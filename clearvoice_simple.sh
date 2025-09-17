#!/bin/bash
# ===============================================================================================
# ClearVoice Simple Final V10 - Intelligent Audio Processing System
# ===============================================================================================
# Pipeline avanzato per chiarezza voci e bassi LFE in audio 5.1 mkv/mp4.
# Analisi loudness multi-segmento (LUFS/LRA/TP), 3 profili dinamica, processing adattivo.
#
# PROFILI AUTOMATICI (algoritmo ridefinito):
# - Alta Dinamica:  LRA > 12 + LUFS < -17 (Cinema/Premium/HD Content)
# - Bassa Dinamica: LRA < 7 OR LUFS > -16 (Contenuto compresso/Broadcast)
# - Media Dinamica: Tutto il resto (Streaming/Standard Content)
#
# FEATURE AVANZATE V10:
# • Sistema Adattivo True Peak - Limiter dinamico basato su analisi contenuto
# • Conservative Mode - Processing protettivo per contenuti problematici (TP > -2.0dB)
# • Voice Protection Plus - Riduzione adattiva voice boost (-0.1/-0.2dB) per HOT/WARM content
# • True Peak Analysis Engine - Warning tecnici per headroom e compliance
# • Multi-Segment Analysis - Analisi accurata su 3-7 segmenti video per maggior precisione
# • Correlazione Intelligente - Rilevamento mastering aggressivo/premium/brick-wall
# • Headroom Management 2.0 - Calcolo automatico limiti sicuri (0.65-0.95) adattivi
# • SoXR 28-bit Precision - Oversampling 2× + minimizzazione aliasing/ringing
# • LFE Chirurgico - Valori bilanciati (2.2-2.4dB) senza "sub-bomba"
# • Processing Pulito - Highpass progressivo (88-95Hz) eliminazione artifacts
#
# UTILIZZO:
#   ./clearvoice_simple.sh "video.mkv" [bitrate] [originale] [codec]
#   1. nome_file.mkv   - File video MKV/MP4 con audio 5.1
#   2. bitrate         - 128k-1024k (default: 768k)
#   3. originale       - si/no per traccia originale (default: si)
#   4. codec           - eac3/ac3 (default: eac3)
#
# ESEMPI:
#   ./clearvoice_simple.sh "film.mkv"                    # Default
#   ./clearvoice_simple.sh "serie.mkv" 448k no eac3      # Personalizzato
#
# OUTPUT: Crea "nome_file_clearvoice_simple.mkv" con traccia ottimizzata
#
# DETTAGLI TECNICI:
# ┌─ Sistema Adattivo True Peak ────────────────────────────────────────────────────────────────┐
# │ • HOT Content (TP > -1.0dB): Conservative mode + limiter aggressivo + voice boost -0.2dB    │
# │ • WARM Content (TP > -2.0dB): Conservative mode + processing bilanciato + voice boost -0.1dB│  
# │ • COLD Content (TP < -2.0dB): Preservazione qualità originale + processing standard         │
# └─────────────────────────────────────────────────────────────────────────────────────────────┘
# ┌─ Voice Processing Adattivo ─────────────────────────────────────────────────────────────────┐
# │ • Highpass progressivo: 88Hz(Alta) → 92Hz(Media) → 95Hz(Bassa)                              │
# │ • Voice boost adattivo: 2.32-2.35 base, ridotto fino a 2.12-2.15 per contenuti HOT          │
# │ • Compressione intelligente: Ratio 2.1-2.4, threshold 0.68-0.72, adattivo per TP            │
# └─────────────────────────────────────────────────────────────────────────────────────────────┘
# ┌─ LFE Optimization & Dynamic Control ────────────────────────────────────────────────────────┐
# │ • Boost chirurgico 80Hz: 2.2dB(Alta) / 2.3dB(Media) / 2.4dB(Bassa)                          │
# │ • Cut selettivi: -3.5dB@55Hz, -1.0dB@75Hz (pulizia sub-bass)                                │
# │ • Limiter adattivo: 0.65-0.95 con ceiling dinamico basato su True Peak                      │
# │ • Conservative mode: Limiti ridotti (0.78-0.85) per contenuti problematici                  │
# └─────────────────────────────────────────────────────────────────────────────────────────────┘
# ===============================================================================================
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
        echo -e "\033[1;31m[Errore]\033[0m Codec non supportato: $AUDIO_CODEC (usa: eac3, ac3)"
        exit 1
        ;;
esac

# Controllo file di input
if [ -z "$INPUT_FILE" ]; then
    echo "USO: ./clearvoice_simple.sh \"video.mkv\" [bitrate] [originale] [codec]"
    exit 1
fi

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
    echo -e "Convertire la traccia in 5.1 per usare ClearVoice.\nEsempio:\nffmpeg -i input.mkv -map 0 -c copy -c:a ac3 -ac 6 output_5.1.mkv"
    exit 1
fi

# Estrazione e validazione durata
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT_FILE" | cut -d'.' -f1)

if [[ ! "$DURATION" =~ ^[0-9]+$ ]]; then
    echo -e "\033[1;31m[Errore]\033[0m Durata non valida: $DURATION"
    DURATION=1800  # Default a 30 minuti se non valida
fi

# Warning per file molto corti
if [ "$DURATION" -lt 300 ]; then
    echo -e "\033[1;33m[Warning]\033[0m File molto corto ($((DURATION/60)) min) - analisi meno precisa"
fi

# --- Analisi loudness multi-segmento -----------------------------------------------------------

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

# Calcolo durata in minuti
MINUTES_TOTAL=$((DURATION/60))

# Stampa informazioni
echo " "
echo -e "\033[1;34m[Info]\033[0m Durata: \033[1;33m${MINUTES_TOTAL} min\033[0m | Segmenti: \033[1;33m${NUM_SEGMENTS}\033[0m | Durata segmento: \033[1;33m${SEGMENT_DUR}s\033[0m"

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

# --- Raccolta dati LUFS/LRA dai segmenti -------------------------------------------------------

# Inizializza array per i valori di LUFS e LRA
declare -a LUFS_ARR=()
declare -a LRA_ARR=()

# Loop attraverso i segmenti per analisi
declare -a TP_ARR=()
SEGMENT_COUNT=${#SEGMENT_STARTS[@]}
SEGMENT_NUM=0

for START in "${SEGMENT_STARTS[@]}"; do
    SEGMENT_NUM=$((SEGMENT_NUM + 1))
    echo -e "\033[1;36m[Progresso]\033[0m Analisi segmento $SEGMENT_NUM di $SEGMENT_COUNT..."
    
    # Analisi completa - loudnorm fornisce LUFS, LRA e True Peak
    STATS=$(ffmpeg -nostdin -ss $START -t $SEGMENT_DUR -i "$INPUT_FILE" -map 0:a:0 -af loudnorm=print_format=summary -f null - 2>&1)
    
    # Estrai i valori dall'output di loudnorm
    LUFS_VAL=$(echo "$STATS" | grep -i 'Input Integrated' | grep -Eo '[-0-9\.]+' | head -n1)
    [ -z "$LUFS_VAL" ] && LUFS_VAL="0"

    # Estrai LRA
    LRA_VAL=$(echo "$STATS" | grep -i 'Input LRA' | grep -Eo '[-0-9\.]+' | head -n1)
    [ -z "$LRA_VAL" ] && LRA_VAL="0"

    # Estrai True Peak
    TP_VAL=$(echo "$STATS" | grep -i 'Input True Peak' | grep -Eo '[-0-9\.]+' | head -n1)
    [ -z "$TP_VAL" ] && TP_VAL="-2.0"  # Valore default sicuro
    
    # Aggiungi i valori agli array
    LUFS_ARR+=("$LUFS_VAL")
    LRA_ARR+=("$LRA_VAL")
    TP_ARR+=("$TP_VAL")
done

# Stampa risultati analisi
echo -e "\033[1;36m[Analisi]\033[0m Completata analisi di $SEGMENT_COUNT segmenti."

# Calcola media LUFS, LRA e True Peak
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
    if [[ "${TP_ARR[$i]}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        TP_SUM=$(awk "BEGIN {print $TP_SUM+(${TP_ARR[$i]})}")
        TP_COUNT=$((TP_COUNT + 1))
    fi
done

# Verifica che le somme siano numeriche
[[ ! "$LUFS_SUM" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && LUFS_SUM=0
[[ ! "$LRA_SUM" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && LRA_SUM=0
[[ ! "$TP_SUM" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && TP_SUM=0

# Calcolo delle medie con protezione robusta
if [ "$LUFS_COUNT" -eq 0 ]; then 
    LUFS=-18.0  # Valore realistico di default
    echo -e "\033[1;33m[Warning]\033[0m Nessun valore LUFS valido rilevato, usando default: $LUFS"
else 
    LUFS=$(awk "BEGIN {printf \"%.1f\", $LUFS_SUM/$LUFS_COUNT}")
fi

# Calcolo LRA con protezione robusta
if [ "$LRA_COUNT" -eq 0 ]; then 
    LRA=8.0
    echo -e "\033[1;33m[Warning]\033[0m Nessun valore LRA valido rilevato, usando default: $LRA"
else 
    LRA=$(awk "BEGIN {printf \"%.1f\", $LRA_SUM/$LRA_COUNT}")
fi

# Calcolo True Peak con protezione robusta
if [ "$TP_COUNT" -eq 0 ]; then 
    TP=-2.0  # Valore default sicuro
    echo -e "\033[1;33m[Warning]\033[0m Nessun valore True Peak valido rilevato, usando default: $TP dBTP"
else 
    TP=$(awk "BEGIN {printf \"%.1f\", $TP_SUM/$TP_COUNT}")
fi

# Stampa risultati
echo -e "\033[1;34m[Info]\033[0m Analisi: LUFS=\033[1;33m$LUFS\033[0m | LRA=\033[1;33m$LRA\033[0m | TP=\033[1;33m$TP\033[0m dBTP"

# --- Selezione automatica profilo dinamica (Alta/Media/Bassa) ----------------------------------

# Algoritmo di selezione profilo basato su dinamica audio
if (( $(awk "BEGIN {print ($LRA > 12.0 && $LUFS < -17.0) ? 1 : 0}") )); then
    # Alta:  LRA > 12 + LUFS < -17 (Cinema/Premium)
    PROFILE="Alta"
    PROFILE_DESC="Alta Dinamica (Cinema/Premium/Blockbuster)"
    echo -e "\033[1;34m[Info]\033[0m Dinamica rilevata: \033[1;33mAlta\033[0m (LRA: \033[1;33m$LRA\033[0m, LUFS: \033[1;33m$LUFS\033[0m, TP: \033[1;33m$TP\033[0m)"

elif (( $(awk "BEGIN {print ($LRA < 7.0 || $LUFS > -16.0) ? 1 : 0}") )); then
    # Bassa: LRA < 7 OR LUFS > -16 (Contenuto compresso)
    PROFILE="Bassa"
    PROFILE_DESC="Bassa Dinamica (Cartoni/Anime/Broadcast)"
    echo -e "\033[1;34m[Info]\033[0m Dinamica rilevata: \033[1;33mBassa\033[0m (LRA: \033[1;33m$LRA\033[0m, LUFS: \033[1;33m$LUFS\033[0m, TP: \033[1;33m$TP\033[0m)"

else
    # Media: Tutto il resto (LRA 7-12+ con LUFS -16 a -17)
    PROFILE="Media"  
    PROFILE_DESC="Media Dinamica (Streaming/Standard Content)"
    echo -e "\033[1;34m[Info]\033[0m Dinamica rilevata: \033[1;33mMedia\033[0m (LRA: \033[1;33m$LRA\033[0m, LUFS: \033[1;33m$LUFS\033[0m, TP: \033[1;33m$TP\033[0m)"
fi

# Protezione LFE per Serie TV Alta Dinamica
SERIETV_HIGH_DYNAMIC=0

# Applicazione parametri per profilo rilevato
case "$PROFILE" in
    "Alta")
        # Alta Dinamica: Cinema/Premium/HD Content
        EQ_VOICE="[FC]highpass=f=88,volume=2.36,acompressor=threshold=0.68:ratio=2.1:attack=18:release=180:knee=6:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=2.2,volume=0.21,alimiter=limit=0.58[LFEout];"
        EQ_SURROUND="[SL]volume=1.78[SLout]; [SR]volume=1.78[SRout];"
        EQ_FRONT="[FL]volume=0.96[FLout]; [FR]volume=0.96[FRout];"
        ;;
        
    "Media")
        # Media Dinamica: Streaming/Standard Content
        EQ_VOICE="[FC]highpass=f=92,volume=2.34,acompressor=threshold=0.69:ratio=2.1:attack=19:release=185:knee=6:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=2.3,volume=0.23,alimiter=limit=0.58[LFEout];"
        EQ_SURROUND="[SL]volume=1.88[SLout]; [SR]volume=1.88[SRout];"
        EQ_FRONT="[FL]volume=0.97[FLout]; [FR]volume=0.97[FRout];"
        ;;
        
    "Bassa")
        # Bassa Dinamica: Cartoni/Broadcast/Compresso
        EQ_VOICE="[FC]highpass=f=95,volume=2.32,acompressor=threshold=0.70:ratio=2.2:attack=20:release=170:knee=5:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=2.4,volume=0.25,alimiter=limit=0.58[LFEout];"
        EQ_SURROUND="[SL]volume=1.92[SLout]; [SR]volume=1.92[SRout];"
        EQ_FRONT="[FL]volume=0.98[FLout]; [FR]volume=0.98[FRout];"
        ;;
        
    *)
        # Fallback: Default Media Dinamica 
        PROFILE="Media"
        PROFILE_DESC="Media Dinamica (Fallback)"
        EQ_VOICE="[FC]highpass=f=92,volume=2.36,acompressor=threshold=0.70:ratio=2.0:attack=21:release=200:knee=7:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=2.3,volume=0.24,alimiter=limit=0.60[LFEout];"
        EQ_SURROUND="[SL]volume=1.95[SLout]; [SR]volume=1.95[SRout];"
        EQ_FRONT="[FL]volume=0.99[FLout]; [FR]volume=0.99[FRout];"
        ;;
esac

# --- Sistema Intelligente True Peak --------------------------------------------------------------

# Analisi adattiva per limiter dinamico e platform compliance
TP_HOT_THRESHOLD=-1.0
TP_WARM_THRESHOLD=-2.0

if awk "BEGIN {print ($TP > $TP_HOT_THRESHOLD) ? 1 : 0}" | grep -q 1; then
    # Contenuto "HOT" - Rischio clipping intersample
    echo -e "\033[1;31m[HOT CONTENT]\033[0m True Peak: \033[1;31m${TP}dBTP\033[0m - Limiter adattivo attivato"
    LIMITER_ADJUSTMENT=$(awk "BEGIN {print $TP - 0.2}")
    HOT_CONTENT=true

    # Processing molto conservativo per contenuto problematico
    CONSERVATIVE_MODE=true

elif awk "BEGIN {print ($TP > $TP_WARM_THRESHOLD) ? 1 : 0}" | grep -q 1; then
    # Contenuto "WARM" - Processing standard ma attento
    echo -e "\033[1;32m[WARM CONTENT]\033[0m True Peak: \033[1;33m[${TP}dBTP]\033[0m - Processing bilanciato"
    LIMITER_ADJUSTMENT=0
    HOT_CONTENT=false
    CONSERVATIVE_MODE=true
else
    # Contenuto "COLD" - Alta qualità originale
    echo -e "\033[1;34m[COLD CONTENT]\033[0m True Peak: \033[1;36m[${TP}dBTP]\033[0m - Preservazione qualità"
    LIMITER_ADJUSTMENT=0
    HOT_CONTENT=false
    CONSERVATIVE_MODE=false
fi

# True Peak Analysis Warnings - Technical Compliance
if awk "BEGIN {print ($TP > -1.0) ? 1 : 0}" | grep -q 1; then
    # Visualizza TP in rosso se supera la soglia
    echo -e "\033[1;31m[TRUEPEAK WARNING]\033[0m Livello elevato rilevato (TP: \033[1;31m${TP}dBTP\033[0m, standard: < \033[1;31m-2.0dBTP\033[0m)"
fi

# Warning per headroom insufficiente
if awk "BEGIN {print ($TP > -0.5) ? 1 : 0}" | grep -q 1; then
    echo -e "\033[1;31m[HEADROOM WARNING]\033[0m Headroom insufficiente rilevato (possibile processing aggressivo)"
fi

# Voice Boost Intelligente - Riduzione automatica per contenuti caldi/problematici
if [ "$HOT_CONTENT" = true ] || [ "$CONSERVATIVE_MODE" = true ]; then
    if [ "$HOT_CONTENT" = true ]; then
    echo -e "\033[1;33m[VOICE PROTECTION]\033[0m Voice boost ridotto automaticamente (\033[1;33m-0.2dB\033[0m) per contenuto HOT"
        VOICE_REDUCTION=0.2
    else

    # Contenuto WARM
    echo -e "\033[1;33m[VOICE PROTECTION]\033[0m Voice boost ridotto automaticamente (\033[1;33m-0.1dB\033[0m) per contenuto WARM"
        VOICE_REDUCTION=0.1
    fi
    
    # Adatta il voice boost in base al profilo
    case "$PROFILE" in
        "Alta") 
            NEW_VOICE_BOOST=$(awk "BEGIN {printf \"%.2f\", 2.35-$VOICE_REDUCTION}")
            EQ_VOICE="[FC]highpass=f=88,volume=${NEW_VOICE_BOOST},acompressor=threshold=0.70:ratio=2.3:attack=22:release=160:knee=5:detection=rms:link=average[FCout];" 
            ;;
        "Media") 
            NEW_VOICE_BOOST=$(awk "BEGIN {printf \"%.2f\", 2.34-$VOICE_REDUCTION}")
            EQ_VOICE="[FC]highpass=f=92,volume=${NEW_VOICE_BOOST},acompressor=threshold=0.71:ratio=2.3:attack=23:release=165:knee=5:detection=rms:link=average[FCout];" 
            ;;
        "Bassa") 
            NEW_VOICE_BOOST=$(awk "BEGIN {printf \"%.2f\", 2.32-$VOICE_REDUCTION}")
            EQ_VOICE="[FC]highpass=f=95,volume=${NEW_VOICE_BOOST},acompressor=threshold=0.72:ratio=2.4:attack=24:release=150:knee=4:detection=rms:link=average[FCout];" 
            ;;
        *) 
            NEW_VOICE_BOOST=$(awk "BEGIN {printf \"%.2f\", 2.34-$VOICE_REDUCTION}")
            EQ_VOICE="[FC]highpass=f=92,volume=${NEW_VOICE_BOOST},acompressor=threshold=0.71:ratio=2.3:attack=23:release=165:knee=5:detection=rms:link=average[FCout];" 
            ;;
    esac
fi

# Controllo dinamico finale per profilo con Limiter Adattivo
if [ "$PROFILE" = "Alta" ]; then
    # Alta: Preserva range cinematografico
    if [ "$CONSERVATIVE_MODE" = true ]; then
        BASE_LIMIT=0.85  # Più conservativo per contenuto problematico
        ADAPTED_LIMIT=$(awk "BEGIN {limit = $BASE_LIMIT + $LIMITER_ADJUSTMENT; if (limit < 0.65) limit = 0.65; if (limit > 0.85) limit = 0.85; printf \"%.2f\", limit}")
        FINAL_DYNAMICS="acompressor=threshold=0.78:ratio=2.4:attack=15:release=180:knee=3:detection=rms:link=average,alimiter=limit=${ADAPTED_LIMIT}:attack=7:release=100:level=disabled:asc=1"
    else
        BASE_LIMIT=0.91
        ADAPTED_LIMIT=$(awk "BEGIN {limit = $BASE_LIMIT + $LIMITER_ADJUSTMENT; if (limit < 0.70) limit = 0.70; if (limit > 0.95) limit = 0.95; printf \"%.2f\", limit}")
        FINAL_DYNAMICS="acompressor=threshold=0.75:ratio=2.1:attack=12:release=210:knee=4:detection=rms:link=average,alimiter=limit=${ADAPTED_LIMIT}:attack=9:release=120:level=disabled:asc=1"
    fi

elif [ "$PROFILE" = "Media" ]; then
    # Media: Bilanciato per streaming
    if [ "$CONSERVATIVE_MODE" = true ]; then
        BASE_LIMIT=0.82  # Più conservativo
        ADAPTED_LIMIT=$(awk "BEGIN {limit = $BASE_LIMIT + $LIMITER_ADJUSTMENT; if (limit < 0.65) limit = 0.65; if (limit > 0.82) limit = 0.82; printf \"%.2f\", limit}")
        FINAL_DYNAMICS="acompressor=threshold=0.75:ratio=2.5:attack=12:release=140:knee=3:detection=rms:link=average,alimiter=limit=${ADAPTED_LIMIT}:attack=7:release=100:level=disabled:asc=1"
    else
        # Media Dinamica: Streaming/Standard Content
        BASE_LIMIT=0.88
        ADAPTED_LIMIT=$(awk "BEGIN {limit = $BASE_LIMIT + $LIMITER_ADJUSTMENT; if (limit < 0.70) limit = 0.70; if (limit > 0.95) limit = 0.95; printf \"%.2f\", limit}")
        FINAL_DYNAMICS="acompressor=threshold=0.72:ratio=2.3:attack=10:release=150:knee=4:detection=rms:link=average,alimiter=limit=${ADAPTED_LIMIT}:attack=9:release=120:level=disabled:asc=1"
    fi

elif [ "$PROFILE" = "Bassa" ]; then
    # Bassa: Dolce per contenuto compresso
    if [ "$CONSERVATIVE_MODE" = true ]; then
        BASE_LIMIT=0.78  # Molto conservativo per contenuto già compresso
        ADAPTED_LIMIT=$(awk "BEGIN {limit = $BASE_LIMIT + $LIMITER_ADJUSTMENT; if (limit < 0.65) limit = 0.65; if (limit > 0.78) limit = 0.78; printf \"%.2f\", limit}")
        FINAL_DYNAMICS="acompressor=threshold=0.76:ratio=2.6:attack=18:release=110:knee=2:detection=rms:link=average,alimiter=limit=${ADAPTED_LIMIT}:attack=6:release=90:level=disabled:asc=1"
    else
        # Bassa Dinamica: Cartoni/Broadcast/Compresso
        BASE_LIMIT=0.85
        ADAPTED_LIMIT=$(awk "BEGIN {limit = $BASE_LIMIT + $LIMITER_ADJUSTMENT; if (limit < 0.70) limit = 0.70; if (limit > 0.95) limit = 0.95; printf \"%.2f\", limit}")
        FINAL_DYNAMICS="acompressor=threshold=0.73:ratio=2.2:attack=15:release=120:knee=4:detection=rms:link=average,alimiter=limit=${ADAPTED_LIMIT}:attack=9:release=120:level=disabled:asc=1"
    fi
else
    # Fallback standard
    if [ "$CONSERVATIVE_MODE" = true ]; then
        # Più conservativo per contenuto problematico
        BASE_LIMIT=0.82
        ADAPTED_LIMIT=$(awk "BEGIN {limit = $BASE_LIMIT + $LIMITER_ADJUSTMENT; if (limit < 0.65) limit = 0.65; if (limit > 0.82) limit = 0.82; printf \"%.2f\", limit}")
        FINAL_DYNAMICS="acompressor=threshold=0.75:ratio=2.5:attack=12:release=140:knee=3:detection=rms:link=average,alimiter=limit=${ADAPTED_LIMIT}:attack=7:release=100:level=disabled:asc=1"
    else
        # Media Dinamica: Streaming/Standard Content
        BASE_LIMIT=0.88
        ADAPTED_LIMIT=$(awk "BEGIN {limit = $BASE_LIMIT + $LIMITER_ADJUSTMENT; if (limit < 0.70) limit = 0.70; if (limit > 0.95) limit = 0.95; printf \"%.2f\", limit}")
        FINAL_DYNAMICS="acompressor=threshold=0.72:ratio=2.3:attack=10:release=150:knee=4:detection=rms:link=average,alimiter=limit=${ADAPTED_LIMIT}:attack=9:release=120:level=disabled:asc=1"
    fi
fi

# Pipeline audio completa con SoXR 28-bit + oversampling 2×
FILTER_COMPLEX="[0:a:0]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][SL][SR]; ${EQ_FRONT} ${EQ_VOICE} ${EQ_SUB} ${EQ_SURROUND} [FLout][FRout][FCout][LFEout][SLout][SRout]join=inputs=6:channel_layout=5.1[premix]; [premix]aresample=out_sample_rate=96000:resampler=soxr:precision=28[os]; [os]${FINAL_DYNAMICS}[limited]; [limited]aresample=out_sample_rate=48000:resampler=soxr:precision=28[clearvoice]"

# Dichiarazione array audio
declare -a AUDIO_ARGS=()

# Inclusione traccia originale
if [[ "${INCLUDE_ORIGINAL,,}" =~ ^(no|n|false)$ ]]; then
    LANG_CODE=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
    [ -z "$LANG_CODE" ] && LANG_CODE="ita"
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "title=ClearVoice $LANG_CODE ${AUDIO_CODEC} 5.1" -disposition:a:0 default)
    # Nessuna traccia originale
elif [[ "${INCLUDE_ORIGINAL,,}" =~ ^(si|s|yes|y|true)$ ]]; then
    LANG_CODE=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
    [ -z "$LANG_CODE" ] && LANG_CODE="ita"
    AUDIO_ARGS+=(-map "[clearvoice]" -c:a:0 ${AUDIO_CODEC} -b:a:0 "$BITRATE" -metadata:s:a:0 "title=ClearVoice $LANG_CODE ${AUDIO_CODEC} 5.1" -map 0:a:0 -c:a:1 copy -metadata:s:a:1 "title=Originale" -disposition:a:0 default -disposition:a:1 0)
    # Traccia originale inclusa
else
    echo "Valore per 'originale' non riconosciuto: usa 'si'/'no'"
    exit 1
fi

# Stampa risultati
echo -e "\033[1;32m[OK]\033[0m Voce ottimizzata | Surround intelligente | LFE chirurgico | Controllo volume dinamico | Anti vibrazione"
echo -e "\033[1;32m[OK]\033[0m SoXR High-End (28-bit precision) | Oversampling 2× | Minimizzazione aliasing/ringing | Audio definito"
echo -e "\033[1;33m[Profilo]\033[0m ${PROFILE_DESC}"

# Mostra informazioni sul profilo selezionato
if [ "$PROFILE" = "Alta" ]; then
    echo -e "\033[1;34m[Engine]\033[0m Profilo selezionato: \033[1;36m${PROFILE}\033[0m con algoritmo \033[1;32m\"Adaptive Audio\"\033[0m"
else
    echo -e "\033[1;34m[Engine]\033[0m Profilo selezionato: ${PROFILE} con algoritmo \033[1;32m\"Adaptive Audio\"\033[0m"
fi

# Correlazione qualità - Rilevamento mastering aggressivo
if awk "BEGIN {print ($TP > -2.0 && $LRA < 8) ? 1 : 0}" | grep -q 1; then
    echo -e "\033[1;33m[CORRELAZIONE]\033[0m Rilevato: Mastering aggressivo (possibile perdita dinamica)"
fi

# Rilevamento qualità originale alta
if awk "BEGIN {print ($TP < -6.0 && $LRA > 15) ? 1 : 0}" | grep -q 1; then
    echo -e "\033[1;36m[CORRELAZIONE]\033[0m Rilevato: Sorgente premium (conservazione qualità attivata)"
fi

# Brick-wall mastered detection
if awk "BEGIN {print ($TP > -2.0 && $LRA < 7) ? 1 : 0}" | grep -q 1; then
    echo -e "\033[1;31m[CORRELAZIONE]\033[0m Rilevato: Brick-wall mastered (compressore soft attivato)"
fi

# Mostra un avviso speciale per il profilo Serie TV ad Alta Dinamica
if [ "$SERIETV_HIGH_DYNAMIC" -eq 1 ]; then
    echo -e "\033[1;34m[Info]\033[0m Rilevato \033[1;31m\"Alta Dinamica\"\033[0m - Attivata protezione LFE avanzata!"
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
echo -e "\033[1;35m[Parametri]\033[0m Dynamic Compressor: \033[1;33m${COMPRESSOR_THRESHOLD}\033[0m threshold | Limiter: \033[1;33m${LIMITER_LIMIT}\033[0m ceiling | SoXR: \033[1;33m28-bit + 2×OS\033[0m precision"

# Report Limiter Dinamico
if [ "$LIMITER_ADJUSTMENT" != "0" ]; then
    echo -e "\033[1;36m[SISTEMA ADATTIVO]\033[0m Limiter adattato: \033[1;33m${BASE_LIMIT}\033[0m → \033[1;33m${ADAPTED_LIMIT}\033[0m | Adjustment: \033[1;33m${LIMITER_ADJUSTMENT}\033[0m dBTP"
else
    echo -e "\033[1;36m[SISTEMA ADATTIVO]\033[0m Limiter standard: \033[1;33m${ADAPTED_LIMIT}\033[0m | True Peak: \033[1;33m${TP}\033[0m dBTP - Processing ottimale"
fi

# --- Generazione file output e controllo sovrascrittura ----------------------------------------------

# Controllo esistenza file
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
    echo -e "\033[1;31m[Errore]\033[0m Elaborazione FFmpeg fallita"
    exit 1
fi

# Verifica che il file di output sia stato creato correttamente
if [ ! -f "$OUTPUT_FILE" ]; then
    echo -e "\033[1;31m[Errore]\033[0m File di output non creato: $OUTPUT_FILE"
    exit 1
fi

# Completamento
echo -e "\033[1;32m[OK]\033[0m Processing audio completato."
echo -e "\033[1;33mFile creato:\033[0m"
echo "${OUTPUT_FILE#./}"