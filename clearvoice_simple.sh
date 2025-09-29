#!/bin/bash
#------------------------------------------------------------------------------------------------
# Script Bash per rendere i dialoghi cristallini, potenti e mai fastidiosi su soundbar.
# Ottimizza tracce 5.1 (film, serie, anime, podcast) con:
#   - Voce centrale chiara e naturale (EQ e limiter dedicati)
#   - Bassi controllati, niente rimbombi
#   - Surround immersivo ma mai invadente
#   - Compatibilità massima con mux moderni e doppiaggio italiano
#
# UTILIZZO:
#     1. nome_file.mkv   - File video MKV/MP4 con audio 5.1
#     2. bitrate         - 256k-320k-384k-448k-512k-640k-768k (default: 768k)
#     3. originale       - si/no per traccia originale (default: si)
#     4. codec           - eac3/ac3 (default: eac3)
#
# ESEMPI:
#   ./clearvoice_simple.sh "film.mkv"                    # Default
#   ./clearvoice_simple.sh "serie.mkv" 448k no ac3       # Personalizzato
#
# OUTPUT: Crea "nome_file_clearvoice_simple.mkv" con traccia audio ottimizzata per dialoghi top.
#------------------------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

# --- Inizializzazione parametri e validazione input -------------------------------------------- 

# File di input
INPUT_FILE="${1:-}"
BITRATE="${2:-768k}"
INCLUDE_ORIGINAL="${3:-yes}"
AUDIO_CODEC="${4:-eac3}"

# Assicura che il bitrate abbia sempre il suffisso "k"
if [[ "$BITRATE" =~ ^[0-9]+$ ]]; then
    BITRATE="${BITRATE}k"
    echo -e "\033[1;33m[Correzione]\033[0m Aggiunto suffisso 'k' al bitrate: $BITRATE"
fi

# Validazione bitrate (range ragionevole per E-AC3)
BITRATE_NUM=$(echo "$BITRATE" | sed 's/k$//')
if [[ ! "$BITRATE_NUM" =~ ^[0-9]+$ ]] || [ "$BITRATE_NUM" -lt 128 ] || [ "$BITRATE_NUM" -gt 1024 ]; then
    echo -e "\033[1;31m[Errore]\033[0m Bitrate non valido: $BITRATE (deve essere tra 128k e 1024k)"
    exit 1
fi

# Validazione codec audio
case "${AUDIO_CODEC,,}" in
    "eac3"|"ac3") 
        AUDIO_CODEC="${AUDIO_CODEC,,}" 
        ;;
    *) 
        # Stampa informazioni codec non supportato
        echo -e "\033[1;31m[Errore]\033[0m Codec non supportato: $AUDIO_CODEC (usa: eac3, ac3)"
        exit 1
        ;;
esac

# Controllo file di input
if [ -z "$INPUT_FILE" ]; then
    echo "USO: ./clearvoice_simple.sh \"video.mkv\" [bitrate] [originale] [codec]"
    exit 1
fi

# Verifica esistenza file
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "\033[1;31m[Errore]\033[0m File non trovato: $INPUT_FILE"
    exit 1
fi

# File di output
INPUT_DIR=$(dirname "$INPUT_FILE")
INPUT_BASENAME=$(basename "$INPUT_FILE")
OUTPUT_FILE="$INPUT_DIR/${INPUT_BASENAME%.*}_clearvoice_simple.mkv"

# Controllo canali audio con gestione errori migliorata
if ! CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$INPUT_FILE" 2>/dev/null); then
    echo -e "\033[1;31m[Errore]\033[0m Impossibile analizzare il file audio: $INPUT_FILE"
    echo -e "Verificare che il file sia un video valido con traccia audio."
    exit 1
fi

# Verifica che il file abbia audio 5.1
if [ -z "$CHANNELS" ] || [ "$CHANNELS" != "6" ]; then
    echo -e "\033[1;31mAudio non 5.1 (canali: ${CHANNELS:-sconosciuto})\033[0m"
    echo -e "Convertire la traccia in 5.1 per ClearVoice.\nEsempio:\nffmpeg -i input.mkv -map 0 -c copy -c:a ac3 -ac 6 output_5.1.mkv"
    exit 1
fi

# Estrazione e validazione durata
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT_FILE" | cut -d'.' -f1)

# Verifica durata valida
if [[ ! "$DURATION" =~ ^[0-9]+$ ]]; then
    echo -e "\033[1;31m[Errore]\033[0m Durata non valida: $DURATION"
    DURATION=1800  # Default a 30 minuti se non valida
fi

# --- Configurazione filtro audio ------------------------------------------------------------------

# Profilo unico
PROFILE="Cinema"
PROFILE_DESC="Cinema/Premium/Blockbuster/Musicali"

# Parametri di tuning
LFE_VOL=0.20
SURROUND_BOOST=1.90
VOICE_BOOST=2.50
FRONT_VOL=1.00
HIGHPASS=80
HIGHSUB=50

# Equalizzatori per ogni canale (VOICE, SUB, SURROUND, FRONT)
EQ_VOICE="[FC]highpass=f=${HIGHPASS},volume=${VOICE_BOOST}dB[FCout];"
EQ_SUB="[LFE]highpass=f=${HIGHSUB},volume=${LFE_VOL},alimiter=limit=0.45:attack=7:release=105[LFEout];"
#EQ_VOICE="[FC]highpass=f=${HIGHPASS},volume=${VOICE_BOOST}dB,equalizer=f=1850:t=q:w=280:g=2,equalizer=f=3050:t=q:w=400:g=1.5,compand=attacks=3:decays=6:points=-90/-90|-17/-5|0/0:soft-knee=3[FCout];"
#EQ_SUB="[LFE]highpass=f=${HIGHSUB},volume=${LFE_VOL}dB,equalizer=f=80:t=q:w=30:g=1.7,equalizer=f=60:t=q:w=40:g=-2,equalizer=f=110:t=q:w=50:g=-1.5[LFEout];"
EQ_SURROUND="[SL]volume=${SURROUND_BOOST}[SLout]; [SR]volume=${SURROUND_BOOST}[SRout];"
EQ_FRONT="[FL]volume=${FRONT_VOL}[FLout]; [FR]volume=${FRONT_VOL}[FRout];"

# Parametri finali di compressione/limiting
FINAL_DYNAMICS="alimiter=limit=0.94:attack=16:release=180:level=disabled:asc=1"

# Pipeline audio completa con SoXR 28-bit + oversampling 2X
FILTER_COMPLEX="[0:a:0]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][SL][SR]; \
    ${EQ_FRONT} ${EQ_VOICE} ${EQ_SUB} ${EQ_SURROUND} \
    [FLout][FRout][FCout][LFEout][SLout][SRout]join=inputs=6:channel_layout=5.1[premix]; \
    [premix]aresample=out_sample_rate=96000:resampler=soxr:precision=28:dither_method=triangular[os]; \
    [os]${FINAL_DYNAMICS}[limited]; \
    [limited]aresample=out_sample_rate=48000:resampler=soxr:precision=28:dither_method=triangular[clearvoice]"

# Dichiarazione array audio
declare -a AUDIO_ARGS=()

# Configurazione tracce audio output
if [[ "${INCLUDE_ORIGINAL,,}" =~ ^(no|n|false)$ ]]; then
    LANG_CODE=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
    [ -z "$LANG_CODE" ] && LANG_CODE="ita"
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "title=ClearVoice $LANG_CODE ${AUDIO_CODEC} 5.1" -disposition:a:0 default)

elif [[ "${INCLUDE_ORIGINAL,,}" =~ ^(si|s|yes|y|true)$ ]]; then
    LANG_CODE=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
    [ -z "$LANG_CODE" ] && LANG_CODE="ita"
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "title=ClearVoice $LANG_CODE ${AUDIO_CODEC} 5.1" -map 0:a:0 -c:a:1 copy -metadata:s:a:1 "title=Originale" -disposition:a:0 default -disposition:a:1 0)
else
    echo "Valore per 'originale' non riconosciuto: usa 'si'/'no'"
    exit 1
fi

# Stampa risultati
echo " "
echo -e "\033[1;32m[OK]\033[0m Tuning Vocale | LFE Controllato | Surround & Front Bilanciati"
echo -e "\033[1;32m[OK]\033[0m SoXR (28-bit Precision) | Oversampling 2X | Audio Finale HD"
echo -e "\033[1;33m[Engine]\033[0m ${PROFILE_DESC}"

# Calcola e mostra i valori dei parametri applicati
VOICE_BOOST=$(echo "$EQ_VOICE" | grep -o 'volume=[0-9.]*' | sed 's/volume=//' | tail -n1)
[ -z "$VOICE_BOOST" ] || [[ ! "$VOICE_BOOST" =~ ^[0-9]+(\.[0-9]+)?$ ]] && VOICE_BOOST="2.36"
LFE_FACTOR="$LFE_VOL"

# Stampa parametri applicati
echo -e "\033[1;35m[Parametri]\033[0m Voice Boost: \033[1;33m${VOICE_BOOST}\033[0m dB | LFE Factor: \033[1;33m${LFE_VOL}\033[0m | Surround Boost: \033[1;33m${SURROUND_BOOST}\033[0m dB | Front: \033[1;33m${FRONT_VOL}\033[0m dB | Highpass: \033[1;33m${HIGHPASS}\033[0m Hz"

# Estrai e mostra i parametri dinamici
LIMITER_LIMIT=$(echo "$FINAL_DYNAMICS" | grep -o 'limit=[0-9.]*' | sed 's/limit=//' | head -n1)
[ -z "$LIMITER_LIMIT" ] || [[ ! "$LIMITER_LIMIT" =~ ^[0-9]+(\.[0-9]+)?$ ]] && LIMITER_LIMIT="0.85"

# Stampa parametri dinamici
echo -e "\033[1;35m[Parametri]\033[0m Processing: \033[1;33mClearVoice\033[0m | LFE Highpass: \033[1;33m${HIGHSUB}\033[0m Hz | Limiter: \033[1;33m${LIMITER_LIMIT}\033[0m ceiling | SoXR: \033[1;33m28-bit\033[0m precision"

# --- Generazione file output e controllo sovrascrittura ----------------------------------------------

# # Avviso sovrascrittura
if [ -f "$OUTPUT_FILE" ]; then
    echo -ne "\033[1;31m[Attenzione]\033[0m Il file esiste già. Sovrascrivere? [s/N]: "
    read -r risposta
    case "$risposta" in
        [sS]|[sS][iI])
            echo -e "\033[1;32m[OK]\033[0m Sovrascrittura confermata"
            ;;
        *) 
            echo -e "\033[1;31m[EXIT]\033[0m Operazione annullata"
            exit 1
            ;;
    esac
fi

# Stampa messaggio di attesa
echo -e "\033[1;36m[Attendere]\033[0m Elaborazione in corso..."

# Esecuzione ffmpeg con solo statistiche essenziali
if ! ffmpeg -y -nostdin -loglevel error -stats -hide_banner -hwaccel auto -threads 0 \
    -i "$INPUT_FILE" \
    -filter_complex "$FILTER_COMPLEX" \
    -max_muxing_queue_size 1024 \
    -map 0:v -c:v copy \
    "${AUDIO_ARGS[@]}" \
    -map 0:s? -c:s copy \
    -map 0:t? -c:t copy \
    "$OUTPUT_FILE"; then
    # Gestione errore ffmpeg
    echo -e "\033[1;31m[Errore]\033[0m Elaborazione FFmpeg fallita"
    exit 1
fi

# Verifica che il file di output sia stato creato correttamente
if [ ! -f "$OUTPUT_FILE" ]; then
    echo -e "\033[1;31m[Errore]\033[0m File di output non creato: $OUTPUT_FILE"
    exit 1
fi

# Completamento con successo
echo -e "\033[1;32m[OK]\033[0m Processing audio completato."
echo -e "\033[1;33mFile creato:\033[0m"
echo "${OUTPUT_FILE#./}"