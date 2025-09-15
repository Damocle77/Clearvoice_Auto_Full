#!/bin/bash
# ====================================================================================================
# ClearVoice Final V8 - Smart Profile Edition  
# ====================================================================================================
# Developed by Sandro Sabbioni (Audio Processing Engineer)
# ====================================================================================================
# Pipeline avanzata per chiarezza voci e bassi LFE in audio 5.1 mkv/mp4.
# Analisi loudness multi-segmento (LUFS/LRA/TruePeak), selezione profili intelligente a punteggio,
# equalizzazione adattiva e compressione anti-vibrazione. LFE chirurgico, bassi definiti, 
# voci cristalline e transizioni naturali.
#
# CARATTERISTICHE PRINCIPALI:
# - Sistema a punteggio intelligente per selezione profili automatica basata su analisi audio
# - Analisi multi-segmento con fallback robusti e gestione errori avanzata
# - Validazione completa parametri input (codec, bitrate, file) con messaggi dettagliati
# - Anti-vibrazione voce: compressore ratio 2.0, knee 7, attack 20–22ms, release 200ms
# - LFE chirurgico: boost selettivo su 80Hz con controllo dinamico per ogni profilo
# - SoXR 28-bit + oversampling 2×: massima precisione, zero aliasing, definizione HD
# - Compatibilità cross-platform (Linux, macOS, BSD) con gestione errori robusta
#
# ALGORITMO SELEZIONE PROFILI:
# Ogni profilo riceve un punteggio (0-6) basato su parametri audio specifici:
# - Blockbuster: LRA > 10.0, TruePeak > -2.5, LUFS ≤ -17.5 (alta dinamica cinematografica)
# - Action:      LRA 8.0-10.0, TruePeak -3.5/-2.5, LUFS -18.5/-15.5 (dinamica equilibrata)
# - Cartoon:     LRA < 7.5, TruePeak ≤ -2.5, LUFS > -16.5 (compresso, voci brillanti)
# - Serie TV:    LRA 6.5-8.0, TruePeak -4.5/-2.0, LUFS -20.0/-16.5 (standard broadcast)
#   └─ Alta Dinamica: LRA ≥ 7.5, TruePeak > -2.5, LUFS ≤ -17.5 (Netflix/Amazon premium)
#
# UTILIZZO:
#   ./clearvoice_simple.sh "video.mkv" [bitrate] [originale] [codec]
#   1. nome_file.mkv   - File video di input (MKV/MP4 con audio 5.1)
#   2. bitrate         - Bitrate audio: 128k-1024k (default: 768k)
#   3. originale       - "si"/"no" per includere traccia originale (default: si)
#                        Accetta: si/no, s/n, yes/no, y/n, true/false
#   4. codec           - Codec audio: eac3/ac3 (default: eac3)
#
# ESEMPI:
#   ./clearvoice_simple.sh "film.mkv"                    # Usa tutti i default
#   ./clearvoice_simple.sh "serie.mkv" 640k no ac3       # Custom tutto
#   ./clearvoice_simple.sh "anime.mkv" 512k si           # Mantiene codec default
#
# CALIBRAZIONE PARAMETRI FINALI (LFE ottimizzato Q-factor 80Hz + EQ Voice chirurgico):
# • Blockbuster:     Front 0.98 | FC 90Hz/2.35/2.0dB@1350 | LFE 55+75+80Hz/0.24/3.6dB | Surr 2.00 | Comp 2.0/22/200/K7
# • Action:          Front 0.99 | FC 88Hz/2.33/1.9dB@1350 | LFE 55+75+80Hz/0.26/3.6dB | Surr 2.05 | Comp 2.0/22/200/K7  
# • Serie TV (BD):   Front 1.00 | FC 95Hz/2.33/1.8dB@1350 | LFE 55+75+80Hz/0.26/3.6dB | Surr 1.95 | Comp 2.0/20/200/K7 
# • Serie TV (AD):   Front 0.98 | FC 92Hz/2.35/1.8dB@1350 | LFE 55+75+80Hz/0.24/3.6dB | Surr 2.00 | Comp 2.0/22/200/K7  
# • Cartoon:         Front 1.00 | FC 92Hz/2.32/1.9dB@1350 | LFE 55+75+80Hz/0.26/3.6dB | Surr 1.90 | Comp 2.0/20/200/K7
#
# EQUALIZZAZIONE VOCE (FC) - Profilo multi-banda per intelligibilità:
# • Highpass adattivo: 88-95Hz per rimozione mud/rumble (varia per profilo dinamico)
# • EQ 500Hz: -0.3dB taglio boxy/nasale (Q=0.8 preciso)
# • EQ 1350Hz: +1.8/+2.0dB boost presenza/chiarezza (core ClearVoice, Q=0.7 musicale)
# • EQ 2900Hz: +1.0dB definizione consonanti (Q=0.8 controllo sibilanza)  
# • EQ 4800Hz: +0.1dB brillantezza conservativa (Q=0.6 naturale)
# • Compressore anti-vibrazione: ratio 2.0, attack 20-22ms, knee 7.0 smooth
#
# OUTPUT:
#   Crea "nome_file_clearvoice_simple.mkv" nella stessa directory del file di input.
#   Include traccia ClearVoice ottimizzata e opzionalmente traccia originale.
#   Metadati automatici con lingua e informazioni codec.
#
# REQUISITI:
#   - ffmpeg/ffprobe installati e funzionanti
#   - Audio di input: 5.1 canali (6 canali totali)
#   - Spazio disco: ~30% della dimensione originale (per traccia aggiuntiva)
#   - RAM: ~500MB per analisi multi-segmento
#
# ====================================================================================================
# GUIDA BITRATE CLEARVOICE - Raccomandazioni ottimizzate
# ====================================================================================================
# Codec supportati: eac3 (raccomandato), ac3 (compatibilità).
# Range validato: 128k - 1024k (con controllo automatico e correzione)
#
# E-AC-3 (Dolby Digital Plus - migliore qualità):
#   Audio sorgente → ClearVoice raccomandato
#   256k → 448k | 384k → 576k | 512k → 704k | 640k+ → 768k (optimal)
#
# AC-3 (Dolby Digital - massima compatibilità):  
#   256k → 512k | 384k → 576k | 512k+ → 640k (limite hardware standard)
#
# RATIONALE: L'incremento compensa perdite da reprocessing lossy-to-lossy,
# artefatti di codifica multipla, headroom per transitori vocali intensi e
# spazio aggiuntivo per dettagli EQ recuperati dall'elaborazione ClearVoice.
# ====================================================================================================
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

    # Calcolo delle medie con protezione robusta
    if [ "$LUFS_COUNT" -eq 0 ]; then 
        LUFS=-18.0  # Valore realistico invece di -20
        echo -e "\033[1;33m[Warning]\033[0m Nessun valore LUFS valido rilevato, usando default: $LUFS"
    else 
        LUFS=$(awk "BEGIN {printf \"%.1f\", $LUFS_SUM/$LUFS_COUNT}")
    fi
    # Calcolo LRA
    if [ "$LRA_COUNT" -eq 0 ]; then 
        LRA=8.0  # Valore realistico invece di 10
        echo -e "\033[1;33m[Warning]\033[0m Nessun valore LRA valido rilevato, usando default: $LRA"
    else 
        LRA=$(awk "BEGIN {printf \"%.1f\", $LRA_SUM/$LRA_COUNT}")
    fi
    # Calcolo True Peak
    if [ "$TP_COUNT" -eq 0 ]; then 
        TP=-3.0  # Valore realistico invece di -5
        echo -e "\033[1;33m[Warning]\033[0m Nessun valore True Peak valido rilevato, usando default: $TP"
    else 
        # Calcolo media True Peak
        TP=$(awk "BEGIN {printf \"%.1f\", $TP_SUM/$TP_COUNT}")
    fi

# Stampa risultati
echo -e "\033[1;35m[Info]\033[0m Loudnorm multi-analisi: LUFS=\033[1;33m$LUFS\033[0m | LRA=\033[1;33m$LRA\033[0m | TruPeak=\033[1;33m$TP\033[0m dBTP"

# --- Logica Adattiva e Definizione Filtri per Profilo -------------------------------------------

# Calcolo punteggio per ogni profilo basato su caratteristiche audio
BLOCKBUSTER_SCORE=0
ACTION_SCORE=0
CARTOON_SCORE=0
SERIETV_SCORE=0

# BLOCKBUSTER: Alta dinamica + picchi elevati + range ampio
if (( $(awk "BEGIN {print ($LRA > 10.0) ? 1 : 0}") )); then BLOCKBUSTER_SCORE=$((BLOCKBUSTER_SCORE + 3)); fi
if (( $(awk "BEGIN {print ($TP > -2.5) ? 1 : 0}") )); then BLOCKBUSTER_SCORE=$((BLOCKBUSTER_SCORE + 2)); fi
if (( $(awk "BEGIN {print ($LUFS <= -17.5) ? 1 : 0}") )); then BLOCKBUSTER_SCORE=$((BLOCKBUSTER_SCORE + 1)); fi

# ACTION: Dinamica media-alta + loudness moderato + picchi medi
if (( $(awk "BEGIN {print ($LRA >= 8.0 && $LRA <= 10.0) ? 1 : 0}") )); then ACTION_SCORE=$((ACTION_SCORE + 3)); fi
if (( $(awk "BEGIN {print ($LUFS >= -18.5 && $LUFS <= -15.5) ? 1 : 0}") )); then ACTION_SCORE=$((ACTION_SCORE + 2)); fi
if (( $(awk "BEGIN {print ($TP >= -3.5 && $TP <= -2.5) ? 1 : 0}") )); then ACTION_SCORE=$((ACTION_SCORE + 1)); fi

# CARTOON: Loudness alto + dinamica bassa + picchi controllati
if (( $(awk "BEGIN {print ($LUFS > -16.5) ? 1 : 0}") )); then CARTOON_SCORE=$((CARTOON_SCORE + 3)); fi
if (( $(awk "BEGIN {print ($LRA < 7.5) ? 1 : 0}") )); then CARTOON_SCORE=$((CARTOON_SCORE + 2)); fi
if (( $(awk "BEGIN {print ($TP <= -2.5) ? 1 : 0}") )); then CARTOON_SCORE=$((CARTOON_SCORE + 1)); fi

# SERIE TV: Parametri intermedi e bilanciati (zona specifica)
if (( $(awk "BEGIN {print ($LRA >= 6.5 && $LRA < 8.0) ? 1 : 0}") )); then SERIETV_SCORE=$((SERIETV_SCORE + 2)); fi
if (( $(awk "BEGIN {print ($LUFS >= -20.0 && $LUFS <= -16.5) ? 1 : 0}") )); then SERIETV_SCORE=$((SERIETV_SCORE + 2)); fi
if (( $(awk "BEGIN {print ($TP >= -4.5 && $TP <= -2.0) ? 1 : 0}") )); then SERIETV_SCORE=$((SERIETV_SCORE + 1)); fi

# Selezione profilo basata sul punteggio più alto con priorità in caso di parità
MAX_SCORE=$(printf '%s\n' "$BLOCKBUSTER_SCORE" "$ACTION_SCORE" "$CARTOON_SCORE" "$SERIETV_SCORE" | sort -nr | head -1)

# Gestione priorità in caso di punteggi uguali: Blockbuster > Action > Cartoon > SerieTV
if [ "$BLOCKBUSTER_SCORE" -eq "$MAX_SCORE" ] && [ "$MAX_SCORE" -gt 0 ]; then
    PROFILE="Blockbuster"
    SERIETV_HIGH_DYNAMIC=0
elif [ "$ACTION_SCORE" -eq "$MAX_SCORE" ] && [ "$MAX_SCORE" -gt 0 ]; then
    PROFILE="Action"
    SERIETV_HIGH_DYNAMIC=0
elif [ "$CARTOON_SCORE" -eq "$MAX_SCORE" ] && [ "$MAX_SCORE" -gt 0 ]; then
    PROFILE="Cartoon"
    SERIETV_HIGH_DYNAMIC=0
elif [ "$SERIETV_SCORE" -eq "$MAX_SCORE" ] && [ "$MAX_SCORE" -gt 0 ]; then
    PROFILE="SerieTV"
    # Rilevamento Serie TV ad alta dinamica (parametri più precisi e coerenti)
    if (( $(awk "BEGIN {print ($LRA >= 7.5 && $TP > -2.5 && $LUFS <= -17.5) ? 1 : 0}") )); then
        SERIETV_HIGH_DYNAMIC=1
    else
        SERIETV_HIGH_DYNAMIC=0
    fi
else
    # Fallback: nessun profilo ha punteggio > 0
    PROFILE="SerieTV"
    SERIETV_HIGH_DYNAMIC=0
    echo -e "\033[1;33m[Warning]\033[0m Nessun profilo con punteggio valido, usando fallback: Serie TV"
fi

# Debug: mostra punteggi per troubleshooting (rimovibile in produzione)
echo -e "\033[1;90m[Debug]\033[0m Punteggi profili - Blockbuster:$BLOCKBUSTER_SCORE | Action:$ACTION_SCORE | Cartoon:$CARTOON_SCORE | SerieTV:$SERIETV_SCORE"

# Reset variabili di stato dei profili per compatibilità
BLOCKBUSTER_PROFILE=0
ACTION_PROFILE=0
CARTOON_PROFILE=0
SERIETV_PROFILE=0

# Imposta la variabile corretta in base al profilo selezionato
case "$PROFILE" in
    "Blockbuster") BLOCKBUSTER_PROFILE=1 ;;
    "Action")      ACTION_PROFILE=1 ;;
    "Cartoon")     CARTOON_PROFILE=1 ;;
    "SerieTV")     SERIETV_PROFILE=1 ;;
esac

# Selezione profilo specifico in stile "switch-case" - più pulito e diretto
case "$PROFILE" in
    "Blockbuster")
        # PROFILO: Blockbuster/Disaster/Marvel/DC - Massima dinamica e controllo LFE avanzato
        PROFILE_DESC="Blockbuster/Disaster/Marvel/DC/Alta Dinamica"
        EQ_VOICE="[FC]highpass=f=90,equalizer=f=500:w=0.8:g=-0.3,equalizer=f=1350:w=0.7:g=2.0,equalizer=f=2900:w=0.8:g=1.0,equalizer=f=4800:w=0.6:g=0.1,volume=2.35,acompressor=threshold=0.70:ratio=2.0:attack=22:release=200:knee=7:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=3.6,volume=0.24,alimiter=limit=0.60[LFEout];"
        EQ_SURROUND="[SL]volume=2.00[SLout]; [SR]volume=2.00[SRout];"
        ;;
        
    "Action")
        # PROFILO: Action/Horror/Sci-Fi/Musical/Cinecomic - Immersione cinematica equilibrata
        PROFILE_DESC="Action/Horror/Sci-Fi/Musical/Cinecomic"
        EQ_VOICE="[FC]highpass=f=88,equalizer=f=500:w=0.8:g=-0.3,equalizer=f=1350:w=0.7:g=1.9,equalizer=f=2900:w=0.8:g=1.0,equalizer=f=4800:w=0.6:g=0.1,volume=2.33,acompressor=threshold=0.68:ratio=2.0:attack=22:release=200:knee=7:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=3.6,volume=0.26,alimiter=limit=0.60[LFEout];"
        EQ_SURROUND="[SL]volume=2.05[SLout]; [SR]volume=2.05[SRout];"
        ;;
        
    "Cartoon")
        # PROFILO: Cartoon/Disney/Musical/Drammedy/Anime - Voci vivaci per contenuti animati
        PROFILE_DESC="Cartoon/Disney/Musical/Drammedy/Anime"
        EQ_VOICE="[FC]highpass=f=92,equalizer=f=500:w=0.8:g=-0.3,equalizer=f=1350:w=0.7:g=1.9,equalizer=f=2900:w=0.8:g=1.0,equalizer=f=4800:w=0.6:g=0.1,volume=2.32,acompressor=threshold=0.68:ratio=2.0:attack=20:release=200:knee=7:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=3.6,volume=0.26,alimiter=limit=0.60[LFEout];"
        EQ_SURROUND="[SL]volume=1.90[SLout]; [SR]volume=1.90[SRout];"
        ;;
        
    "SerieTV")
        # PROFILO: Amazon/Netflix/Serie TV/Pop/Binge
        if [ "$SERIETV_HIGH_DYNAMIC" -eq 1 ]; then
            # Serie TV moderne ad alta dinamica
            PROFILE_DESC="Amazon/Netflix/Pop/Binge (Alta Dinamica)"
            EQ_VOICE="[FC]highpass=f=92,equalizer=f=500:w=0.8:g=-0.3,equalizer=f=1350:w=0.7:g=1.8,equalizer=f=2900:w=0.8:g=1.0,equalizer=f=4800:w=0.6:g=0.1,volume=2.35,acompressor=threshold=0.70:ratio=2.0:attack=22:release=200:knee=7:detection=rms:link=average[FCout];"
            EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=3.6,volume=0.24,alimiter=limit=0.60[LFEout];"
            EQ_SURROUND="[SL]volume=2.00[SLout]; [SR]volume=2.00[SRout];"
        else
            # Serie TV standard a bassa dinamica
            PROFILE_DESC="Amazon/Netflix/Pop/Binge (Bassa Dinamica)"
            EQ_VOICE="[FC]highpass=f=95,equalizer=f=500:w=0.8:g=-0.3,equalizer=f=1350:w=0.7:g=1.8,equalizer=f=2900:w=0.8:g=1.0,equalizer=f=4800:w=0.6:g=0.1,volume=2.33,acompressor=threshold=0.70:ratio=2.0:attack=20:release=200:knee=7:detection=rms:link=average[FCout];"
            EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=3.6,volume=0.26,alimiter=limit=0.60[LFEout];"
            EQ_SURROUND="[SL]volume=1.95[SLout]; [SR]volume=1.95[SRout];"
        fi
        ;; 
    *)
        # PROFILO FALLBACK: Serie TV standard
        PROFILE_DESC="Serie TV Standard (Fallback)"
        EQ_VOICE="[FC]highpass=f=95,equalizer=f=500:w=0.8:g=-0.3,equalizer=f=1350:w=0.7:g=1.8,equalizer=f=2900:w=0.8:g=1.0,equalizer=f=4800:w=0.6:g=0.1,volume=2.33,acompressor=threshold=0.70:ratio=2.0:attack=20:release=200:knee=7:detection=rms:link=average[FCout];"
        EQ_SUB="[LFE]highpass=f=40,equalizer=f=55:t=q:w=1.8:g=-3.5,equalizer=f=75:t=q:w=1.4:g=-1.0,equalizer=f=80:t=q:w=0.8:g=3.6,volume=0.26,alimiter=limit=0.60[LFEout];"
        EQ_SURROUND="[SL]volume=1.95[SLout]; [SR]volume=1.95[SRout];"
        ;;
esac

# Front Equalizer (per profilo specifico)
if [ "$BLOCKBUSTER_PROFILE" -eq 1 ]; then
    # Blockbuster: Controllo minimo per range estremo
    EQ_FRONT="[FL]volume=0.98[FLout]; [FR]volume=0.98[FRout];"

elif [ "$ACTION_PROFILE" -eq 1 ]; then
    # Action: Leggero calo per evitare vibrazioni
    EQ_FRONT="[FL]volume=0.99[FLout]; [FR]volume=0.99[FRout];"

elif [ "$SERIETV_PROFILE" -eq 1 ]; then
    # Serie TV: Pieno volume per chiarezza voci
    if [ "$SERIETV_HIGH_DYNAMIC" -eq 1 ]; then
        # Serie TV ad Alta Dinamica
        EQ_FRONT="[FL]volume=0.98[FLout]; [FR]volume=0.98[FRout];"  
    else
        # Serie TV standard
        EQ_FRONT="[FL]volume=1.00[FLout]; [FR]volume=1.00[FRout];"  
    fi
      
elif [ "$CARTOON_PROFILE" -eq 1 ]; then
    # Cartoon: Pieno volume per voci brillanti
    EQ_FRONT="[FL]volume=1.00[FLout]; [FR]volume=1.00[FRout];"
else
    # Fallback: Leggero calo per sicurezza
    EQ_FRONT="[FL]volume=0.98[FLout]; [FR]volume=0.98[FRout];"
fi

# Controllo dinamico finale (adattivo per profilo)
if [ "$BLOCKBUSTER_PROFILE" -eq 1 ]; then
    # Blockbuster: Controllo massimo per preservare range dinamico estremo
    FINAL_DYNAMICS="acompressor=threshold=0.76:ratio=2.1:attack=14:release=210:knee=4:detection=rms:link=average,alimiter=limit=0.91:attack=9:release=120:level=disabled:asc=1"

elif [ "$ACTION_PROFILE" -eq 1 ]; then
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
    # Fallback: Controllo standard
    FINAL_DYNAMICS="acompressor=threshold=0.73:ratio=2.2:attack=12:release=160:knee=4:detection=rms:link=average,alimiter=limit=0.88:attack=9:release=120:level=disabled:asc=1"
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
echo -e "\033[1;32m[OK]\033[0m SoXR High-End (28-bit precision) | Oversampling 2× | Minimizzazione aliasing/ringing | Audio ultra-definito HD"
echo -e "\033[1;33m[Profilo]\033[0m ${PROFILE_DESC}"

# Mostra informazioni sul profilo selezionato
echo -e "\033[1;34m[Engine]\033[0m Profilo selezionato: \033[1;36m${PROFILE}\033[0m con algoritmo \033[1;32m\"Adaptive Audio\"\033[0m"

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
echo -e "\033[1;36m[Attendere]\033[0m Elaborazione in corso, potrebbero essere necessari alcuni minuti..."

# Esecuzione ffmpeg con gestione errori migliorata
if ! ffmpeg -y -nostdin -loglevel warning -stats -hide_banner -hwaccel auto -threads 0 \
    -i "$INPUT_FILE" \
    -filter_complex "$FILTER_COMPLEX" \
    -max_muxing_queue_size 1024 \
    -map 0:v -c:v copy \
    "${AUDIO_ARGS[@]}" \
    -map 0:s? -c:s copy \
    -map 0:t? -c:t copy \
    "$OUTPUT_FILE" 2>/dev/null; then
    echo -e "\033[1;31m[Errore]\033[0m Elaborazione FFmpeg fallita"
    exit 1
fi

# Verifica che il file di output sia stato creato correttamente
if [ ! -f "$OUTPUT_FILE" ]; then
    echo -e "\033[1;31m[Errore]\033[0m File di output non creato: $OUTPUT_FILE"
    exit 1
fi

# Verifica che il file di output abbia una dimensione minima (compatibilità cross-platform)
if command -v stat >/dev/null 2>&1; then
    # Prova sintassi BSD prima (macOS), poi GNU (Linux)
    OUTPUT_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "0")
else
    # Fallback usando ls (universale ma meno preciso)
    OUTPUT_SIZE=$(ls -l "$OUTPUT_FILE" 2>/dev/null | awk '{print $5}' || echo "0")
fi

if [ "$OUTPUT_SIZE" -lt 1000000 ]; then  # Minimo 1MB
    echo -e "\033[1;31m[Errore]\033[0m File di output troppo piccolo (${OUTPUT_SIZE} bytes). Elaborazione probabilmente fallita."
    exit 1
fi

# Stampa messaggio di completamento
echo -e "\033[1;32m[OK]\033[0m Il file è pronto, tuning audio completato."
echo -e "\033[1;33mFile creato:\033[0m"
echo "${OUTPUT_FILE#./}"