
#!/bin/bash
# ================================================================================================
# ClearVoice Simple - Binging ⓦ Edition (Nerd Spectral Extended)
# ================================================================================================
# Script per migliorare la chiarezza delle voci nei file audio 5.1 contenuti in video MKV.
# Analizza il loudness (LUFS/LRA) su più segmenti e applica equalizzazione adattiva.
# Ottimizzato per binge watching (Pop, Netflix, Disney, Action, Cartoon) e soundbar LG SP7(+SPK8).
#
# By Sandro (D@mocle77) Sabbioni
#
# USO:
#   ./clearvoice_simple.sh "video.mkv" [bitrate] [originale] [codec]
#
# PARAMETRI:
#   1. nome_file.mkv   - File video di input (MKV con audio 5.1)
#   2. bitrate         - Bitrate audio desiderato (default: 768k)
#   3. originale       - "si" per includere la traccia originale, "no" per solo ClearVoice
#                        (accetta anche "yes"/"no", "y"/"n", "true"/"false")
#   4. codec           - Codec audio di output (default: eac3)
#
# ESEMPIO:
#   ./clearvoice_simple.sh "film.mkv" 768k si eac3
#
# OUTPUT:
#   Crea un nuovo file "nome_file_clearvoice_simple.mkv" con traccia audio ottimizzata.
#
# NOTE:
#   - Questo script richiede ffmpeg e ffprobe in ENV per funzionare.
#   - I file di output verranno creati nella stessa directory del file di input.
#   - Scegli non meno di 386k eac3 o 448k ac3 per serie TV e 640k ac3 o 758k eac3 per film.
#   - Se il file di origine (serie TV è 256k puoi selezionare 320k ac3/eac3).
# ================================================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Controllo dipendenze ---
if ! command -v ffmpeg &> /dev/null; then
    echo -e "\033[1;31mErrore:\033[0m ffmpeg non trovato. Installare ffmpeg e aggiungere al PATH."
    exit 1
fi

if ! command -v ffprobe &> /dev/null; then
    echo -e "\033[1;31mErrore:\033[0m ffprobe non trovato. Installare ffmpeg e aggiungere al PATH."
    exit 1
fi

# --- Variabili di ambiente --- 

# File di input
INPUT_FILE="${1:-}"
BITRATE="${2:-768k}"
INCLUDE_ORIGINAL="${3:-yes}"
AUDIO_CODEC="${4:-eac3}"

# Controllo parametri
if [ -z "$INPUT_FILE" ]; then
    echo "USO: ./clearvoice_simple.sh \"video.mkv\" [bitrate] [originale] [codec]"
    exit 1
fi

# File di output
OUTPUT_FILE="${INPUT_FILE%.*}_clearvoice_simple.mkv"

# Controllo canali audio
CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$INPUT_FILE")
if [ "$CHANNELS" != "6" ]; then
    echo -e "\033[1;31mAudio non 5.1 (canali: $CHANNELS)\033[0m"
    echo -e "Convertire la traccia in 5.1 per usare ClearVoice.\nEsempio:\nffmpeg -i input.mkv -map 0 -c copy -c:a ac3 -ac 6 output_5.1.mkv"
    exit 1
fi

# Calcolo durata filmato
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT_FILE" | cut -d'.' -f1)

# Controllo durata minima
if [ "$DURATION" -lt 300 ]; then
    echo -e "\033[1;31mAttenzione:\033[0m File troppo corto ($DURATION secondi). Minimo consigliato: 5 minuti"
    echo -e "Continuare comunque? [s/N]: "
    read -r risposta
    case "$risposta" in
        [sS]|[sS][iI]) ;;
        *) echo -e "\033[1;31mOperazione annullata\033[0m"; exit 1 ;;
    esac
fi

# --- Segmentazione audio (analisi ottimizzata per precisione + velocità) ---

if [ "$DURATION" -le 1800 ]; then
    NUM_SEGMENTS=3; SEGMENT_DUR=210
elif [ "$DURATION" -le 3600 ]; then
    NUM_SEGMENTS=4; SEGMENT_DUR=240
elif [ "$DURATION" -le 5400 ]; then
    NUM_SEGMENTS=5; SEGMENT_DUR=270
elif [ "$DURATION" -le 7200 ]; then
    NUM_SEGMENTS=6; SEGMENT_DUR=300
else
    NUM_SEGMENTS=7; SEGMENT_DUR=330
fi

# --- Segmentazione audio ---

# Stampa informazioni di segmentazione
echo " "
HOURS=$((DURATION/3600))
MINUTES=$(((DURATION%3600)/60))
SECONDS=$((DURATION%60))
printf -v DURATION_FMT "%02d:%02d:%02d" $HOURS $MINUTES $SECONDS
MINUTES=$((DURATION/60))
echo -en "\033[1;34m[Info]\033[0m Durata filmato: "
echo -en "\033[1;33m${MINUTES} min\033[0m\n"
echo -en "\033[1;34m[Info]\033[0m Segmenti usati: "
echo -en "\033[1;33m${NUM_SEGMENTS}\033[0m"
echo -en " | Durata per segmento: "
echo -en "\033[1;33m${SEGMENT_DUR}s\033[0m\n"

# Calcolo dei punti di inizio segmento
START_LIMIT=120
END_LIMIT=120
# Adatta i limiti per file corti
if [ "$DURATION" -lt 600 ]; then
    START_LIMIT=30
    END_LIMIT=30
fi
AVAILABLE_DUR=$((DURATION - START_LIMIT - END_LIMIT))
# Protezione per durata negativa
if [ "$AVAILABLE_DUR" -lt 0 ]; then
    AVAILABLE_DUR=$((DURATION / 2))
    START_LIMIT=$((DURATION / 4))
fi
declare -a SEGMENT_STARTS=()
for ((i=0; i<NUM_SEGMENTS; i++)); do
    POS=$((START_LIMIT + (AVAILABLE_DUR * i / NUM_SEGMENTS)))
    SEGMENT_STARTS+=($POS)
done

echo -e "\033[1;36m[Attendere]\033[0m Analisi spettrale in corso, potrebbero essere necessari diversi minuti..."

# --- Analisi su tutti i segmenti ---

# Inizializza array per i valori di LUFS e LRA
declare -a LUFS_ARR=()
declare -a LRA_ARR=()
declare -a TP_ARR=()
for START in "${SEGMENT_STARTS[@]}"; do
    STATS=$(ffmpeg -nostdin -ss $START -t $SEGMENT_DUR -i "$INPUT_FILE" -map 0:a:0 -af loudnorm=print_format=summary -f null - 2>&1)
    LUFS_VAL=$(echo "$STATS" | grep -i 'Input Integrated' | grep -Eo '[-0-9\.]+')
    [ -z "$LUFS_VAL" ] && LUFS_VAL="0"
    LRA_VAL=$(echo "$STATS" | grep -i 'Input LRA' | grep -Eo '[-0-9\.]+')
    [ -z "$LRA_VAL" ] && LRA_VAL="0"
    TP_VAL=$(echo "$STATS" | grep -i 'Input True Peak' | grep -Eo '[-0-9\.]+')
    [ -z "$TP_VAL" ] && TP_VAL="0"
    LUFS_ARR+=("$LUFS_VAL")
    LRA_ARR+=("$LRA_VAL")
    TP_ARR+=("$TP_VAL")
done
# Calcola media LUFS e LRA
LUFS_SUM=0
LRA_SUM=0
TP_SUM=0
for ((i=0; i<${#LUFS_ARR[@]}; i++)); do
    LUFS_SUM=$(awk "BEGIN {print $LUFS_SUM+${LUFS_ARR[$i]}}")
    LRA_SUM=$(awk "BEGIN {print $LRA_SUM+${LRA_ARR[$i]}}")
    TP_SUM=$(awk "BEGIN {print $TP_SUM+${TP_ARR[$i]}}")
done
LUFS=$(awk "BEGIN {print $LUFS_SUM/${#LUFS_ARR[@]}}")
LRA=$(awk "BEGIN {print $LRA_SUM/${#LRA_ARR[@]}}")
TP=$(awk "BEGIN {print $TP_SUM/${#TP_ARR[@]}}")

echo -e "\033[1;35m[Info]\033[0m Loudnorm multi-analisi: LUFS=$LUFS | LRA=$LRA | TruPeak=$TP dBTP"

# --- Logica Adattiva e Definizione Filtri per Profilo ---

# Funzione per confronti sicuri usando awk invece di bc
safe_compare() {
    awk "BEGIN { print ($1) ? 1 : 0 }"
}

# Selezione profilo con range ottimizzati per lo Spider-Verse dell'audio
ACTION_PROFILE=$(safe_compare "$LRA > 12 && $LUFS < -18.5")
NETFLIX_PROFILE=$(safe_compare "$LUFS >= -18.5 && $LUFS <= -15.5 && $LRA >= 8 && $LRA <= 12")
CARTOON_PROFILE=$(safe_compare "$LUFS > -18.5 && $LRA < 8")

if [ "$ACTION_PROFILE" -eq 1 ]; then
    # --- PROFILO: Action/Horror/Sci-Fi/Musical/Cinecomic ---
    PROFILE_DESC="Action/Horror/Sci-Fi/Musical/Cinecomic"
    EQ_VOICE="[FC]highpass=f=100,equalizer=f=1200:w=0.8:g=2.5,equalizer=f=2800:w=0.9:g=1.5,volume=2.15,asoftclip[FCout];"
    EQ_SUB="[LFE]highpass=f=38,equalizer=f=60:w=0.2:g=-2.5,equalizer=f=80:w=1.0:g=2,equalizer=f=120:w=1.2:g=-3,volume=0.50[LFEout];"
    EQ_SURROUND="[SL]volume=2.15[SLout]; [SR]volume=2.15[SRout];"

elif [ "$NETFLIX_PROFILE" -eq 1 ]; then
    # --- PROFILO: Amazon/Netflix/Pop/Binge ---
    PROFILE_DESC="Amazon/Netflix/Pop/Binge"
    EQ_VOICE="[FC]highpass=f=100,equalizer=f=1200:w=0.8:g=2.5,equalizer=f=2800:w=0.9:g=1.5,volume=2.15,asoftclip[FCout];"
    EQ_SUB="[LFE]highpass=f=38,equalizer=f=60:w=0.2:g=-2.5,equalizer=f=80:w=1.0:g=3,equalizer=f=120:w=1.2:g=-2,volume=0.52[LFEout];"
    EQ_SURROUND="[SL]volume=2.1[SLout]; [SR]volume=2.1[SRout];"

elif [ "$CARTOON_PROFILE" -eq 1 ]; then
    # --- PROFILO: Cartoon/Disney/Musical/Drammedy/Anime ---
    PROFILE_DESC="Cartoon/Disney/Musical/Drammedy/Anime"
    EQ_VOICE="[FC]highpass=f=95,equalizer=f=1200:w=0.8:g=2.5,equalizer=f=2800:w=0.9:g=1.5,volume=2.1,asoftclip[FCout];"
    EQ_SUB="[LFE]highpass=f=38,equalizer=f=60:w=0.2:g=-2.5,equalizer=f=80:w=1.0:g=4,equalizer=f=120:w=1.2:g=-1,volume=0.54[LFEout];"
    EQ_SURROUND="[SL]volume=2.05[SLout]; [SR]volume=2.05[SRout];"

else
    # --- PROFILO: Fallback per contenuti ad alta dinamica ---
    PROFILE_DESC="Alta Dinamica/Blockbuster/Disaster"
    EQ_VOICE="[FC]highpass=f=100,equalizer=f=1200:w=0.8:g=2.5,equalizer=f=2800:w=0.9:g=1.5,volume=2.15,asoftclip[FCout];"
    EQ_SUB="[LFE]highpass=f=38,equalizer=f=60:w=0.2:g=-2.8,equalizer=f=80:w=0.8:g=2.2,equalizer=f=120:w=1.0:g=-3.5,volume=0.48[LFEout];"
    EQ_SURROUND="[SL]volume=2.15[SLout]; [SR]volume=2.15[SRout];"
fi
# Front Equalizer (Statico per tutti i profili)
EQ_FRONT="[FL]volume=1.0[FLout]; [FR]volume=1.0[FRout];"

# Filter Complex
FILTER_COMPLEX="[0:a:0]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][SL][SR]; \
${EQ_FRONT} \
${EQ_VOICE} \
${EQ_SUB} \
${EQ_SURROUND} \
[FLout][FRout][FCout][LFEout][SLout][SRout]join=inputs=6:channel_layout=5.1[clearvoice]"

# Dichiarazione array audio
declare -a AUDIO_ARGS=()

if [[ "${INCLUDE_ORIGINAL,,}" =~ ^(no|n|false)$ ]]; then
    LANG_CODE=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
    [ -z "$LANG_CODE" ] && LANG_CODE="ita"
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "title=ClearVoice $LANG_CODE ${AUDIO_CODEC} 5.1" -disposition:a:0 default)
elif [[ "${INCLUDE_ORIGINAL,,}" =~ ^(si|s|yes|y|true)$ ]]; then
    LANG_CODE=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
    [ -z "$LANG_CODE" ] && LANG_CODE="ita"
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "title=ClearVoice $LANG_CODE ${AUDIO_CODEC} 5.1" \
    -map 0:a:0 -c:a:1 copy -metadata:s:a:1 "title=Originale" -disposition:a:0 default -disposition:a:1 0)
else
    echo "Valore per 'originale' non riconosciuto: usa 'si'/'no'"
    exit 1
fi

echo -e "\033[1;32m[OK]\033[0m ClearVoice: Voce ottimizzata | Surround intelligente | LFE chirurgico | Protezione soft-clip"
echo -e "\033[1;33m[Profilo]\033[0m ${PROFILE_DESC}"

# Calcola e mostra i valori dei parametri applicati
# Estrazione più affidabile usando sed
VOICE_BOOST=$(echo "$EQ_VOICE" | sed -n 's/.*volume=\([0-9.]*\).*/\1/p' | head -n1)
[ -z "$VOICE_BOOST" ] && VOICE_BOOST="2.0" # valore di fallback
LFE_FACTOR=$(echo "$EQ_SUB" | sed -n 's/.*volume=\([0-9.]*\).*/\1/p' | head -n1)
[ -z "$LFE_FACTOR" ] && LFE_FACTOR="0.5" # valore di fallback
SURROUND_BOOST=$(echo "$EQ_SURROUND" | sed -n 's/.*volume=\([0-9.]*\).*/\1/p' | head -n1)
[ -z "$SURROUND_BOOST" ] && SURROUND_BOOST="2.0" # valore di fallback
FRONT_BOOST=$(echo "$EQ_FRONT" | sed -n 's/.*volume=\([0-9.]*\).*/\1/p' | head -n1)
[ -z "$FRONT_BOOST" ] && FRONT_BOOST="1.0" # valore di fallback
# Visualizza i parametri in modo chiaro
echo -e "\033[1;36m[Parametri]\033[0m Voice Boost: \033[1;33m${VOICE_BOOST}\033[0m dB | LFE Factor: \033[1;33m${LFE_FACTOR}\033[0m | Surround Boost: \033[1;33m${SURROUND_BOOST}\033[0m dB | Front: \033[1;33m${FRONT_BOOST}\033[0m dB"

# --- Prompt sovrascrittura file ---

# Controllo esistenza file
if [ -f "$OUTPUT_FILE" ]; then
    echo -ne "\033[1;31m[Attenzione]\033[0m Il file esiste già. Sovrascrivere? [s/N]: "
    read -r risposta
    case "$risposta" in
        [sS]|[sS][iI])
            echo -e "\033[1;32m[OK]\033[0m Sovrascrittura confermata"
            ;;
        *)
            echo -e "\033[1;31m[EXIT]\033[0m Sovrascrittura Annullata. "
            exit 1
            ;;
    esac
fi

# Esecuzione ffmpeg
ffmpeg -y -nostdin -loglevel error -stats -hide_banner -hwaccel auto -threads 0 \
    -i "$INPUT_FILE" -filter_complex "$FILTER_COMPLEX" \
    -map 0:v -c:v copy "${AUDIO_ARGS[@]}" \
    -map 0:s? -c:s copy \
    -map 0:t? -c:t copy "$OUTPUT_FILE"

echo -e "\033[1;32m[OK]\033[0m Fatto! Il file è pronto, tuning completato."
echo -e "\033[1;33mFile creato:\033[0m"
echo "$OUTPUT_FILE"
echo " "

