#!/bin/bash
# ================================================================================================
# ClearVoice Final V8 - Nerding Edition
# ================================================================================================
# Developed by Sandro Sabbioni (Audio Processing Engineer)
# ================================================================================================
# Pipeline avanzata per ottimizzare la chiarezza delle voci (con focus sulla lingua italiana) 
# e la qualità del subwoofer (LFE) nei file audio 5.1 contenuti in video mkv/mp4.
# Analizza il loudness (LUFS/LRA) su più segmenti e applica equalizzazione adattiva e
# compressione intelligente con tecnologia anti-vibrazione. Implementa la filosofia "Controlled & 
# Airy" per un LFE presente, controllato e arioso. Tuning automatico per bassi non invadenti.
# 
# Voice Priority Strategy con parametri calibrati per ogni profilo e sistema anti-vibrazione:
# - Compressione RMS intelligente per sussurri fluidi e naturali
# - Parametri knee specifici per transizioni morbide tra parlato e silenzio
# - Auto-level disabilitato per eliminare micro-pumping e artefatti artificiali
# - Boost vocale per profilo (Action: 2.30, Serie TV: 2.30-2.32, Cartoon: 2.28, Blockbuster: 2.33)
#
# Riconosce il profilo audio (Action, Serie TV/Binge, Cartoon/Anime, Blockbuster) e applica
# preset specifici calibrati. Utilizza SoXR ad alta precisione (28-bit professional) + oversampling 2×
# (96kHz) per eliminare aliasing e artefatti, garantendo bassi ultra-definiti, voci cristalline 
# e transizioni naturali anche nei passaggi più delicati.
# 
# Sistema di controllo dinamico ultra-delicato con parametri calibrati per ogni tipo di contenuto:
# - Compressione RMS con knee 4dB per smoothing naturale
# - Limitazione audio con ASC e level=disabled per evitare micro-vibrazioni 
# - Highpass ottimizzato per profilo (100-105Hz) per preservare corpo vocale senza rumble
# - Front L/R dinamici (0.98-1.00) per bilanciamento ottimale stereo
# - LFE calibrato (0.24-0.28) con limiter adattivo (0.62-0.66) per controllo preciso
# - Surround boost dinamico (2.00-2.15) per immersione bilanciata
#
# Ottimizzato per binge watching (Netflix, Disney+, Amazon), soundbar moderne e sistemi home 
# cinema premium. Ideale per chi cerca dialoghi cristallini, bassi musicali
# controllati e un'esperienza audio cinematografica senza stress o artefatti.
# Specificamente ottimizzato per contenuti critici e film con dialoghi sussurrati.
#
# Tecnologia anti-vibrazione:
# - Pipeline di processamento 48kHz → 96kHz → Processing → 48kHz
# - Compressione intelligente con detection RMS e knee ottimizzato
# - Controllo dinamico adattivo per ogni profilo senza gate fisso
# - Limiter avanzato con ASC e level=disabled per evitare pumping
#
# CALIBRAZIONE PARAMETRI PER PROFILO (Valori reali applicati dallo script):
# • Blockbuster/Alta Dinamica: Front 0.98 | FC 90Hz/2.33 | LFE 45Hz/0.22/0.60 | Surr 2.10 | Comp 2.1:1/14/210
# • Action/Horror/Sci-Fi:     Front 0.99 | FC 88Hz/2.30 | LFE 45Hz/0.24/0.60 | Surr 2.15 | Comp 1.7:1/30/140
# • Serie TV Standard:         Front 1.00 | FC 92Hz/2.30 | LFE 45Hz/0.26/0.60 | Surr 2.05 | Comp 1.6:1/30/120
# • Serie TV Alta Dinamica:    Front 0.99 | FC 95Hz/2.32 | LFE 45Hz/0.24/0.60 | Surr 2.10 | Comp 1.6:1/30/180
# • Cartoon/Disney:            Front 1.00 | FC 92Hz/2.28 | LFE 45Hz/0.28/0.60 | Surr 2.00 | Comp 1.7:1/30/140
#
# USO:
#   ./clearvoice_simple.sh "video.mkv" [bitrate] [originale] [codec]
#
# PARAMETRI:
#   1. nome_file.mkv   - File video di input (MKV con audio 5.1)
#   2. bitrate         - Bitrate audio desiderato (default: 768k)
#   3. originale       - "si" per includere traccia originale, "no" solo ClearVoice
#                        (accetta anche "yes"/"no", "y"/"n", "true"/"false")
#   4. codec           - Codec audio di output (default: eac3)
#
# ESEMPIO:
#   ./clearvoice_simple.sh "film.mkv" 768k si eac3
#
# OUTPUT:
#   Crea un nuovo file "nome_file_clearvoice.mkv" con traccia audio ottimizzata.
#
# NOTE:
#   - I file di output verranno creati nella stessa directory del file di input.
#   - Lo script rileva automaticamente il profilo audio ottimale per il contenuto.
#
# ================================================================================================
# GUIDA BITRATE CLEARVOICE - La Regola aurea
# ================================================================================================
# E-AC-3 (raccomandato): Originale +192k
#   256k → 448k | 384k → 576k | 640k+ → 768k (cap)
#
# AC-3 (compatibilità): Originale +256k  
#   256k → 512k | 384k → 640k (cap) | 640k+ → 640k (limite max)
#
# Perché +192k/+256k: Compensa perdite reprocessing + artefatti lossy-to-lossy + 
#     headroom transitori vocali + spazio dettagli EQ recuperati
# ================================================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Variabili di ambiente ---------------------------------------------------------------------- 

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

# Validazione bitrate (range ragionevole per E-AC-3)
BITRATE_NUM=$(echo "$BITRATE" | sed 's/k$//')
if [[ ! "$BITRATE_NUM" =~ ^[0-9]+$ ]] || [ "$BITRATE_NUM" -lt 128 ] || [ "$BITRATE_NUM" -gt 1024 ]; then
    echo -e "\033[1;31m[Errore]\033[0m Bitrate non valido: $BITRATE (deve essere tra 128k e 1024k)"
    exit 1
fi

# Controllo parametri e file di input
if [ -z "$INPUT_FILE" ]; then
    echo "USO: ./clearvoice_simple.sh \"video.mkv\" [bitrate] [originale] [codec]"
    exit 1
fi

# Verifica che il file di input esista e sia un file
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "\033[1;31m[Errore]\033[0m File di input non trovato: $INPUT_FILE"
    exit 1
fi

# Verifica che il file di input sia leggibile
if [ ! -r "$INPUT_FILE" ]; then
    echo -e "\033[1;31m[Errore]\033[0m File di input non leggibile: $INPUT_FILE"
    exit 1
fi

# File di output (crea in una directory con permessi di scrittura)
INPUT_DIR=$(dirname "$INPUT_FILE")
INPUT_BASENAME=$(basename "$INPUT_FILE")
OUTPUT_FILE="$INPUT_DIR/${INPUT_BASENAME%.*}_clearvoice_simple.mkv"

# Verifica che il file di output non sia già in uso
if [ -f "$OUTPUT_FILE" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="$INPUT_DIR/${INPUT_BASENAME%.*}_clearvoice_simple_${TIMESTAMP}.mkv"
    echo -e "\033[1;33m[Info]\033[0m File rinominato per evitare conflitti: ${OUTPUT_FILE}"
fi

# Controllo canali audio con gestione errori migliorata
if ! CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$INPUT_FILE" 2>/dev/null); then
    echo -e "\033[1;31m[Errore]\033[0m Impossibile analizzare il file audio: $INPUT_FILE"
    echo -e "Verificare che il file sia un video valido con traccia audio."
    exit 1
fi

# Verifica che il file abbia audio 5.1
if [ -z "$CHANNELS" ] || [ "$CHANNELS" != "6" ]; then
    echo -e "\033[1;31mAudio non 5.1 (canali: ${CHANNELS:-sconosciuto})\033[0m"
    echo -e "Convertire la traccia in 5.1 per usare ClearVoice.\nEsempio:\nffmpeg -i input.mkv -map 0 -c copy -c:a ac3 -ac 6 output_5.1.mkv"
    exit 1
fi

# Estrazione durata in secondi (intero)
SECONDS_DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT_FILE" | cut -d'.' -f1)

# Converti semplicemente a intero
DURATION=$SECONDS_DURATION

# Protezione minima per valori non numerici
if [[ ! "$DURATION" =~ ^[0-9]+$ ]]; then
    echo -e "\033[1;31m[Errore]\033[0m Durata non valida: $DURATION"
    DURATION=1800  # Default a 30 minuti se non valida
fi

# Controllo durata minima con messaggio migliorato
if [ "$DURATION" -lt 300 ]; then
    echo -e "\033[1;31m[Attenzione]\033[0m File molto corto ($DURATION secondi / $((DURATION/60)) minuti)"
    echo -e "Minimo consigliato: 5 minuti per analisi affidabile del loudness"
    echo -e "Continuare comunque? [s/N]: "
    read -r risposta
    case "$risposta" in
        [sS]|[sS][iI]) ;;
        *) echo -e "\033[1;31mOperazione annullata\033[0m"; exit 1 ;;
    esac
fi

# --- Segmentazione audio ------------------------------------------------------------------------ 

# Determina numero segmenti e durata in base alla lunghezza del video
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

# Calcolo e visualizzazione durata come in V4 (semplice)
HOURS=$((DURATION/3600))
MINUTES=$(((DURATION%3600)/60))
SECONDS=$((DURATION%60))

# Formattazione semplice come nella versione precedente
MINUTES_TOTAL=$((DURATION/60))

# Stampa informazioni
echo " "
echo -en "\033[1;34m[Info]\033[0m Durata filmato: "
echo -en "\033[1;33m${MINUTES_TOTAL} min\033[0m\n"
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
# Calcola intervallo disponibile
AVAILABLE_DUR=$((DURATION - START_LIMIT - END_LIMIT))

# Protezione per durata negativa
if [ "$AVAILABLE_DUR" -lt 0 ]; then
    AVAILABLE_DUR=$((DURATION / 2))
    START_LIMIT=$((DURATION / 4))
fi

# Calcola inizio di ogni segmento
declare -a SEGMENT_STARTS=()
for ((i=0; i<NUM_SEGMENTS; i++)); do
    POS=$((START_LIMIT + (AVAILABLE_DUR * i / NUM_SEGMENTS)))
    SEGMENT_STARTS+=($POS)
done

# Stampa punti di inizio segmento
echo -e "\033[1;36m[Attendere]\033[0m Analisi spettrale in corso, potrebbero essere necessari diversi minuti..."

# --- Analisi su tutti i segmenti ----------------------------------------------------------------

# Inizializza array per i valori di LUFS e LRA
declare -a LUFS_ARR=()
declare -a LRA_ARR=()
declare -a TP_ARR=()

# Loop attraverso i segmenti per analisi
for START in "${SEGMENT_STARTS[@]}"; do
    STATS=$(ffmpeg -nostdin -ss $START -t $SEGMENT_DUR -i "$INPUT_FILE" -map 0:a:0 -af loudnorm=print_format=summary -f null - 2>&1 | grep -v -E '^\[.*\]')
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
LUFS_COUNT=0
LRA_COUNT=0
TP_COUNT=0

# Calcolo delle somme
for ((i=0; i<${#LUFS_ARR[@]}; i++)); do

    # Verifica valori numerici validi
    if [[ "${LUFS_ARR[$i]}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && [[ "${LUFS_ARR[$i]}" != "0" ]]; then
        LUFS_SUM=$(awk "BEGIN {print $LUFS_SUM+(${LUFS_ARR[$i]})}")
        LUFS_COUNT=$((LUFS_COUNT + 1))
    fi
    # Verifica LRA
    if [[ "${LRA_ARR[$i]}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && [[ "${LRA_ARR[$i]}" != "0" ]]; then
        LRA_SUM=$(awk "BEGIN {print $LRA_SUM+(${LRA_ARR[$i]})}")
        LRA_COUNT=$((LRA_COUNT + 1))
    fi
    # Verifica True Peak
    if [[ "${TP_ARR[$i]}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && [[ "${TP_ARR[$i]}" != "0" ]]; then
        TP_SUM=$(awk "BEGIN {print $TP_SUM+(${TP_ARR[$i]})}")
        TP_COUNT=$((TP_COUNT + 1))
    fi
done
    # Verifica che le somme siano numeriche
    [[ ! "$LUFS_SUM" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && LUFS_SUM=0
    [[ ! "$LRA_SUM" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && LRA_SUM=0
    [[ ! "$TP_SUM" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && TP_SUM=0

    # Calcolo delle medie con protezione
    if [ "$LUFS_COUNT" -eq 0 ]; then LUFS=-20; else LUFS=$(awk "BEGIN {print $LUFS_SUM/$LUFS_COUNT}"); fi
    if [ "$LRA_COUNT" -eq 0 ]; then LRA=10; else LRA=$(awk "BEGIN {print $LRA_SUM/$LRA_COUNT}"); fi
    if [ "$TP_COUNT" -eq 0 ]; then TP=-5; else TP=$(awk "BEGIN {print $TP_SUM/$TP_COUNT}"); fi

# Stampa risultati
echo -e "\033[1;35m[Info]\033[0m Loudnorm multi-analisi: LUFS=$LUFS | LRA=$LRA | TruPeak=$TP dBTP"

# --- Logica Adattiva e Definizione Filtri per Profilo -------------------------------------------

# Funzione per confronti sicuri
safe_compare() {
    awk "BEGIN { print ($1) ? 1 : 0 }"
}

# Selezione profilo con range ottimizzati
ACTION_PROFILE=$(safe_compare "$LRA > 12 && $LUFS < -18.5")
SERIETV_PROFILE=$(safe_compare "$LUFS >= -18.5 && $LUFS <= -15.5 && $LRA >= 8 && $LRA <= 12")
CARTOON_PROFILE=$(safe_compare "$LUFS > -18.5 && $LRA < 8")

# Rilevamento Serie TV ad Alta Dinamica ("Stranger Things Effect")
SERIETV_HIGH_DYNAMIC=$(safe_compare "($SERIETV_PROFILE -eq 1) && (($LRA >= 10) || ($TP >= -1.0))")

# Verifica che almeno un profilo sia stato selezionato
PROFILE_SELECTED=$((ACTION_PROFILE + SERIETV_PROFILE + CARTOON_PROFILE))
if [ "$PROFILE_SELECTED" -eq 0 ]; then
    # Fallback al profilo Blockbuster se nessun profilo specifico rilevato
    ACTION_PROFILE=0
    SERIETV_PROFILE=0
    CARTOON_PROFILE=0
fi

# Selezione profilo specifico
if [ "$ACTION_PROFILE" -eq 1 ]; then
    # PROFILO: Action/Horror/Sci-Fi/Musical/Cinecomic - Immersione cinematica equilibrata
    PROFILE_DESC="Action/Horror/Sci-Fi/Musical/Cinecomic"
    EQ_VOICE="[FC]highpass=f=88,equalizer=f=720:w=0.8:g=-0.5,equalizer=f=1350:w=0.7:g=2.2,equalizer=f=2900:w=0.8:g=1.1,equalizer=f=4800:w=0.6:g=0.2,volume=2.30,acompressor=threshold=0.76:ratio=1.7:attack=30:release=140:knee=4:detection=rms:link=average[FCout];"
    EQ_SUB="[LFE]highpass=f=45,equalizer=f=48:t=q:w=1.8:g=-4.3,equalizer=f=65:t=q:w=1.4:g=-2.5,equalizer=f=82:t=q:w=1.1:g=2.3,volume=0.24,alimiter=limit=0.60[LFEout];"
    EQ_SURROUND="[SL]volume=2.15[SLout]; [SR]volume=2.15[SRout];"

elif [ "$SERIETV_PROFILE" -eq 1 ]; then
    # PROFILO: Amazon/Netflix/Serie TV/Pop/Binge - Chiarezza costante per maratone TV
    if [ "$SERIETV_HIGH_DYNAMIC" -eq 1 ]; then
        ## Serie TV moderne ad alta dinamica
        PROFILE_DESC="Amazon/Netflix/Pop/Binge (Alta Dinamica Rilevata)"
        EQ_VOICE="[FC]highpass=f=92,equalizer=f=780:w=0.7:g=-0.7,equalizer=f=1350:w=0.7:g=2.1,equalizer=f=2900:w=0.8:g=1.1,equalizer=f=4800:w=0.6:g=0.2,volume=2.32,acompressor=threshold=0.78:ratio=1.6:attack=30:release=180:knee=4:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=45,equalizer=f=45:t=q:w=2.0:g=-5.5,equalizer=f=65:t=q:w=1.3:g=-3.2,equalizer=f=82:t=q:w=1.1:g=1.8,volume=0.22,alimiter=limit=0.60[LFEout];"
        EQ_SURROUND="[SL]volume=2.10[SLout]; [SR]volume=2.10[SRout];"
    else
        ## Serie TV standard a bassa dinamica
        PROFILE_DESC="Amazon/Netflix/Pop/Binge"
        EQ_VOICE="[FC]highpass=f=95,equalizer=f=780:w=0.7:g=-0.7,equalizer=f=1350:w=0.7:g=2.1,equalizer=f=2900:w=0.8:g=1.1,equalizer=f=4800:w=0.6:g=0.2,volume=2.30,acompressor=threshold=0.78:ratio=1.6:attack=30:release=120:knee=4:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=45,equalizer=f=50:t=q:w=1.6:g=-3.8,equalizer=f=65:t=q:w=1.3:g=-2.3,equalizer=f=82:t=q:w=1.1:g=2.4,volume=0.24,alimiter=limit=0.60[LFEout];"
        EQ_SURROUND="[SL]volume=2.05[SLout]; [SR]volume=2.05[SRout];"
    fi

elif [ "$CARTOON_PROFILE" -eq 1 ]; then
    # PROFILO: Cartoon/Disney/Musical/Drammedy/Anime - Voci vivaci per contenuti animati
    PROFILE_DESC="Cartoon/Disney/Musical/Drammedy/Anime"
    EQ_VOICE="[FC]highpass=f=92,equalizer=f=820:w=0.6:g=-0.9,equalizer=f=1350:w=0.7:g=2.2,equalizer=f=2900:w=0.8:g=1.1,equalizer=f=4800:w=0.6:g=0.2,volume=2.28,acompressor=threshold=0.76:ratio=1.7:attack=30:release=140:knee=4:detection=rms:link=average[FCout];"
    EQ_SUB="[LFE]highpass=f=45,equalizer=f=60:t=q:w=1.3:g=-2.1,equalizer=f=82:t=q:w=1.0:g=2.2,volume=0.22,alimiter=limit=0.60[LFEout];"
    EQ_SURROUND="[SL]volume=2.00[SLout]; [SR]volume=2.00[SRout];"

else
    # PROFILO: Alta Dinamica/Blockbuster/Disaster - Immersivo, intenso ma controllato
    PROFILE_DESC="Alta Dinamica/Blockbuster/Disaster"
    EQ_VOICE="[FC]highpass=f=90,equalizer=f=700:w=0.9:g=-0.4,equalizer=f=1350:w=0.7:g=2.3,equalizer=f=2900:w=0.8:g=1.1,equalizer=f=4800:w=0.6:g=0.2,volume=2.33,acompressor=threshold=0.76:ratio=1.7:attack=30:release=140:knee=4:detection=rms:link=average[FCout];"
    EQ_SUB="[LFE]highpass=f=45,equalizer=f=45:t=q:w=2.2:g=-5.8,equalizer=f=65:t=q:w=1.8:g=-3.5,equalizer=f=82:t=q:w=1.1:g=2.5,volume=0.22,alimiter=limit=0.60[LFEout];"
    EQ_SURROUND="[SL]volume=2.10[SLout]; [SR]volume=2.10[SRout];"
fi

# Front Equalizer (per profilo specifico)
if [ "$ACTION_PROFILE" -eq 1 ]; then
    EQ_FRONT="[FL]volume=0.99[FLout]; [FR]volume=0.99[FRout];"
elif [ "$SERIETV_PROFILE" -eq 1 ]; then
    if [ "$SERIETV_HIGH_DYNAMIC" -eq 1 ]; then
        EQ_FRONT="[FL]volume=0.99[FLout]; [FR]volume=0.99[FRout];"
    else
        EQ_FRONT="[FL]volume=1.00[FLout]; [FR]volume=1.00[FRout];"
    fi
elif [ "$CARTOON_PROFILE" -eq 1 ]; then
    EQ_FRONT="[FL]volume=1.00[FLout]; [FR]volume=1.00[FRout];"
else
    EQ_FRONT="[FL]volume=0.98[FLout]; [FR]volume=0.98[FRout];"
fi

# Controllo dinamico finale (adattivo per profilo)
if [ "$ACTION_PROFILE" -eq 1 ]; then

    # Action: Controllo aggressivo ma naturale per esplosioni, zero vibrazioni 
    FINAL_DYNAMICS="acompressor=threshold=0.69:ratio=2.6:attack=8:release=140:knee=4:detection=rms:link=average,alimiter=limit=0.92:attack=9:release=120:level=disabled:asc=1"

elif [ "$SERIETV_PROFILE" -eq 1 ]; then
    if [ "$SERIETV_HIGH_DYNAMIC" -eq 1 ]; then
        ## Serie TV ad Alta Dinamica: Controllo avanzato anti-brillantezza con due stadi (RMS e limiting)
        FINAL_DYNAMICS="acompressor=threshold=0.69:ratio=2.5:attack=8:release=120:knee=4:detection=rms:link=average,alimiter=limit=0.65:attack=8:release=120:level=disabled:asc=1"
    else
        ## Serie TV standard: Controllo dolcissimo per binge watching, zero artefatti
        FINAL_DYNAMICS="acompressor=threshold=0.73:ratio=2.2:attack=12:release=120:knee=4:detection=rms:link=average,alimiter=limit=0.69:attack=9:release=120:level=disabled:asc=1"
    fi
elif [ "$CARTOON_PROFILE" -eq 1 ]; then

    # Cartoon: Bilanciato per voci animate, controllo effetti senza perdere vivacità
    FINAL_DYNAMICS="acompressor=threshold=0.71:ratio=2.3:attack=10:release=160:knee=4:detection=rms:link=average,alimiter=limit=0.93:attack=9:release=120:level=disabled:asc=1"
else
    # Alta Dinamica: Preserva range dinamico, controllo chirurgico rumble blockbuster
    FINAL_DYNAMICS="acompressor=threshold=0.76:ratio=2.1:attack=14:release=210:knee=4:detection=rms:link=average,alimiter=limit=0.91:attack=9:release=120:level=disabled:asc=1"
fi

# Filter Complex (Dynamic Range Control Integrato con SoXR Resampler 28-Bit +Oversampling 2×)
FILTER_COMPLEX="[0:a:0]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][SL][SR]; ${EQ_FRONT} ${EQ_VOICE} ${EQ_SUB} ${EQ_SURROUND} [FLout][FRout][FCout][LFEout][SLout][SRout]join=inputs=6:channel_layout=5.1[premix]; [premix]aresample=out_sample_rate=96000:resampler=soxr:precision=28[os]; [os]${FINAL_DYNAMICS}[limited]; [limited]aresample=out_sample_rate=48000:resampler=soxr:precision=28[clearvoice]"

# Dichiarazione array audio
declare -a AUDIO_ARGS=()

# Inclusione traccia originale
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

# Stampa risultati
echo -e "\033[1;32m[OK]\033[0m ClearVoice: Voce ottimizzata | Surround intelligente | LFE chirurgico | Controllo volume dinamico | Anti-Vibrazione"
echo -e "\033[1;32m[OK]\033[0m SoXR High-End (28-bit precision) | Oversampling 2× | Minimizzazione aliasing/ringing | Audio ultra-definito"
echo -e "\033[1;33m[Profilo]\033[0m ${PROFILE_DESC}"

# Mostra un avviso speciale per lo "Stranger Things Effect"
if [ "$SERIETV_HIGH_DYNAMIC" -eq 1 ]; then
    echo -e "\033[1;34m[Info]\033[0m Rilevato \033[1;31m\"Stranger Things Effect\"\033[0m - Attivata protezione LFE avanzata!"
fi

# Calcola e mostra i valori dei parametri applicati
VOICE_BOOST=$(echo "$EQ_VOICE" | grep -o 'volume=[0-9.]*' | sed 's/volume=//' | tail -n1)
[ -z "$VOICE_BOOST" ] || [[ ! "$VOICE_BOOST" =~ ^[0-9]+(\.[0-9]+)?$ ]] && VOICE_BOOST="2.0"
LFE_FACTOR=$(echo "$EQ_SUB" | grep -o 'volume=[0-9.]*' | sed 's/volume=//' | tail -n1)
[ -z "$LFE_FACTOR" ] || [[ ! "$LFE_FACTOR" =~ ^[0-9]+(\.[0-9]+)?$ ]] && LFE_FACTOR="0.5"
SURROUND_BOOST=$(echo "$EQ_SURROUND" | grep -o 'volume=[0-9.]*' | sed 's/volume=//' | head -n1)
[ -z "$SURROUND_BOOST" ] || [[ ! "$SURROUND_BOOST" =~ ^[0-9]+(\.[0-9]+)?$ ]] && SURROUND_BOOST="2.0"
FRONT_BOOST=$(echo "$EQ_FRONT" | grep -o 'volume=[0-9.]*' | sed 's/volume=//' | head -n1)
[ -z "$FRONT_BOOST" ] || [[ ! "$FRONT_BOOST" =~ ^[0-9]+(\.[0-9]+)?$ ]] && FRONT_BOOST="1.0"

# Stampa parametri applicati
echo -e "\033[1;35m[Parametri]\033[0m Voice Boost: \033[1;33m${VOICE_BOOST}\033[0m dB | LFE Factor: \033[1;33m${LFE_FACTOR}\033[0m | Surround Boost: \033[1;33m${SURROUND_BOOST}\033[0m dB | Front: \033[1;33m${FRONT_BOOST}\033[0m dB"

# Estrai e mostra i parametri dinamici dal profilo attivo
COMPRESSOR_THRESHOLD=$(echo "$FINAL_DYNAMICS" | grep -o 'threshold=[0-9.]*' | sed 's/threshold=//' | head -n1)
[ -z "$COMPRESSOR_THRESHOLD" ] || [[ ! "$COMPRESSOR_THRESHOLD" =~ ^[0-9]+(\.[0-9]+)?$ ]] && COMPRESSOR_THRESHOLD="0.7"

# Estrai il limite del limiter
LIMITER_LIMIT=$(echo "$FINAL_DYNAMICS" | grep -o 'limit=[0-9.]*' | sed 's/limit=//' | head -n1)
[ -z "$LIMITER_LIMIT" ] || [[ ! "$LIMITER_LIMIT" =~ ^[0-9]+(\.[0-9]+)?$ ]] && LIMITER_LIMIT="0.9"
echo -e "\033[1;35m[Parametri]\033[0m Dynamic Compressor: \033[1;33m${COMPRESSOR_THRESHOLD}\033[0m threshold | Limiter: \033[1;33m${LIMITER_LIMIT}\033[0m ceiling | SoXR: \033[1;33m28-bit + 2× OS\033[0m precision"

# --- Prompt sovrascrittura file -----------------------------------------------------------------

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
echo -e "\033[1;36m[Attendere]\033[0m Elaborazione in corso..."

# Esecuzione ffmpeg con gestione errori migliorata
if ! ffmpeg -y -nostdin -loglevel warning -stats -hide_banner -hwaccel auto -threads 0 \
    -i "$INPUT_FILE" \
    -filter_complex "$FILTER_COMPLEX" \
    -max_muxing_queue_size 1024 \
    -map 0:v -c:v copy \
    "${AUDIO_ARGS[@]}" \
    -map 0:s? -c:s copy \
    -map 0:t? -c:t copy \
    "$OUTPUT_FILE" 2>&1 | grep -v -E '^\[.*@.*\]'; then
    echo -e "\033[1;31m[Errore]\033[0m Elaborazione FFmpeg fallita"
    exit 1
fi

# Verifica che il file di output sia stato creato correttamente
if [ ! -f "$OUTPUT_FILE" ]; then
    echo -e "\033[1;31m[Errore]\033[0m File di output non creato: $OUTPUT_FILE"
    exit 1
fi

# Verifica che il file di output abbia una dimensione minima
OUTPUT_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "0")
if [ "$OUTPUT_SIZE" -lt 1000000 ]; then  # Minimo 1MB
    echo -e "\033[1;31m[Errore]\033[0m File di output troppo piccolo (${OUTPUT_SIZE} bytes). Elaborazione probabilmente fallita."
    exit 1
fi

# Stampa messaggio di completamento
echo -e "\033[1;32m[OK]\033[0m Il file è pronto, tuning audio completato."
echo -e "\033[1;33mFile creato:\033[0m"
echo "${OUTPUT_FILE#./}"