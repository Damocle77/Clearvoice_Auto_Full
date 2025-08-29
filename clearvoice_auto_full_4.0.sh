#!/bin/bash

export LC_ALL=C
# ==============================================================================
#  ClearVoice Auto Full v4.0 - Audio Processing Adattivo Universale
# ==============================================================================
#  2025 - Sandro (D@mocle77) Sabbioni
#
# Descrizione aggiornata:
# - Ottimizza l'audio multicanale di film, serie TV e cartoon, garantendo
#   dialoghi sempre chiari e intelligibili anche in presenza di effetti.
# - Bilanciamento dinamico tra canali frontali, surround e LFE, con regolazioni 
#   adattive che valorizzano la scena sonora e riducono la fatica d'ascolto.
# - Applica filtri automatici (highpass, equalizer, volume boost) e regolazioni 
#   intelligenti per ogni canale, adattando il trattamento in base alle 
#   caratteristiche del contenuto.
# - Analizza il loudness (LUFS), il True Peak e la Loudness Range (LRA)
#   su segmenti rappresentativi, calcolati in modo adattivo in base alla
#   durata e alla tipologia del video.
# - Migliora la coerenza e la qualità audio finale, riducendo i picchi 
#   indesiderati e ottimizzando la dinamica per una resa professionale.
# - Segmentazione adattiva per analisi loudnorm: il numero e la durata dei
#   segmenti sono calcolati automaticamente in base alla durata del video,
#   garantendo maggiore accuratezza statistica e efficienza computazionale.
# - Gestione robusta di errori e report automatico al termine.
#
# Funzionalità chiave:
# - Analisi EBU R128 con segmenti adattivi, filtri adattivi per ogni canale.
# - Mapping audio esteso, supporto layout "unknown".
# - Output compatto pronto per batch/report.
# - Diagnostica audio dettagliata e parametri di normalizzazione ottimizzati.
# - Segmentazione adattiva: 3 segmenti per serie TV (<60min),
#   5 per film standard (60-120min), 6 per film lunghi (>120min).
# - Durata dei segmenti ottimizzata (90s o 60s) e distribuzione uniforme.
#
# Dipendenze:
#   ffmpeg, ffprobe, awk, gitbash, wsl
#
# UTILIZZO RAPIDO:
# ./clearvoice_auto_full.sh "video.mkv" [bitrate] [originale] [codec]
#   Bitrate:     256k..768k    (default: 768k)
#   Originale:   yes/no        (default: yes)
#   Codec:       eac3/ac3      (default: eac3)
#
# Output:
#   Input:   miofilm.mkv
#   Output:  miofilm_Clearvoice.mkv
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# Misurazione tempo totale script
SCRIPT_START_TIME=$(date +%s)

# ---> Inizio Pipeline


# ============================= FUNZIONI MODULARI ==============================


# Controllo requisiti di sistema
check_system_requirements() {
    local missing=0
    for cmd in ffmpeg ffprobe awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "ERR: comando necessario non trovato: $cmd"
            missing=1
        fi
    done
    ((missing)) && exit 1
}

# Controllo bitrate
check_bitrate() {
    case "$1" in
        256k|320k|384k|448k|512k|640k|768k) ;;
        *) echo -e "\033[1;31mBitrate non valido!\033[0m"; exit 1 ;;
    esac
}

# Controllo codec audio
check_codec() {
    case "$1" in
        eac3|ac3) ;;
        *) echo -e "\033[1;31mCodec audio non valido! Usa 'eac3' o 'ac3'.\033[0m"; exit 1 ;;
    esac
}

# Wrapper ffmpeg
run_ffmpeg() {
    ffmpeg "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "ERRORE: ffmpeg ha fallito (exit $status)"
        exit $status
    fi
}

# Wrapper ffprobe
run_ffprobe() {
    ffprobe "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "ERRORE: ffprobe ha fallito (exit $status)"
        exit $status
    fi
}

# Estrazione durata video
get_video_duration() {
    local FILE="$1"
    run_ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FILE" 2>/dev/null | cut -d'.' -f1
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


# ===================== PARSING ARGOMENTI UTENTE ============================


# Parsing posizionale
INPUT_FILE="${1:-}"
BITRATE="${2:-768k}"
INCLUDE_ORIGINAL="${3:-yes}"
AUDIO_CODEC="${4:-eac3}"
# Controllo input
if [ -z "$INPUT_FILE" ]; then
    echo -e "\033[1;34mUSO: ./clearvoice_auto_full.sh \"video.mkv\" [bitrate] [originale] [codec]\033[0m"
    echo -e "\033[1;34m Bitrate: 256k,320k,384k,448k,512k,640k,768k (default 768k)\033[0m"
    echo -e "\033[1;34m Originale: yes/no (default yes)\033[0m"
    echo -e "\033[1;34m Codec audio (opz.): eac3/ac3 (default eac3)\033[0m"
    exit 1
fi
# Imposta il nome del file di log in base al file di input
LOG_FILE="${INPUT_FILE%.*}_logfile.log"
# Controllo requisiti
check_bitrate "$BITRATE"
check_codec "$AUDIO_CODEC"

# Imposta il nome del file di output
OUTPUT_FILE="${INPUT_FILE%.*}_clearvoice.mkv"
# Chiedi conferma prima di sovrascrivere il file di output
if [ -f "$OUTPUT_FILE" ]; then
    read -p "Il file $OUTPUT_FILE esiste già. Sovrascrivere? [s/N]: " REPLY
    if [[ ! "$REPLY" =~ ^([sS]|[yY])$ ]]; then
        echo "Operazione annullata. Il file non verrà sovrascritto."
        exit 1
    fi
fi
# Inizio elaborazione
echo ""
echo -e "\033[1;5;32mClearVoice\033[0m\033[1;5;37m Auto Gain - \033[0m\033[1;5;31mEsecuzione Pipeline\033[0m"
echo ""
echo -e "\033[1;34m[Info]\033[0m Controllo requisiti di sistema e parsing argomenti..."


# Estrazione informazioni audio
CHANNELS=$(run_ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$INPUT_FILE")
LAYOUT=$(run_ffprobe -v error -select_streams a:0 -show_entries stream=channel_layout -of csv=p=0 "$INPUT_FILE")

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
# Calcolo durata video
DURATION=$(get_video_duration "$INPUT_FILE")


# =================== SEGMENTAZIONE ADATTIVA PER ANALISI LOUDNORM ===================


# Imposta numero e durata segmenti in base alla durata
if [ "$DURATION" -le 3600 ]; then
    NUM_SEGMENTS=3
    SEGMENT_DUR=90
elif [ "$DURATION" -le 7200 ]; then
    NUM_SEGMENTS=5
    SEGMENT_DUR=60
else
    NUM_SEGMENTS=6
    SEGMENT_DUR=60
fi

# Calcola le posizioni di partenza dei segmenti (distribuiti uniformemente)
declare -a SEGMENT_STARTS=()
for ((i=0; i<NUM_SEGMENTS; i++)); do
    # Evita di campionare troppo vicino ai bordi
    OFFSET=$((DURATION / (NUM_SEGMENTS+1) * (i+1) - SEGMENT_DUR/2))
    # Limita offset minimo e massimo
    [ "$OFFSET" -lt 60 ] && OFFSET=60
    MAX_START=$((DURATION-SEGMENT_DUR-60))
    [ "$OFFSET" -gt "$MAX_START" ] && OFFSET=$MAX_START
    SEGMENT_STARTS+=("$OFFSET")
done

# Report iniziale
VIDEO_CODEC=$(run_ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$INPUT_FILE")
echo ""
echo " -------------------------------------------------------------------------------------"
echo "# Video: $(basename "$INPUT_FILE")"
echo "# Codec Video: ${VIDEO_CODEC} | Codec Audio selezionato: ${AUDIO_CODEC}"
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
echo -e "\033[1;36mAnalisi rappresentativa su $NUM_SEGMENTS segmenti distribuiti (adattivo)...\033[0m"

# Funzione per ottenere statistiche loudnorm da un segmento
get_loudnorm_stats() {
    local FILE=$1
    local START=$2
    local DUR=$3
    ffmpeg -nostdin -ss "$START" -t "$DUR" -i "$FILE" -map 0:a:0 -af loudnorm=print_format=summary -f null - 2>&1
}

# Analizza tutti i segmenti
declare -a ANALYSIS_RESULTS=()
for START in "${SEGMENT_STARTS[@]}"; do
    ANALYSIS_RESULTS+=("$(get_loudnorm_stats "$INPUT_FILE" "$START" "$SEGMENT_DUR")")
done

# Estrai LUFS, Peak, LRA da tutti i segmenti
extract_lufs() { echo "$1" | grep "Input Integrated" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^-?[0-9]+(\.[0-9]+)?$/) print $i}'; }
extract_peak() { echo "$1" | grep "Input True Peak" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^-?[0-9]+(\.[0-9]+)?$/) print $i}'; }
extract_lra()  { echo "$1" | grep "Input LRA" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^-?[0-9]+(\.[0-9]+)?$/) print $i}'; }

# Dichiarazione degli array per i valori estratti
declare -a LUFS_ARR=()
declare -a PEAK_ARR=()
declare -a LRA_ARR=()
for ANALYSIS in "${ANALYSIS_RESULTS[@]}"; do
    LUFS_VAL=$(extract_lufs "$ANALYSIS")
    PEAK_VAL=$(extract_peak "$ANALYSIS")
    LRA_VAL=$(extract_lra "$ANALYSIS")
    LUFS_ARR+=("${LUFS_VAL:-0}")
    PEAK_ARR+=("${PEAK_VAL:-0}")
    LRA_ARR+=("${LRA_VAL:-0}")
done

# --- Calcola media ---

# Calcola media dei valori
LUFS_SUM=0
PEAK_SUM=0
LRA_SUM=0
for ((i=0; i<${#LUFS_ARR[@]}; i++)); do
    LUFS_SUM=$(awk "BEGIN {print $LUFS_SUM+${LUFS_ARR[$i]}}")
    PEAK_SUM=$(awk "BEGIN {print $PEAK_SUM+${PEAK_ARR[$i]}}")
    LRA_SUM=$(awk "BEGIN {print $LRA_SUM+${LRA_ARR[$i]}}")
done
LUFS=$(awk "BEGIN {print $LUFS_SUM/${#LUFS_ARR[@]}}")
PEAK=$(awk "BEGIN {print $PEAK_SUM/${#PEAK_ARR[@]}}")
LRA=$(awk "BEGIN {print $LRA_SUM/${#LRA_ARR[@]}}")
# Limita valore TP per compatibilità loudnorm
if (( $(awk "BEGIN {print ($PEAK < -9)}") )); then
    PEAK=-9
fi
PEAK=$(awk "BEGIN {print ($PEAK>0)?0:$PEAK}")
echo -e "\033[1;32m[OK]\033[0m Analisi segmenti completata. Valori medi: LUFS=$LUFS, TP=$PEAK, LRA=$LRA"

# --- Estrazione valori ---

# Impostazioni voice boost adattivo
VOICE_BOOST=2.8  # Valore minimo
if (( $(awk "BEGIN {print ($LUFS < -28)}") )); then
  VOICE_BOOST=3.2
elif (( $(awk "BEGIN {print ($LUFS < -25)}") )); then
  VOICE_BOOST=3.0
elif (( $(awk "BEGIN {print ($LUFS < -22)}") )); then
  VOICE_BOOST=2.8
fi
# Limita a max 3.2
VOICE_BOOST=$(awk "BEGIN {print ($VOICE_BOOST>3.2)?3.2:$VOICE_BOOST}")

# Impostazioni stereo front adattivo
if (( $(awk "BEGIN {print ($LUFS < -25 || $PEAK > 0)}") )); then
  FRONT_REDUCTION=0.96
elif (( $(awk "BEGIN {print ($LUFS < -21 || $PEAK > -1)}") )); then
  FRONT_REDUCTION=0.97
elif (( $(awk "BEGIN {print ($LUFS < -18 || $PEAK > -2)}") )); then
  FRONT_REDUCTION=0.99
else
  FRONT_REDUCTION=1.00
fi

# Impostazioni surround adattivo
MAX_SURROUND_BOOST=2.9 # Valore massimo
if (( $(awk "BEGIN {print ($LUFS < -25 || $PEAK > 0)}") )); then
    SURROUND_BOOST=2.3
elif (( $(awk "BEGIN {print ($LUFS < -20 || $PEAK > -1)}") )); then
    SURROUND_BOOST=2.5
elif (( $(awk "BEGIN {print ($LUFS < -18 || $PEAK > -2)}") )); then
    SURROUND_BOOST=2.7
else
    SURROUND_BOOST=2.9
fi
# Limitazione massima surround
SURROUND_BOOST=$(awk "BEGIN {print ($SURROUND_BOOST>$MAX_SURROUND_BOOST)?$MAX_SURROUND_BOOST:$SURROUND_BOOST}")

# Impostazioni LFE adattivo (LUFS + True Peak)
MIN_LFE_REDUCTION=0.60 # Valore minimo
LFE_REDUCTION=0.70   # Valore iniziale
if (( $(awk "BEGIN {print ($LUFS < -27 || $PEAK > 0)}") )); then
    LFE_REDUCTION=0.60
elif (( $(awk "BEGIN {print ($LUFS < -23 || $PEAK > -1)}") )); then
    LFE_REDUCTION=0.63
elif (( $(awk "BEGIN {print ($LUFS < -19 || $PEAK > -2)}") )); then
    LFE_REDUCTION=0.66
elif (( $(awk "BEGIN {print ($LUFS < -16 || $PEAK > -4)}") )); then
    LFE_REDUCTION=0.68
else
    LFE_REDUCTION=0.70
fi
# Limitazione massima LFE
LFE_REDUCTION=$(awk "BEGIN {print ($LFE_REDUCTION > 0.70)?0.70:$LFE_REDUCTION}")
LFE_REDUCTION=$(awk "BEGIN {print ($LFE_REDUCTION<$MIN_LFE_REDUCTION)?$MIN_LFE_REDUCTION:$LFE_REDUCTION}")

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
echo -e "\033[1;34m=======================================\033[0m"
echo ""

# Impostazioni codifica audio
declare -a AUDIO_ARGS=()
LANG0=$(run_ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of csv=p=0 "$INPUT_FILE")
LANG0=${LANG0:-ita}
include_original_lc=$(printf "%s" "$INCLUDE_ORIGINAL" | tr '[:upper:]' '[:lower:]')
idx_offset=0
if [[ "$include_original_lc" =~ ^(no|n|false)$ ]]; then
    # Solo ClearVoice
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "language=${LANG0}" -metadata:s:a:0 "title=$(basename "$OUTPUT_FILE" .mkv)" -disposition:a:0 default)
    idx_offset=1
else
    # ClearVoice + Originale
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "language=${LANG0}" -metadata:s:a:0 "title=$(basename "$OUTPUT_FILE" .mkv)" -map 0:a:0 -c:a:1 copy -metadata:s:a:1 "title=Originale" -disposition:a:0 default -disposition:a:1 0)
    idx_offset=2
fi
ALL_INDICES=$(run_ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$INPUT_FILE")
for i in $ALL_INDICES; do
    [ "$i" -eq 0 ] && continue
    AUDIO_ARGS+=(-map 0:a:$i? -c:a:$idx_offset copy)
    idx_offset=$((idx_offset+1))
done


# ============================ FILTRI AUDIO =================================


# Filtro highpass centrale adattivo tra 120 e 140 Hz
if (( $(awk "BEGIN {print ($LUFS < -26)}") )); then
  FC_HPF=140
elif (( $(awk "BEGIN {print ($LUFS < -24)}") )); then
  FC_HPF=135
elif (( $(awk "BEGIN {print ($LUFS < -21)}") )); then
  FC_HPF=130
else
  FC_HPF=120
fi
# EQ adattivo extra sui dialoghi se Voice Boost >2dB
FC_FILTER="highpass=f=${FC_HPF},volume=${VOICE_BOOST},equalizer=f=3000:t=q:w=2:g=2"
# Filtro LFE adattivo
LFE_FILTER="highpass=f=40:p=2,volume=${LFE_REDUCTION}"
# Filtro surround adattivo
SURROUND_FILTER="volume=${SURROUND_BOOST}"

# Costruzione filtro complesso
TARGET_LUFS=-16.0  # Standard broadcast
TARGET_PEAK=-1.5   # Sicurezza clipping
TARGET_LRA=7.0     # Range standard

# Se LUFS troppo basso, usa solo volume boost invece di loudnorm
VOLUME_BOOST=$(awk "BEGIN {print 10^((-16-($LUFS))/20)}")
FILTER_COMPLEX="[0:a:0]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][SL][SR]; \
[FC]highpass=f=${FC_HPF},volume=${VOICE_BOOST}[FCout]; \
[LFE]volume=${LFE_REDUCTION}[LFEout]; \
[FL]volume=${FRONT_REDUCTION}[FLout]; \
[FR]volume=${FRONT_REDUCTION}[FRout]; \
[SL]volume=${SURROUND_BOOST}[SLout]; \
[SR]volume=${SURROUND_BOOST}[SRout]; \
[FLout][FRout][FCout][LFEout][SLout][SRout]join=inputs=6:channel_layout=5.1,volume=${VOLUME_BOOST}[clearvoice]"
echo -e "\033[1;33m[Info]\033[0m channelsplit ottimizzato sempre attivo: ${VOLUME_BOOST}x"


# ========================= ELABORAZIONE AUDIO ==============================


# Elaborazione audio per il file ottimizzato
echo -e "\033[1;33m[Attendere]\033[0m\nProcessing file ottimizzato:\n\033[1;33m${OUTPUT_FILE}\033[0m\n"
run_ffmpeg -y -nostdin -loglevel error -stats -hide_banner -hwaccel auto -threads 0 -i "$INPUT_FILE" \
    -filter_complex "$FILTER_COMPLEX" \
    -map 0:v -c:v copy \
    "${AUDIO_ARGS[@]}" \
    -map 0:s? -c:s copy \
    -map 0:t? -c:t copy \
    -map_metadata 0 -map_chapters 0 \
    "$OUTPUT_FILE"
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
        if [ "$DURATION" -gt "$OUTPUT_DURATION" ]; then
            DURATION_DIFF=$((DURATION - OUTPUT_DURATION))
        else
            DURATION_DIFF=$((OUTPUT_DURATION - DURATION))
        fi
        if [ "$DURATION_DIFF" -lt 5 ]; then
            INTEGRITY_RES="✓ OK"
        else
            INTEGRITY_RES="⚠ Durata differente ($DURATION_DIFF s)"
        fi
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
    echo " Parametri Audio"
    echo " Voice Boost    : ${VOICE_BOOST} dB"
    echo " Highpass Voce  : ${FC_HPF} Hz"
    echo " Front Redux    : ${FRONT_REDUCTION}x"
    echo " LFE HPF 40Hz   : ${LFE_REDUCTION}x"
    echo " Surround Boost : ${SURROUND_BOOST}x"
    echo " -----------------------------------------"
    echo " Parametri Loudness"
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
# <--- Fine pipeline