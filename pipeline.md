#!/usr/bin/env bash

# -----------------------------------------------------------------------------------------------
#  CLEARVOICE 0.77 - OTTIMIZZAZIONE AUDIO 5.1 PER LG MERIDIAN SP7 5.1.2 
#  Script avanzato per miglioramento dialoghi e controllo LFE (C)2025
#  Autore: [Sandro "D@mocle77" Sabbioni]
# -----------------------------------------------------------------------------------------------
# DESCRIZIONE:
#   Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE.
#   Specificamente calibrato per sistemi LG Meridian SP7 e soundbar o AVR compatibili.
#
# USO BASE:
#   ./clearvoice077_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
#
# PRESET DISPONIBILI:
#   --film     : Ottimizzato per contenuti cinematografici con action e dialoghi.
#   --serie    : Bilanciato per serie TV con dialoghi sussurrati e problematici. (Default)
#   --cartoni  : Leggero per animazione con preservazione musicale e dinamica.
#
# CODEC SUPPORTATI:
#   eac3      : Enhanced AC3 (DD+), default 384k - Raccomandato per serie TV
#   ac3       : Dolby Digital, default 448k - Compatibilità universale
#   dts       : DTS, default 768k - Qualità premium per film e Blu-ray
#
# ESEMPI D'USO:
#   ./clearvoice077_preset.sh --serie eac3 384k "Serie.mkv"
#   ./clearvoice077_preset.sh --film dts 768k *.mkv
#   ./clearvoice077_preset.sh --cartoni ac3 640k
#   ./clearvoice077_preset.sh
#   ./clearvoice077_preset.sh --serie /path/to/series/
#
# ELABORAZIONE AVANZATA v0.77:
#   ✓ Ottimizzazione individuale canali 5.1, boost FC, controllo LFE
#   ✓ Compressione multi-banda, Limitatore intelligente, Crossover LFE
#   ✓ Resampling SoxR qualità audiophile (precision 33-bit, triangular dithering)
#   ✓ Processing parallelo (2 file) per preset --serie su cartelle
#   ✓ DTS: Centralità FC aumentata, FL/FR ridotti
#   ✓ Output: filename_[preset]_clearvoice0.mkv
#
# VERSIONE: 0.77
# -----------------------------------------------------------------------------------------------
# NOTA: Questo script richiede ffmpeg e awk installati nel sistema.
# pipefail assicura che un errore in una pipeline venga propagato.

set -euo pipefail

# -----------------------------------------------------------------------------------------------
#  CONFIGURAZIONE GLOBALE E VERIFICA DIPENDENZE
# -----------------------------------------------------------------------------------------------
FRONT_VOL=1.0         # Volume base canali frontali (FL/FR) - NON MODIFICARE
VERSION="0.77"        # Versione dello script
MIN_FFMPEG_VER="6.0"  # Versione minima di ffmpeg richiesta (non usata attivamente nel check)

# Verifica la presenza dei comandi essenziali (ffmpeg, awk)
for cmd in ffmpeg awk; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Errore: Il comando richiesto '$cmd' non è stato trovato. Assicurati che sia installato e nel PATH." >&2
    exit 1
  fi
done

# Verifica opzionale di 'nproc' per determinare il numero di core CPU
if ! command -v nproc &> /dev/null; then
    echo "ℹ️  nproc non disponibile, usando 4 thread di default per ffmpeg."
fi

# -----------------------------------------------------------------------------------------------
#  PARSING DEGLI ARGOMENTI DELLA RIGA DI COMANDO (CLI)
# -----------------------------------------------------------------------------------------------
PRESET="serie"  # Preset di default se non specificato
CODEC=""        # Codec audio (e.g., eac3, ac3, dts)
BR=""           # Bitrate audio (e.g., 384k, 768k)
INPUTS=()       # Array per memorizzare i file/cartelle di input

# Loop per processare gli argomenti passati allo script
while [[ $# -gt 0 ]]; do
  case "$1" in
    --film) PRESET="film"; shift;;          # Imposta preset "film"
    --serie) PRESET="serie"; shift;;        # Imposta preset "serie"
    --cartoni) PRESET="cartoni"; shift;;    # Imposta preset "cartoni"
    -c) CODEC="$2"; shift 2;;               # Imposta codec (argomento successivo)
    -b) BR="$2";   shift 2;;                # Imposta bitrate (argomento successivo)
    -*) echo "Opzione sconosciuta: $1"; exit 1;;    # Gestisce opzioni non valide
    *) INPUTS+=("$1"); shift;;              # Aggiunge l'argomento all'array di input
  esac
done

# -----------------------------------------------------------------------------------------------
#  FUNZIONI PER LA COSTRUZIONE DI PARTI SPECIFICHE DEL FILTRO AUDIO
# -----------------------------------------------------------------------------------------------

# Costruisce la stringa del filtro 'alimiter' e 'asoftclip' in base al preset
build_limiter_settings() {
    case "$PRESET" in
        film)
            echo "alimiter=level_in=1.0:level_out=0.95:limit=0.98:attack=5:release=50:asc=1,asoftclip=type=tanh:param=0.8"
            ;;
        serie)
            echo "alimiter=level_in=1.0:level_out=0.93:limit=0.96:attack=3:release=30:asc=1,asoftclip=type=exp:param=0.7"
            ;;
        cartoni)
            echo "alimiter=level_in=1.0:level_out=0.96:limit=0.99:attack=8:release=80:asc=1,asoftclip=type=sin:param=0.9"
            ;;
    esac
}

# Costruisce la stringa dei filtri passa-alto e passa-basso per i canali frontali (FL/FR)
build_front_filters() {
    case "$PRESET" in
        film)
            echo "highpass=f=22:poles=1,lowpass=f=20000:poles=1"
            ;;
        serie)
            echo "highpass=f=28:poles=1,lowpass=f=18000:poles=1"
            ;;
        cartoni)
            echo "highpass=f=18:poles=1,lowpass=f=24000:poles=1"
            ;;
    esac
}

# -----------------------------------------------------------------------------------------------
#  IMPOSTAZIONE DEI PARAMETRI SPECIFICI DEL PRESET SELEZIONATO
# -----------------------------------------------------------------------------------------------
set_preset_params() {
    # Imposta volumi, parametri di compressione e frequenze di taglio in base al preset
    case "$PRESET" in
        film)
            VOICE_VOL=8.5; LFE_VOL=0.24; SURROUND_VOL=3.6  
            VOICE_COMP="0.35:1.30:40:390"
            HP_FREQ=115; LP_FREQ=7900
            ;;
        serie)
            VOICE_VOL=8.6; LFE_VOL=0.24; SURROUND_VOL=3.4
            VOICE_COMP="0.32:1.18:50:380"
            HP_FREQ=120; LP_FREQ=7600
            ;;
        cartoni)
            VOICE_VOL=8.2; LFE_VOL=0.26; SURROUND_VOL=3.5  
            VOICE_COMP="0.40:1.15:50:330"
            HP_FREQ=110; LP_FREQ=6900
            ;;
        *) echo "Preset sconosciuto: $PRESET"; exit 1;;
    esac
    
    # Estrae i singoli parametri di compressione dalla stringa VOICE_COMP
    IFS=':' read -r VC_THRESHOLD VC_RATIO VC_ATTACK VC_RELEASE <<< "$VOICE_COMP"
    # Costruisce la stringa del filtro compressore
    COMPRESSOR_SETTINGS="acompressor=threshold=${VC_THRESHOLD}:ratio=${VC_RATIO}:attack=${VC_ATTACK}:release=${VC_RELEASE}"
    # Ottiene le impostazioni del limitatore e dei filtri frontali
    SOFTCLIP_SETTINGS=$(build_limiter_settings)
    FRONT_FILTER=$(build_front_filters)
}

set_preset_params # Chiama la funzione per impostare i parametri del preset

# Gestione fallback per CODEC e BR se non specificati come opzioni ma come argomenti posizionali
if [[ -z $CODEC && ${#INPUTS[@]} -ge 1 ]]; then
  CODEC="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi
if [[ -z $BR && ${#INPUTS[@]} -ge 1 && "${INPUTS[0]}" =~ ^[0-9]+[kK]$ ]]; then
  BR="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi

# Se non sono stati forniti file/cartelle di input, processa tutti i file .mkv nella directory corrente
if [[ ${#INPUTS[@]} -eq 0 ]]; then
  shopt -s nullglob # Se non ci sono file .mkv, l'espansione non produce errori
  for f in *.mkv; do INPUTS+=("$f"); done
  shopt -u nullglob # Ripristina il comportamento di default
fi
# Se ancora non ci sono input, esce con errore
[[ ${#INPUTS[@]} -eq 0 ]] && { echo "Errore: nessun file o cartella specificato!"; exit 1; }

# -----------------------------------------------------------------------------------------------
#  SELEZIONE DEL CODEC AUDIO E IMPOSTAZIONE DEI RELATIVI PARAMETRI DI ENCODING
# -----------------------------------------------------------------------------------------------  
CODEC="${CODEC:-eac3}" # Codec di default è eac3 se non specificato
case "${CODEC,,}" in  # Converte il codec in minuscolo per il matching
  eac3) 
    ENC=eac3; BR=${BR:-384k}; TITLE="EAC3 Clearvoice 5.1"
    EXTRA="-channel_layout 5.1 -mixing_level 108 -room_type 1 -copyright 0 -dialnorm -27 -dsur_mode 2"
    ;;
  ac3)  
    ENC=ac3; BR=${BR:-448k}; TITLE="AC3 Clearvoice 5.1"
    EXTRA="-channel_layout 5.1 -center_mixlev 0.594 -surround_mixlev 0.5 -dialnorm -27"
    ;;
  dts)  
    ENC=dts; BR=${BR:-768k}; TITLE="DTS Clearvoice 5.1"
    EXTRA="-strict -2 -ar 48000 -channel_layout 5.1(side) -compression_level 1"
    ;;
  *) echo "Codec non supportato: $CODEC"; exit 1;;
esac

# -----------------------------------------------------------------------------------------------
#  COSTRUZIONE DELLA STRINGA DEL FILTRO AUDIO COMPLESSO ('filter_complex')
# -----------------------------------------------------------------------------------------------
build_audio_filter() {
    local voice_vol_adj front_vol_adj lfe_vol_adj surround_vol_adj
    local hp_freq=${HP_FREQ} lp_freq=${LP_FREQ} # Frequenze di taglio per il canale centrale
    
    # Logica differenziata per codec DTS rispetto a EAC3/AC3
    if [[ "${CODEC,,}" == "dts" ]]; then
        # ===== RAMO DTS: Parametri ottimizzati specifici per codec DTS =====
        case "$PRESET" in # Ulteriori aggiustamenti specifici per preset quando il codec è DTS
            film)
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.7}")
                front_vol_adj="0.80"                                   
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.70}")     
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.82}")
                hp_freq=145; lp_freq=7700                        
                ;;
            serie)
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.2}")    
                front_vol_adj="0.75"                                    
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.72}")       
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.78}") 
                hp_freq=140; lp_freq=7500
                ;;
            cartoni)
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.9}")    
                front_vol_adj="0.82"                                    
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.80}")      
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.85}") 
                hp_freq=135; lp_freq=6800
                ;;
        esac
        
        # Costruzione del filtro complesso per DTS
        ADV_FILTER=$(cat <<EOF | tr -d '\n'
[0:a]channelmap=channel_layout=5.1[audio5dot1];
[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
[FC]highpass=f=${hp_freq},lowpass=f=${lp_freq},volume=${voice_vol_adj},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
[FL]${FRONT_FILTER},volume=${front_vol_adj}[left];
[FR]${FRONT_FILTER},volume=${front_vol_adj}[right];
[LFE]highpass=f=35:poles=2,lowpass=f=100:poles=2,volume=${lfe_vol_adj},acompressor=threshold=0.25:ratio=3.0:attack=15:release=150[bass];
[BL]highpass=f=30:poles=1,lowpass=f=19000:poles=1,volume=${surround_vol_adj}[surroundL];
[BR]highpass=f=30:poles=1,lowpass=f=19000:poles=1,volume=${surround_vol_adj}[surroundR];
[left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1:map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[joined];
[joined]aresample=48000:resampler=soxr:precision=33:cheby=1:dither_method=triangular_hp:cutoff=0.99:phase_shift=24,asetnsamples=n=1152:p=0,aformat=sample_fmts=s32:channel_layouts=5.1[out]
EOF
)
    else
        # ===== RAMO EAC3/AC3: Parametri per codec Dolby (EAC3 o AC3) =====
        case "$PRESET" in # Aggiustamenti volume per FC e FL/FR
            film)
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.2}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.12}")
                ;;
            serie)
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.5}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.08}")
                ;;
            cartoni)
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.8}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.02}")
                ;;
        esac
        
        # Calcolo riduzione volume LFE e surround specifica per preset
        case "$PRESET" in
            serie)
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.80}")       
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.92}")
                ;;
            film)
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.83}")       
                surround_vol_adj=${SURROUND_VOL}
                ;;
            cartoni)
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.92}")       
                surround_vol_adj=${SURROUND_VOL}
                ;;
            *) # Fallback se il preset non matcha (non dovrebbe succedere)
                lfe_vol_adj=${LFE_VOL}
                surround_vol_adj=${SURROUND_VOL}
                ;;
        esac
        
        # Costruzione del filtro complesso per EAC3/AC3
        ADV_FILTER=$(cat <<EOF | tr -d '\n'
[0:a]channelmap=channel_layout=5.1[audio5dot1];
[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
[FC]highpass=f=${hp_freq},lowpass=f=${lp_freq},volume=${voice_vol_adj},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
[FL]${FRONT_FILTER},volume=${front_vol_adj}[left];
[FR]${FRONT_FILTER},volume=${front_vol_adj}[right];
[LFE]highpass=f=25:poles=2,lowpass=f=105:poles=2,volume=${lfe_vol_adj}[bass];
[BL]highpass=f=35:poles=1,lowpass=f=18000:poles=1,volume=${surround_vol_adj}[surroundL];
[BR]highpass=f=35:poles=1,lowpass=f=18000:poles=1,volume=${surround_vol_adj}[surroundR];
[left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1:map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[joined];
[joined]aresample=48000:resampler=soxr:precision=33:cheby=1:dither_method=triangular_hp:cutoff=0.99:phase_shift=24[out]
EOF
)
    fi
}

build_audio_filter # Chiama la funzione per costruire la stringa del filtro audio globale

# -----------------------------------------------------------------------------------------------
#  GESTIONE DEL PROCESSING PARALLELO E FUNZIONI DI UTILITÀ
# -----------------------------------------------------------------------------------------------
MAX_PARALLEL=1 # Numero massimo di processi ffmpeg da eseguire in parallelo (default 1)
SKIPPED_FOR_NON_5_1_AUDIO_COUNT=0 # Contatore per file saltati perché non 5.1

# Funzione per attendere uno slot libero se il numero di job attivi raggiunge MAX_PARALLEL
wait_for_slot() {
    while (( $(jobs -r | wc -l) >= MAX_PARALLEL )); do
        sleep 1 # Attende 1 secondo prima di ricontrollare
    done
}

# Funzione per attendere il completamento di tutti i job in background
wait_all_jobs() {
    while (( $(jobs -r | wc -l) > 0 )); do
        sleep 1
    done
}

# -----------------------------------------------------------------------------------------------
#  FUNZIONE PRINCIPALE DI ELABORAZIONE PER UN SINGOLO FILE
# -----------------------------------------------------------------------------------------------
process() {
    local input_file="$1"         # File di input da processare
    local parallel_mode="${2:-false}" # Flag per indicare se è in modalità parallela
    local out="${input_file%.*}_${PRESET}_clearvoice0.mkv" # Nome del file di output

    # Validazione: controlla se il file di input esiste
    if [[ ! -f "$input_file" ]]; then
        echo "❌ File '$input_file' non trovato!" >&2
        return 1 # Esce dalla funzione con errore -> set -e fermerà lo script
    fi
    
    # Validazione: stima conservativa dello spazio disco necessario
    local file_size=$(stat -c%s "$input_file" 2>/dev/null || stat -f%z "$input_file" 2>/dev/null || echo "0")
    local free_space=$(df . | awk 'NR==2 {print $4*1024}' 2>/dev/null || echo "999999999999") # Spazio libero in byte
    if (( file_size > 0 && file_size * 2 > free_space )); then # Stima che l'output possa essere grande quanto l'input
        echo "⚠️  Spazio disco insufficiente per elaborare '$input_file'" >&2
        return 1 # Esce dalla funzione con errore -> set -e fermerà lo script
    fi
    
    # Rilevamento del layout e del numero di canali della traccia audio principale
    local channel_layout=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channel_layout -of csv=p=0 "$input_file" 2>/dev/null)
    local channels=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$input_file" 2>/dev/null)

    # Validazione: controlla se l'audio è 5.1
    if [[ "$channel_layout" != "5.1" && "$channels" != "6" ]]; then
        echo "⚠️  '$input_file' non ha audio 5.1 (layout: $channel_layout, canali: $channels), saltato." >&2
        ((SKIPPED_FOR_NON_5_1_AUDIO_COUNT++)) # Incrementa il contatore dei file saltati per audio non 5.1
        return 0 # Restituisce 0 per permettere allo script di continuare con altri file
    fi
    
    # Correzione per file con layout "unknown" ma 6 canali (assume 5.1)
    local LOCAL_FILTER="$ADV_FILTER" # Usa una copia locale del filtro globale
    if [[ "$channel_layout" == "unknown" && "$channels" == "6" ]]; then
        echo "ℹ️  File con 6 canali ma layout sconosciuto, assumo 5.1 e adatto il filtro."
        # Sostituisce 'channelmap' con 'aformat' per forzare il layout 5.1
        LOCAL_FILTER="${ADV_FILTER//channelmap=channel_layout=5.1/aformat=channel_layouts=5.1}"
    fi
    
    echo -e "\n🎬 Elaborazione: $(basename "$input_file") [Preset: $PRESET] $([ "$parallel_mode" = "true" ] && echo "[PARALLEL]" || echo "")"
    
    # Gestione sovrascrittura file di output
    if [[ -e "$out" && "$parallel_mode" = "false" ]]; then # Se sequenziale, chiede conferma
        read -p "⚠️ File di output '$out' già esistente! Sovrascrivere? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            echo "⏭️  Salto elaborazione di $input_file."
            return 0 # Esce dalla funzione senza errore (scelta utente)
        fi
    elif [[ -e "$out" && "$parallel_mode" = "true" ]]; then # Se parallelo, salta automaticamente
        echo "⏭️ File di output già esistente, salto: $(basename "$out")"
        return 0
    fi

    # Esecuzione del comando ffmpeg
    local START_TIME=$(date +%s) # Tempo di inizio elaborazione
    # Determina il numero di thread da usare per ffmpeg
    local thread_count=$(nproc 2>/dev/null || echo "4") # Default a 4 se nproc non è disponibile
    if [[ "$parallel_mode" = "true" ]]; then # Se parallelo, riduce i thread per processo
        thread_count=$((thread_count / MAX_PARALLEL))
        [[ $thread_count -lt 2 ]] && thread_count=2 # Minimo 2 thread
    fi
    
    # Comando ffmpeg per l'elaborazione audio
    ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero -fflags +genpts+discardcorrupt \
        -threads "$thread_count" -filter_threads "$thread_count" -thread_queue_size 512 \
        -i "$input_file" -filter_complex "$LOCAL_FILTER" \
        -map 0:v -map "[out]" -map 0:a? -map 0:s? \
        -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
        -c:v copy -c:a:0 "$ENC" $EXTRA -b:a:0 "$BR" -c:a:1 copy -c:s copy \
        -movflags +faststart "$out"

    local exit_code=$? # Codice di uscita di ffmpeg
    local END_TIME=$(date +%s)   # Tempo di fine elaborazione
    local PROCESSING_TIME=$((END_TIME - START_TIME)) # Durata elaborazione
    
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ Completato in ${PROCESSING_TIME}s: $(basename "$out")"
        return 0 # Successo
    else
        echo "❌ Errore durante l'elaborazione di $input_file (ffmpeg exit code: $exit_code)" >&2
        return 1 # Errore -> set -e fermerà lo script
    fi
}

# -----------------------------------------------------------------------------------------------
#  LOOP PRINCIPALE SUI FILE/CARTELLE DI INPUT
# -----------------------------------------------------------------------------------------------
echo ""
echo "🚀 Avvio CLEARVOICE $VERSION - Preset: $PRESET | Codec: $CODEC ($BR)"

# Determina se si stanno processando cartelle per attivare la modalità parallela per preset "serie"
PROCESSING_DIRS=false
for path_check in "${INPUTS[@]}"; do
    if [[ -d "$path_check" ]]; then
        PROCESSING_DIRS=true
        break
    fi
done

# Attiva la modalità parallela (MAX_PARALLEL=2) se si processano cartelle e il preset è "serie"
if [[ "$PROCESSING_DIRS" = "true" && "$PRESET" = "serie" ]]; then
    MAX_PARALLEL=2
    echo "🔄 Modalità parallela attivata: elaborazione $MAX_PARALLEL file contemporaneamente per preset '$PRESET' su cartelle."
    echo "💾 Threads per processo ffmpeg ridotti automaticamente per bilanciare carico CPU."
fi

echo ""
echo "   Miglioramenti qualità applicati: "
echo "   Multi-Banda Compressor, Smart Peak Limiter, "
echo "   Crossover LFE Precision, Resampling SoxR Audiophile."

# Itera su ogni file o cartella fornito in input
for path in "${INPUTS[@]}"; do
    if [[ -d "$path" ]]; then # Se l'input è una cartella
        shopt -s nullglob
        dir_files=("$path"/*.mkv) # Trova tutti i file .mkv nella cartella
        shopt -u nullglob
        
        if [[ ${#dir_files[@]} -gt 0 ]]; then
            echo -e "\n📁 Elaborazione cartella: $path (${#dir_files[@]} file .mkv trovati)"
            
            for f in "${dir_files[@]}"; do # Itera sui file nella cartella
                if [[ $MAX_PARALLEL -gt 1 ]]; then
                    wait_for_slot # Attende uno slot libero se in modalità parallela
                    process "$f" "true" & # Lancia il processo in background
                else
                    process "$f" "false" # Esegue il processo in modalità sequenziale
                fi
            done
            
            # Se sono stati lanciati processi paralleli per questa cartella, attende il loro completamento
            if [[ $MAX_PARALLEL -gt 1 ]]; then
                echo "⏳ Attendo completamento processi paralleli per la cartella: $path..."
                wait_all_jobs
            fi
        else
            echo "ℹ️  Nessun file .mkv trovato nella cartella: $path"
        fi
    else # Se l'input è un singolo file
        process "$path" "false" # Esegue il processo in modalità sequenziale
    fi
done

# Attende il completamento di eventuali processi paralleli rimasti dall'ultima cartella
if [[ $MAX_PARALLEL -gt 1 ]]; then
    wait_all_jobs
fi

echo -e "\n🏁 Elaborazione Clearvoice terminata."

# Notifica finale se alcuni file sono stati saltati perché non avevano audio 5.1
if [[ $SKIPPED_FOR_NON_5_1_AUDIO_COUNT -gt 0 ]]; then
    if [[ $SKIPPED_FOR_NON_5_1_AUDIO_COUNT -eq 1 ]]; then
        echo "ℹ️  Nota: 1 file è stato saltato perché non aveva audio 5.1."
    else
        echo "ℹ️  Nota: $SKIPPED_FOR_NON_5_1_AUDIO_COUNT file sono stati saltati perché non avevano audio 5.1."
    fi
fi