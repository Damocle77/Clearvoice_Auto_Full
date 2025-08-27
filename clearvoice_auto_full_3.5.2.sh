#!/bin/bash

export LC_ALL=C
# ================================================================================
# ClearVoice Auto (Full) v3.5.2 - Audio Processing Adattivo Universale
# © 2025 - Sandro (D@mocle77) Sabbioni
#
# Descrizione:
# ▸ Ottimizza automaticamente l'audio multicanale di film, serie e cartoon.
# ▸ Dialoghi chiari, bilanciamento ottimale frontali/surround/LFE.
# ▸ Makeup gain automatico: se serve, viene creata solo la versione "_gain".
# ▸ Output compatto, report tecnico batch-ready.
#
# Funzioni principali:
# ▸ Analisi loudnorm EBU R128 (LUFS, True Peak, LRA), filtri adattivi per canale.
# ▸ Gestione robusta di errori, mapping audio esteso, layout "unknown".
# ▸ Feedback chiaro e continuo durante le fasi di attesa ed export.
#
# Dipendenze:
# ▸ ffmpeg >= 4.2, ffprobe >= 4.2, awk
#
# Uso rapido:
# ./clearvoice_auto_full.sh "video.mkv" [bitrate] [originale] [codec]
#  - bitrate: 256k ... 768k (default 768k)
#  - originale: yes/no (default yes)
#  - codec: eac3/ac3 (default eac3)
#
# Output finale:
#  Input:   Sandman 2x01 La Stagione Delle Nebbie-0.mkv
#  Output:  Sandman 2x01 La Stagione Delle Nebbie-0_Clearvoice_Auto_gain.mkv
# ================================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Costanti configurabili ---
MAX_SURROUND_BOOST=3.0
MIN_LFE_REDUCTION=0.60

# === FUNZIONI UTILI ===
# Controllo requisiti di sistema
check_system_requirements() {
local missing=0
for cmd in ffmpeg ffprobe awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERRORE: comando necessario non trovato: $cmd"
        missing=1
    fi
done
if [ $missing -eq 1 ]; then
    echo "Installa i requisiti mancanti e riprova."
    exit 1
fi
}

# Estrazione durata video
get_video_duration() {
local FILE="$1"
ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FILE" 2>/dev/null | cut -d'.' -f1
}


# Stima tempo di elaborazione
estimate_processing_time() {
local DURATION=$1
local BASE_FACTOR=35
[ "$DURATION" -gt 7200 ] && BASE_FACTOR=45
[ "$DURATION" -lt 1800 ] && BASE_FACTOR=25
local ESTIMATED=$((DURATION / BASE_FACTOR))
[ "$ESTIMATED" -lt 10 ] && ESTIMATED=10
[ "$ESTIMATED" -gt 1200 ] && ESTIMATED=1200
echo "$ESTIMATED"
}

# --- Silent mode opzionale ---
SILENT=0
for arg in "$@"; do
    [ "$arg" = "--silent" ] && SILENT=1
    [ "$arg" = "-s" ] && SILENT=1
    [ "$arg" = "-q" ] && SILENT=1
    # ...puoi aggiungere altri flag se vuoi
done

# === PARSING ARGOMENTI UTENTE ===
# Controllo argomenti 
if [ -z "${1:-}" ]; then
    echo -e "\033[1;34mUSO: ./clearvoice_auto_full.sh \"video.mkv\" [bitrate] [originale] [codec]\033[0m"
    echo -e "\033[1;34m Bitrate: 256k,320k,384k,448k,512k,640k,768k (default 768k)\033[0m"
    echo -e "\033[1;34m Originale: yes/no (default yes)\033[0m"
    echo -e "\033[1;34m Codec audio (opz.): eac3/ac3 (default eac3)\033[0m"
    exit 1
fi

# Assegnazione variabili
INPUT_FILE="${1:-}"
BITRATE="${2:-768k}"
INCLUDE_ORIGINAL="${3:-yes}"
AUDIO_CODEC="${4:-eac3}"

# Controllo bitrate
case "$BITRATE" in
256k|320k|384k|448k|512k|640k|768k) ;;
*) echo -e "\033[1;31mBitrate non valido!\033[0m"; exit 1 ;;
esac

# Controllo codec audio
case "$AUDIO_CODEC" in
eac3|ac3) ;;
*) echo -e "\033[1;31mCodec audio non valido! Usa 'eac3' o 'ac3'.\033[0m"; exit 1 ;;
esac

# Assegnazione file di output
OUTPUT_FILE="${INPUT_FILE%.*}_clearvoice_auto.mkv"
echo ""
echo -e "\033[1;5;32mClearVoice\033[0m\033[1;5;37m Auto Gain - \033[0m\033[1;5;31mEsecuzione Pipeline\033[0m"
echo ""
echo -e "\033[1;34m[Info]\033[0m Controllo requisiti di sistema e parsing argomenti..."

# Controllo requisiti di sistema
check_system_requirements
if [ -f "$OUTPUT_FILE" ]; then
    echo ""
    echo -e "\033[1;33m▶ [AVVISO]\033[0m File di output già esistente: $OUTPUT_FILE"
    echo " Sovrascrivere? (y/n) [default: n]"
    read -r OVERWRITE
    [ -z "$OVERWRITE" ] && OVERWRITE="n"
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo " Operazione annullata."
        exit 0
    fi
    echo " Sovrascrivo..."
fi
# Controllo file di input
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "\033[1;31m✗ File di input non trovato: $INPUT_FILE\033[0m"
    exit 1
fi

# Controllo layout audio
CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$INPUT_FILE")
LAYOUT=$(ffprobe -v error -select_streams a:0 -show_entries stream=channel_layout -of csv=p=0 "$INPUT_FILE")

# Controllo layout audio
if [ "$CHANNELS" = "6" ]; then
    if [ "$LAYOUT" != "5.1" ] && [ "$LAYOUT" != "5.1(side)" ] && [ "$LAYOUT" != "unknown" ] && [ -n "$LAYOUT" ]; then
    echo -e "\033[1;34m▲ Info:\033[0m Layout audio non standard ($LAYOUT) rilevato, ma a 6 canali: continuo..."
    fi
    if [ -z "$LAYOUT" ] || [ "$LAYOUT" = "unknown" ]; then
    echo -e "\033[1;31m▲ Info:\033[0m Layout unknown. Uso mapping 5.1 standard...Attendere"
        LAYOUT="5.1"
    fi
else
    echo -e "\033[1;31m✗ Audio non 5.1 (canali: $CHANNELS, layout: $LAYOUT)\033[0m"
    exit 1
fi

# Controllo requisiti di sistema
check_system_requirements
if ! ffprobe -v quiet -show_entries format=format_name "$INPUT_FILE" >/dev/null 2>&1; then
    echo -e "\033[1;31m✗ File non riconosciuto da FFmpeg o formato non supportato\033[0m"
    exit 1
fi

# Calcolo durata video
DURATION=$(get_video_duration "$INPUT_FILE")

# Report iniziale
echo ""
echo " -------------------------------------------------------------------------------------"
echo "# Video: $(basename "$INPUT_FILE")"
echo "# Durata: $((DURATION / 60))m $((DURATION % 60))s | Bitrate: ${BITRATE} | Layout: ${LAYOUT}"
if [[ "$INCLUDE_ORIGINAL" =~ ^(no|n|false)$ ]]; then
    MODALITA="Solo Traccia ClearVoice"
else
    MODALITA="Traccia ClearVoice + Originale"
fi
echo "# Modalità: $MODALITA"
echo " -------------------------------------------------------------------------------------"
echo ""
echo -e "\033[1;33m[Attendere]\033[0m Analisi audio loudnorm:"
echo -e "\033[1;36mTipicamente 12 minuti per ogni 2 ore di filmato...\033[0m"
ANALYSIS=$(ffmpeg -nostdin -i "$INPUT_FILE" -af loudnorm=print_format=summary -f null - 2>&1)
echo -e "\033[1;32m[OK]\033[0m Analisi audio completata."

# Estrazione valori
LUFS=$(echo "$ANALYSIS" | grep "Input Integrated" | awk '{print $3}' | sed 's/LUFS//')
PEAK=$(echo "$ANALYSIS" | grep "Input True Peak" | awk '{print $4}' | sed 's/dBTP//')
LRA=$(echo "$ANALYSIS" | grep "Input LRA" | awk '{print $3}' | sed 's/LU//')

# Calcolo valore medio
LUFS=${LUFS/-inf/-200}
PEAK=${PEAK/-inf/-20}

# Analisi audio LRA
if [ -z "$LUFS" ] || [ -z "$PEAK" ] || [ -z "$LRA" ]; then
    echo -e "\033[1;31m✗ ERRORE: Analisi audio fallita. Verificare il file di input.\033[0m"
    exit 1
fi
if ! awk "BEGIN{exit !($LUFS >= -70 && $LUFS <= 0)}"; then
    echo -e "\033[1;31m✗ ERRORE: Valore LUFS non valido: $LUFS\033[0m"
    exit 1
fi
if ! awk "BEGIN{exit !($PEAK >= -20 && $PEAK <= 10)}"; then
    echo -e "\033[1;31m✗ ERRORE: Valore True Peak non valido: $PEAK\033[0m"
    exit 1
fi

# --- Controllo validità numerica ---
if ! awk "BEGIN{exit !($LUFS ~ /^-?[0-9]+(\.[0-9]+)?$/)}"; then
    echo -e "\033[1;31m✗ ERRORE: LUFS non numerico ($LUFS)\033[0m"
  exit 1
fi
if ! awk "BEGIN{exit !($PEAK ~ /^-?[0-9]+(\.[0-9]+)?$/)}"; then
    echo -e "\033[1;31m✗ ERRORE: PEAK non numerico ($PEAK)\033[0m"
  exit 1
fi
if ! awk "BEGIN{exit !($LRA ~ /^-?[0-9]+(\.[0-9]+)?$/)}"; then
    echo -e "\033[1;31m✗ ERRORE: LRA non numerico ($LRA)\033[0m"
  exit 1
fi

# Impostazioni filtri audio
VOICE_BOOST=2.8
if (( $(awk "BEGIN {print ($LUFS < -28)}") )); then
    VOICE_BOOST=3.8
elif (( $(awk "BEGIN {print ($LUFS < -25)}") )); then
    VOICE_BOOST=3.5
elif (( $(awk "BEGIN {print ($LUFS < -22)}") )); then
    VOICE_BOOST=3.3
elif (( $(awk "BEGIN {print ($LUFS < -18)}") )); then
    VOICE_BOOST=3.0
fi

# Impostazioni stereo front
if (( $(awk "BEGIN {print ($PEAK > 0)}") )); then
    FRONT_REDUCTION=1.0
elif (( $(awk "BEGIN {print ($PEAK > -1)}") )); then
    FRONT_REDUCTION=0.97
elif (( $(awk "BEGIN {print ($PEAK > -2)}") )); then
    FRONT_REDUCTION=0.94
elif (( $(awk "BEGIN {print ($PEAK > -4)}") )); then
    FRONT_REDUCTION=0.92
else
    FRONT_REDUCTION=0.89
fi

# Impostazioni surround
SURROUND_BOOST=2.2
if (( $(awk "BEGIN {print ($LUFS < -25)}") )); then
    SURROUND_BOOST=2.9
elif (( $(awk "BEGIN {print ($LUFS < -20)}") )); then
    SURROUND_BOOST=2.7
else
    SURROUND_BOOST=2.5
fi
# Protezione aggiuntiva su True Peak
if (( $(awk "BEGIN {print ($PEAK > -1)}") )); then
    SURROUND_BOOST=2.3
fi

# Impostazioni LFE
LFE_REDUCTION=0.74
if (( $(awk "BEGIN {print ($LUFS < -25)}") )); then
    LFE_REDUCTION=0.65
elif (( $(awk "BEGIN {print ($LUFS < -21)}") )); then
    LFE_REDUCTION=0.68
elif (( $(awk "BEGIN {print ($LUFS < -18)}") )); then
    LFE_REDUCTION=0.72
else
    LFE_REDUCTION=0.70
fi
# Protezione True Peak aggiuntiva
if (( $(awk "BEGIN {print ($PEAK > -1)}") )); then
    LFE_REDUCTION=0.62
fi

# --- Limiting invece di override ---
if (( $(awk "BEGIN {print ($PEAK > -1)}") )); then
  SURROUND_BOOST=$(awk "BEGIN {print ($SURROUND_BOOST>$MAX_SURROUND_BOOST)?$MAX_SURROUND_BOOST:$SURROUND_BOOST}")
  LFE_REDUCTION=$(awk "BEGIN {print ($LFE_REDUCTION<$MIN_LFE_REDUCTION)?$MIN_LFE_REDUCTION:$LFE_REDUCTION}")
fi

# Report diagnostica
echo ""
echo -e "\033[1;34m========= Diagnostica Audio ==========\033[0m"
echo -e " Voice Boost     : ${VOICE_BOOST} dB"
echo -e " Front Reduction : ${FRONT_REDUCTION}x"
echo -e " LFE - HPF 40Hz  : ${LFE_REDUCTION}x"
echo -e " Surround Boost  : ${SURROUND_BOOST}x"
echo -e " LUFS (input)    : ${LUFS} LUFS"
echo -e " True Peak       : ${PEAK} dBTP"
echo -e " Loudness Range  : ${LRA} LU"
echo -e " Codec audio     : ${AUDIO_CODEC^^}\033[0m"

# Impostazioni codifica audio
declare -a AUDIO_ARGS=()
LANG0=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of csv=p=0 "$INPUT_FILE")
LANG0=${LANG0:-ita}
include_original_lc=$(printf "%s" "$INCLUDE_ORIGINAL" | tr '[:upper:]' '[:lower:]')
idx_offset=0
if [[ "$include_original_lc" =~ ^(no|n|false)$ ]]; then
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "language=${LANG0}" -metadata:s:a:0 "title=$(basename "$OUTPUT_FILE" .mkv)" -disposition:a:0 default)
    idx_offset=1
else
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "language=${LANG0}" -metadata:s:a:0 "title=$(basename "$OUTPUT_FILE" .mkv)" -map 0:a:0 -c:a:1 copy -metadata:s:a:1 "title=Originale" -disposition:a:0 default -disposition:a:1 0)
    idx_offset=2
fi
ALL_INDICES=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$INPUT_FILE")
for i in $ALL_INDICES; do
    [ "$i" -eq 0 ] && continue
    AUDIO_ARGS+=(-map 0:a:$i? -c:a:$idx_offset copy)
    idx_offset=$((idx_offset+1))
done

# Filtri audio
FC_FILTER="highpass=f=120,volume=${VOICE_BOOST},alimiter=attack=5:release=100"
LFE_FILTER="highpass=f=40:p=2,volume=${LFE_REDUCTION}"
SURROUND_FILTER="volume=${SURROUND_BOOST}"
FILTER_COMPLEX="[0:a:0]channelsplit=channel_layout=${LAYOUT}[FL][FR][FC][LFE][SL][SR]; \
[FC]${FC_FILTER}[FCout]; \
[LFE]${LFE_FILTER}[LFEout]; \
[FL]volume=${FRONT_REDUCTION}[FLout]; \
[FR]volume=${FRONT_REDUCTION}[FRout]; \
[SL]${SURROUND_FILTER}[SLout]; \
[SR]${SURROUND_FILTER}[SRout]; \
[FLout][FRout][FCout][LFEout][SLout][SRout]join=inputs=6:channel_layout=${LAYOUT}[clearvoice]"

# Stima tempo di elaborazione
ESTIMATED_PROCESSING_TIME=$(estimate_processing_time "$DURATION")
MINUTES=$((ESTIMATED_PROCESSING_TIME / 60))
SECONDS=$((ESTIMATED_PROCESSING_TIME % 60))
echo ""
echo -e "\033[1;33m[Attendere]\033[0m\nProcessing file ottimizzato:\n\033[1;33m${OUTPUT_FILE}\033[0m\nTempo stimato: ${MINUTES}m ${SECONDS}s\n"
ffmpeg -y -nostdin -loglevel fatal -nostats -hide_banner -hwaccel auto -threads 0 -i "$INPUT_FILE" \
    -filter_complex "$FILTER_COMPLEX" \
    -map 0:v -c:v copy \
    "${AUDIO_ARGS[@]}" \
    -map 0:s? -c:s copy \
    -map 0:t? -c:t copy \
    -map_metadata 0 -map_chapters 0 \
    "$OUTPUT_FILE"

# Esecuzione ffmpeg
START_TIME=$(date +%s)
ffmpeg_exit_code=$?
DURATION_FINAL=$(( $(date +%s) - START_TIME ))
MINUTI=$((DURATION_FINAL / 60))
SECONDI=$((DURATION_FINAL % 60))
echo -e "\033[1;32m[OK]\033[0m File ottimizzato esportato...\033[1;33m[Attendere]\033[0m"
ffmpeg_exit_code=$?
DURATION_FINAL=$(( $(date +%s) - START_TIME ))
MINUTI=$((DURATION_FINAL / 60))
SECONDI=$((DURATION_FINAL % 60))

if [ $ffmpeg_exit_code -ne 0 ]; then
    echo "✗ Errore durante l'elaborazione con FFmpeg. [exit: $ffmpeg_exit_code]"
    exit $ffmpeg_exit_code
fi

# Calcolo makeup gain finale
FINAL_MAKEUP_GAIN="-"
LUFS_PROCESSED="-"

echo ""
echo -e "\033[1;34m[Info]\033[0m Operazione completata. Generazione report finale..."

# Report finale
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    if command -v wc >/dev/null 2>&1; then
        OUTPUT_SIZE=$(wc -c < "$OUTPUT_FILE" 2>/dev/null || echo "sconosciuta")
    else
        OUTPUT_SIZE="sconosciuta"
    fi
    OUTPUT_SIZE_MB=$((OUTPUT_SIZE / 1024 / 1024))
    if ffprobe -v quiet -show_entries format=duration "$OUTPUT_FILE" >/dev/null 2>&1; then
        OUTPUT_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null | cut -d'.' -f1)
        DURATION_DIFF=$((DURATION > OUTPUT_DURATION ? DURATION - OUTPUT_DURATION : OUTPUT_DURATION - DURATION))
        INTEGRITY_RES=$([ "$DURATION_DIFF" -lt 5 ] && echo "✓ OK" || echo "⚠ Durata differente ($DURATION_DIFF s)")
    else
        INTEGRITY_RES="Impossibile verifica durata."
    fi
    echo ""
    echo "╔═════════════════════════════════════════╗"
    echo "║         CLEARVOICE AUTO - REPORT        ║"
    echo "╚═════════════════════════════════════════╝"
    echo " Durata         : $((DURATION / 60))m $((DURATION % 60))s"
    echo " Integrità      : ${INTEGRITY_RES}"
    echo " Dimensione     : ${OUTPUT_SIZE_MB} MB"
    echo " -----------------------------------------"
    echo " Parametri audio"
    echo " Voice Boost    : ${VOICE_BOOST} dB"
    echo " Front Redux    : ${FRONT_REDUCTION}x"
    echo " LFE HPF 40Hz   : ${LFE_REDUCTION}x"
    echo " Surround Boost : ${SURROUND_BOOST}x"
    echo " -----------------------------------------"
    echo " Loudness"
    echo " LUFS (input)    : ${LUFS} LUFS"
    echo " True Peak       : ${PEAK} dBTP"
    echo " LRA Range       : ${LRA} LU"
    echo " -----------------------------------------"
    echo ""
    echo -e "\033[1;5;33mFile finale pronto e conforme:\033[0m"
    echo -e "\033[1;37m${OUTPUT_FILE##*/}\033[0m"
else
    echo "✗ Output non creato o vuoto!"
    echo " Percorso: $OUTPUT_FILE"
fi
# --- END ---
