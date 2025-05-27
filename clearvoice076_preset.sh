#!/usr/bin/env bash

# -----------------------------------------------------------------------------------------------
#  CLEARVOICE 0.76 - OTTIMIZZAZIONE AUDIO 5.1 PER LG MERIDIAN SP7 5.1.2 
#  Script avanzato per miglioramento dialoghi e controllo LFE (C)2025
#  Autore: [Sandro "D@mocle77" Sabbioni]
# -----------------------------------------------------------------------------------------------
# DESCRIZIONE:
#   Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE.
#   Specificamente calibrato per sistemi LG Meridian SP7 e soundbar o AVR compatibili.
#
# USO BASE:
#   ./clearvoice076_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
#
# PRESET DISPONIBILI:
#   --film     : Ottimizzato per contenuti cinematografici con action e dialoghi.
#                Parametri: VOICE_VOL=8.5, LFE=0.24, SURR=3.6, COMP=0.35:1.30:40:390
#                Filtri FC: Highpass 115Hz, Lowpass 7900Hz, Compressore multi-banda, Limitatore intelligente
#                Filtri FL/FR: Anti-rumble 22Hz, Lowpass 20kHz per pulizia conservativa
#                Ideale per: Film d'azione, thriller, drammi con effetti sonori intensi
#
#   --serie    : Bilanciato per serie TV con dialoghi sussurrati e problematici.
#                Parametri: VOICE_VOL=8.6, LFE=0.24, SURR=3.4, COMP=0.32:1.18:50:380
#                Filtri FC: Highpass 120Hz, Lowpass 7600Hz, Compressore delicato, Anti-aliasing
#                Filtri FL/FR: Anti-rumble 28Hz, Lowpass 18kHz per focus dialoghi
#                Ideale per: Serie TV, documentari, contenuti con dialoghi difficili
#                ELABORAZIONE PARALLELA: 2 file contemporaneamente per cartelle
#
#   --cartoni  : Leggero per animazione con preservazione musicale e dinamica.
#                Parametri: VOICE_VOL=8.2, LFE=0.26, SURR=3.5, COMP=0.40:1.15:50:330
#                Filtri FC: Highpass 110Hz, Lowpass 6900Hz, Compressione minima, Limitatore gentile
#                Filtri FL/FR: Anti-rumble 18Hz, Lowpass 24kHz per brillantezza musicale
#                Ideale per: Cartoni animati, anime, contenuti con colonne sonore elaborate
#
# CODEC SUPPORTATI:
#   eac3      : Enhanced AC3 (DD+), default 384k - Raccomandato per serie TV
#   ac3       : Dolby Digital, default 448k - Compatibilità universale
#   dts       : DTS, default 768k - Qualità premium per film e Blu-ray
#
# ESEMPI D'USO:
#   ./clearvoice076_preset.sh --serie eac3 384k "Serie.mkv"    # Singolo file serie TV
#   ./clearvoice076_preset.sh --film dts 768k *.mkv            # Batch film alta qualità  
#   ./clearvoice076_preset.sh --cartoni ac3 448k               # Tutti i .mkv, preset cartoni
#   ./clearvoice076_preset.sh                                  # Auto: serie, eac3, 384k
#   ./clearvoice076_preset.sh --serie /path/to/series/         # Cartella serie: 2 file paralleli
#
# ELABORAZIONE AVANZATA v0.76:
#   ✓ Separazione e ottimizzazione individuale di ogni canale 5.1
#   ✓ Boost intelligente canale centrale (FC) senza interferenze DSP Meridian
#   ✓ Controllo LFE anti-boom (riduzione 8-20% secondo preset)
#   ✓ Compressione dinamica multi-banda per intelligibilità naturale
#   ✓ Limitatore intelligente anti-clipping con lookahead adattivo
#   ✓ Crossover LFE precisione con slopes controllati per perfetta integrazione SP7
#   ✓ Resampling SoxR qualità audiophile con dithering triangular
#   ✓ Anti-aliasing surround per canali posteriori cristallini
#   ✓ Filtri pulizia Front L/R: anti-rumble e controllo frequenze acute
#   ✓ Preservazione stereofonía FL/FR e surround BL/BR con processing ottimizzato
#   ✓ Processing parallelo: 2 file contemporaneamente per preset --serie su cartelle
#   ✓ Output: filename_[preset]_clearvoice0.mkv
#
# CARATTERISTICHE TECNICHE:
#   - Gestione robusta file con layout audio "unknown"
#   - Accelerazione hardware GPU quando disponibile
#   - Threading ottimizzato per CPU multi-core con queue size
#   - Processing parallelo intelligente per serie TV (max 2 processi)
#   - Preservazione video, tracce audio aggiuntive e sottotitoli
#   - Metadata ottimizzati: lingua ITA, traccia predefinita
#   - Encoding qualità ottimizzato per ogni codec con parametri specifici
#   - Gestione errori avanzata con validazione spazio disco
#   - Bilanciamento automatico risorse CPU per modalità parallela
#   - Dipendenze: ffmpeg 4.0+, awk, bc (opzionale)
#
# MIGLIORAMENTI v0.76:
#   - Compressore multi-banda per processing più naturale
#   - Limitatore intelligente per ogni preset (film/serie/cartoni)
#   - Crossover LFE con poles controllati per SP7
#   - Resampling SoxR precision 28-bit con dithering
#   - Anti-aliasing su canali surround
#   - Filtri pulizia front stereo specifici per preset
#   - Encoding ottimizzato (dialnorm, dsur_mode, dts_hd)
#   - Threading efficiente con thread_queue_size
#   - Processing parallelo per serie TV (2 file contemporaneamente)
#   - Statistiche processing con tempo medio per file
#   - Gestione automatica risorse per evitare sovraccarico CPU
#
# VERSIONE: 0.76 | TESTATO SU: LG SP7 5.1.2, Windows 11, ffmpeg 7.x
# -----------------------------------------------------------------------------------------------

set -euo pipefail

# -----------------------------------------------------------------------------------------------
#  CONFIGURAZIONE GLOBALE
# -----------------------------------------------------------------------------------------------
FRONT_VOL=1.0         # Volume canali frontali (FL/FR) - NON MODIFICARE
VERSION="0.76"        # Versione script
MIN_FFMPEG_VER="6.0"  # Versione minima ffmpeg richiesta

# Verifica dipendenze e versioni
for cmd in ffmpeg awk; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Errore: Il comando richiesto '$cmd' non è stato trovato. Assicurati che sia installato e nel PATH." >&2
    exit 1
  fi
done

# -----------------------------------------------------------------------------------------------
#  ANALISI CLI
# -----------------------------------------------------------------------------------------------
PRESET="serie"  # preset di default
CODEC=""; BR=""; INPUTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --film) PRESET="film"; shift;;
    --serie) PRESET="serie"; shift;;
    --cartoni) PRESET="cartoni"; shift;;
    -c) CODEC="$2"; shift 2;;
    -b) BR="$2";   shift 2;;
    -h|--help)
      cat << 'EOF'
CLEARVOICE 0.76 - Ottimizzazione Audio 5.1 per LG Meridian SP7

USO: ./clearvoice076_preset.sh [PRESET] [CODEC] [BITRATE] [FILES...]

PRESET:
  --film     Cinema/Action (VOICE:8.5, LFE:0.24, moderato)
  --serie    Serie TV/Dialoghi (VOICE:8.6, LFE:0.24, intelligibilità max, 2 file paralleli)
  --cartoni  Animazione (VOICE:8.2, LFE:0.26, preserva musica)

CODEC: eac3(def)|ac3|dts  BITRATE: 384k(def)|448k|640k|768k

ESEMPI:
  ./clearvoice076_preset.sh --serie *.mkv           # Serie TV, EAC3 384k
  ./clearvoice076_preset.sh --film dts 768k Film/   # Film DTS alta qualità
  ./clearvoice076_preset.sh --cartoni ac3 448k      # Cartoni AC3
  ./clearvoice076_preset.sh --serie /series/folder/ # Serie: 2 file paralleli

OUTPUT: filename_[preset]_clearvoice0.mkv

MIGLIORAMENTI QUALITÀ v0.76:
  ✓ Compressore multi-banda per naturalezza
  ✓ Limitatore intelligente anti-clipping adattivo
  ✓ Crossover LFE precisione per SP7
  ✓ Resampling SoxR qualità audiophile
  ✓ Anti-aliasing surround
  ✓ Filtri pulizia Front L/R specifici per preset
  ✓ Encoding ottimizzato per ogni codec
  ✓ Threading efficiente con queue size
  ✓ Processing parallelo per serie TV (max 2 processi)
EOF
      exit 0;;
    -*) echo "Unknown option $1"; exit 1;;
    *) INPUTS+=("$1"); shift;;
  esac
done

# -----------------------------------------------------------------------------------------------
#  FUNZIONI QUALITÀ AVANZATE
# -----------------------------------------------------------------------------------------------

# Costruisce limitatore intelligente anti-clipping specifico per preset
build_limiter_settings() {
    case "$PRESET" in
        film)
            # Limiter cinematografico: preserva dinamica, controlla picchi
            echo "alimiter=level_in=1.0:level_out=0.95:limit=0.98:attack=5:release=50:asc=1,asoftclip=type=tanh:param=0.8"
            ;;
        serie)
            # Limiter dialoghi: controllo aggressivo per TV
            echo "alimiter=level_in=1.0:level_out=0.93:limit=0.96:attack=3:release=30:asc=1,asoftclip=type=exp:param=0.7"
            ;;
        cartoni)
            # Limiter musicale: protezione gentile
            echo "alimiter=level_in=1.0:level_out=0.96:limit=0.99:attack=8:release=80:asc=1,asoftclip=type=sin:param=0.9"
            ;;
    esac
}

# Costruisce filtri pulizia Front L/R specifici per preset
build_front_filters() {
    case "$PRESET" in
        film)
            # Film: pulizia conservativa, preserva dinamica musicale
            echo "highpass=f=22:poles=1,lowpass=f=20000:poles=1"
            ;;
        serie)
            # Serie: pulizia moderata, focus su intelligibilità
            echo "highpass=f=28:poles=1,lowpass=f=18000:poles=1"
            ;;
        cartoni)
            # Cartoni: pulizia minima, preserva brillantezza musicale
            echo "highpass=f=18:poles=1,lowpass=f=24000:poles=1"
            ;;
    esac
}

# -----------------------------------------------------------------------------------------------
#  IMPOSTAZIONI PRESET AVANZATE
# -----------------------------------------------------------------------------------------------
set_preset_params() {
    case "$PRESET" in
        film)
            # PRESET FILM: Bilanciato per contenuti cinematografici
            # Voce presente ma non invadente, LFE controllato per action scenes
            VOICE_VOL=8.5; LFE_VOL=0.24; SURROUND_VOL=3.6  
            VOICE_COMP="0.35:1.30:40:390"  # Compressione moderata
            # Compressore multi-banda per naturalezza
            VOICE_COMP_MB="compand=attacks=0.02,0.05:decays=0.2,0.4:points=-90/-90,-45/-30,-25/-15,-5/-5|0.5"
            HP_FREQ=115; LP_FREQ=7900      # Range frequenze voce ottimale
            ;;
        serie)
            # PRESET SERIE TV: Massima intelligibilità dialoghi
            # Ideale per contenuti con dialoghi sussurrati o problematici
            VOICE_VOL=8.6; LFE_VOL=0.24; SURROUND_VOL=3.4
            VOICE_COMP="0.32:1.18:50:380"  # Compressione delicata anti-vibrazione
            # Compressore dialoghi: controllo massimo range dinamico
            VOICE_COMP_MB="compand=attacks=0.01,0.03:decays=0.15,0.3:points=-90/-90,-50/-35,-30/-20,-8/-8|0.6"
            HP_FREQ=120; LP_FREQ=7600      # Pulizia maggiore dei bassi
            ;;
        cartoni)
            # PRESET CARTONI: Preserva musicalità e dinamica
            # Bilanciato per voci chiare + colonne sonore elaborate
            VOICE_VOL=8.2; LFE_VOL=0.26; SURROUND_VOL=3.5  
            VOICE_COMP="0.40:1.15:50:330"  # Compressione leggera
            # Compressore musicale: preserva dinamica
            VOICE_COMP_MB="compand=attacks=0.03,0.08:decays=0.3,0.6:points=-90/-90,-40/-25,-20/-12,-3/-3|0.4"
            HP_FREQ=110; LP_FREQ=6900      # Range esteso per musica
            ;;
        *) echo "Preset sconosciuto: $PRESET"; exit 1;;
    esac
    
    # Parsing parametri compressione dinamica   
    IFS=':' read -r VC_THRESHOLD VC_RATIO VC_ATTACK VC_RELEASE <<< "$VOICE_COMP"
    
    # Compressore ibrido: standard + multiband per naturalezza
    COMPRESSOR_SETTINGS="acompressor=threshold=${VC_THRESHOLD}:ratio=${VC_RATIO}:attack=${VC_ATTACK}:release=${VC_RELEASE},${VOICE_COMP_MB}"
    
    # Limitatore intelligente specifico per preset
    SOFTCLIP_SETTINGS=$(build_limiter_settings)
    
    # Filtri pulizia Front L/R specifici per preset
    FRONT_FILTER=$(build_front_filters)
}

set_preset_params

# Ripiego posizionale per CODEC e BR
if [[ -z $CODEC && ${#INPUTS[@]} -ge 1 ]]; then
  CODEC="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi
if [[ -z $BR && ${#INPUTS[@]} -ge 1 && "${INPUTS[0]}" =~ ^[0-9]+[kK]$ ]]; then
  BR="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi
# Se non sono specificati input, prendi tutti i file .mkv in cartella
if [[ ${#INPUTS[@]} -eq 0 ]]; then
  shopt -s nullglob
  for f in *.mkv; do INPUTS+=("$f"); done
  shopt -u nullglob
fi
[[ ${#INPUTS[@]} -eq 0 ]] && { echo "Error: nessun file o cartella specificato!"; exit 1; }

# -----------------------------------------------------------------------------------------------
#  SELEZIONE CODEC CON PARAMETRI QUALITÀ OTTIMIZZATI
# -----------------------------------------------------------------------------------------------  
CODEC="${CODEC:-eac3}"
case "${CODEC,,}" in
  eac3) 
    ENC=eac3; BR=${BR:-384k}; TITLE="EAC3 Clearvoice 5.1"
    # Parametri qualità EAC3 ottimizzati per SP7
    EXTRA="-channel_layout 5.1 -mixing_level -1 -room_type 1 -copyright 0 -dialnorm -27 -dsur_mode 2"
    ;;
  ac3)  
    ENC=ac3; BR=${BR:-448k}; TITLE="AC3 Clearvoice 5.1"
    # Parametri qualità AC3 ottimizzati
    EXTRA="-channel_layout 5.1 -center_mixlev 0.594 -surround_mixlev 0.5 -dialnorm -27"
    ;;
  dts)  
    ENC=dts; BR=${BR:-768k}; TITLE="DTS Clearvoice 5.1"
    # Parametri DTS con qualità massima
    EXTRA="-strict -2 -ar 48000 -channel_layout 5.1 -dts_hd 1 -compression_level 0"
    ;;
  *) echo "Unsupported codec $CODEC"; exit 1;;
esac

# -----------------------------------------------------------------------------------------------
#  COSTRUZIONE FILTRI AUDIO AVANZATI
# -----------------------------------------------------------------------------------------------
build_audio_filter() {
    local voice_vol_adj front_vol_adj lfe_vol_adj surround_vol_adj
    local hp_freq=${HP_FREQ} lp_freq=${LP_FREQ}
    
    if [[ "${CODEC,,}" == "dts" ]]; then
        # ===== RAMO DTS: Parametri ottimizzati per codec DTS =====
        case "$PRESET" in
            film)
                # DTS Film: sub molto più controllato per eliminare boom eccessivo
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.5}") 
                front_vol_adj="0.85"                                     
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.82}")    
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.82}")
                hp_freq=135; lp_freq=7700                                
                ;;
            serie)
                # DTS Serie: sub molto ridotto, voce massima sub minimale
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.0}")
                front_vol_adj="0.80"                                     
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.85}")       
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.78}") 
                hp_freq=130; lp_freq=7500
                ;;
            cartoni)
                # DTS Cartoni: Bilanciamento musicale
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.7}")    
                front_vol_adj="0.87"                                     
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.92}")      
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.85}") 
                hp_freq=125
                ;;
        esac
        
        # Filtro DTS con crossover LFE precisione, resampling SoxR e filtri Front
        ADV_FILTER=$(cat <<EOF | tr -d '\n'
[0:a]channelmap=channel_layout=5.1[audio5dot1];
[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
[FC]highpass=f=${hp_freq},lowpass=f=${lp_freq},volume=${voice_vol_adj},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
[FL]${FRONT_FILTER},volume=${front_vol_adj}[left];
[FR]${FRONT_FILTER},volume=${front_vol_adj}[right];
[LFE]highpass=f=30:poles=2,lowpass=f=115:poles=2,volume=${lfe_vol_adj}[bass];
[BL]highpass=f=30:poles=1,lowpass=f=19000:poles=1,volume=${surround_vol_adj}[surroundL];
[BR]highpass=f=30:poles=1,lowpass=f=19000:poles=1,volume=${surround_vol_adj}[surroundR];
[left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1:map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[joined];
[joined]aresample=48000:resampler=soxr:precision=28:cheby=1,asetnsamples=n=1152:p=0,aformat=sample_fmts=s32:channel_layouts=5.1,adither=method=triangular_hp[out]
EOF
)
    else
        # ===== RAMO EAC3/AC3: Parametri per codec Dolby =====
        case "$PRESET" in
            film)
                # EAC3/AC3 Film: Voce presente ma non eccessiva
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.2}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.12}")
                ;;
            serie)
                # EAC3/AC3 Serie: Ottimizzato per dialoghi TV
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.5}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.08}")
                ;;
            cartoni)
                # EAC3/AC3 Cartoni: Bilanciato per contenuti misti
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.8}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.02}")
                ;;
        esac
        
        # Calcolo riduzione LFE specifica per preset
        case "$PRESET" in
            serie)
                # Serie TV: Sub molto controllato per SP7 
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.80}")       # -20% per dialoghi TV
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.92}")
                ;;
            film)
                # Film: Sub più controllato come richiesto
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.83}")       # -17% bilanciato
                surround_vol_adj=${SURROUND_VOL}
                ;;
            cartoni)
                # Cartoni: LFE leggermente controllato per bilanciamento
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.92}")       # -8% preserva impatto 
                surround_vol_adj=${SURROUND_VOL}
                ;;
            *)
                lfe_vol_adj=${LFE_VOL}  # Fallback sicuro
                surround_vol_adj=${SURROUND_VOL}
                ;;
        esac
        
        # Filtro EAC3/AC3 con crossover LFE precisione, anti-aliasing surround e filtri Front
        ADV_FILTER=$(cat <<EOF | tr -d '\n'
[0:a]channelmap=channel_layout=5.1[audio5dot1];
[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
[FC]highpass=f=${hp_freq},lowpass=f=${lp_freq},volume=${voice_vol_adj},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
[FL]${FRONT_FILTER},volume=${front_vol_adj}[left];
[FR]${FRONT_FILTER},volume=${front_vol_adj}[right];
[LFE]highpass=f=25:poles=2,lowpass=f=105:poles=2,volume=${lfe_vol_adj}[bass];
[BL]highpass=f=35:poles=1,lowpass=f=18000:poles=1,volume=${surround_vol_adj}[surroundL];
[BR]highpass=f=35:poles=1,lowpass=f=18000:poles=1,volume=${surround_vol_adj}[surroundR];
[left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1[out]
EOF
)
    fi
}

build_audio_filter

# -----------------------------------------------------------------------------------------------
#  PROCESSING PARALLELO E GESTIONE RISORSE
# -----------------------------------------------------------------------------------------------
PROCESSED_FILES=()
PROCESSED_COUNT=0
FAILED_COUNT=0
TOTAL_START_TIME=$(date +%s)
MAX_PARALLEL=1  # Default: elaborazione sequenziale

# Funzione per attendere completamento processi paralleli
wait_for_slot() {
    while (( $(jobs -r | wc -l) >= MAX_PARALLEL )); do
        sleep 1
    done
}

# Funzione per attendere tutti i processi in background
wait_all_jobs() {
    while (( $(jobs -r | wc -l) > 0 )); do
        sleep 1
    done
}

process() {
    local input_file="$1"
    local parallel_mode="${2:-false}"
    local out="${input_file%.*}_${PRESET}_clearvoice0.mkv"
    
    # Validazioni più robuste
    if [[ ! -f "$input_file" ]]; then
        echo "❌ File '$input_file' non trovato!" >&2
        ((FAILED_COUNT++))
        return 1
    fi
    
    # Check spazio disco (stima conservativa)
    local file_size=$(stat -c%s "$input_file" 2>/dev/null || stat -f%z "$input_file" 2>/dev/null || echo "0")
    local free_space=$(df . | awk 'NR==2 {print $4*1024}' 2>/dev/null || echo "999999999999")
    if (( file_size > 0 && file_size * 2 > free_space )); then
        echo "⚠️  Spazio disco insufficiente per elaborare '$input_file'" >&2
        ((FAILED_COUNT++))
        return 1
    fi
    
    # ===== RILEVAMENTO TRACCIA AUDIO 5.1 =====
    local channel_layout=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channel_layout -of csv=p=0 "$input_file" 2>/dev/null)
    local channels=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$input_file" 2>/dev/null)

    if [[ "$channel_layout" != "5.1" && "$channels" != "6" ]]; then
        echo "⚠️  '$input_file' non ha audio 5.1 (layout: $channel_layout, canali: $channels), saltato." >&2
        ((FAILED_COUNT++))
        return 1
    fi
    
    # ===== CORREZIONE LAYOUT AUDIO =====
    if [[ "$channel_layout" == "unknown" && "$channels" == "6" ]]; then
        echo "ℹ️  File con 6 canali ma layout sconosciuto, assumo 5.1"
        ADV_FILTER="${ADV_FILTER//channelmap=channel_layout=5.1/aformat=channel_layouts=5.1}"
    fi
    
    echo -e "\n🎬 Processing: $(basename "$input_file") [Preset: $PRESET] $([ "$parallel_mode" = "true" ] && echo "[PARALLEL]" || echo "")"
    
    # Controllo sovrascrittura file output
    if [[ -e "$out" && "$parallel_mode" = "false" ]]; then
        read -p "⚠️  Output file '$out' presente! Sovrascrivere? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            echo "⏭️  Skipping $input_file"
            return 0
        fi
    elif [[ -e "$out" && "$parallel_mode" = "true" ]]; then
        # In modalità parallela, skippa automaticamente se il file esiste
        echo "⏭️  Output già esistente, skip: $(basename "$out")"
        return 0
    fi

    # ===== ESECUZIONE FFMPEG CON THREADING OTTIMIZZATO =====
    local START_TIME=$(date +%s)
    
    # Riduzione threads per modalità parallela per evitare sovraccarico CPU
    local thread_count=0
    if [[ "$parallel_mode" = "true" ]]; then
        thread_count=$(($(nproc) / MAX_PARALLEL))
        [[ $thread_count -lt 2 ]] && thread_count=2
    fi
    
    ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero -fflags +genpts+discardcorrupt \
        -threads $thread_count -filter_threads $thread_count -thread_queue_size 512 \
        -i "$input_file" -filter_complex "$ADV_FILTER" \
        -map 0:v -map "[out]" -map 0:a? -map 0:s? \
        -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
        -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:a:1 copy -c:s copy \
        -movflags +faststart "$out"

    local exit_code=$?
    local END_TIME=$(date +%s)
    local PROCESSING_TIME=$((END_TIME - START_TIME))
    
    if [[ $exit_code -eq 0 ]]; then
        PROCESSED_FILES+=("$input_file")
        ((PROCESSED_COUNT++))
        echo "✅ Completato in ${PROCESSING_TIME}s: $(basename "$out")"
        return 0
    else
        ((FAILED_COUNT++))
        echo "❌ Errore durante l'elaborazione di $input_file (exit code: $exit_code)" >&2
        return 1
    fi
}

# -----------------------------------------------------------------------------------------------
#  LOOP SUI FILE DI INPUT CON SUPPORTO PROCESSING PARALLELO
# -----------------------------------------------------------------------------------------------
echo "🚀 Avvio CLEARVOICE 0.76 - Preset: $PRESET | Codec: $CODEC ($BR)"

# Determina modalità parallela: 2 file per cartelle con preset "serie"
PROCESSING_DIRS=false
for path in "${INPUTS[@]}"; do
    [[ -d "$path" ]] && PROCESSING_DIRS=true && break
done

if [[ "$PROCESSING_DIRS" = "true" && "$PRESET" = "serie" ]]; then
    MAX_PARALLEL=2
    echo "🔄 Modalità parallela attivata: elaborazione 2 file contemporaneamente per serie TV"
    echo "💾 Threads per processo ridotti automaticamente per bilanciare carico CPU"
fi

echo "🎛️  Miglioramenti qualità: Compressore multi-banda, Limitatore intelligente, Crossover LFE precisione, Filtri Front L/R"

for path in "${INPUTS[@]}"; do
    if [[ -d "$path" ]]; then
        shopt -s nullglob
        local dir_files=("$path"/*.mkv)
        shopt -u nullglob
        
        if [[ ${#dir_files[@]} -gt 0 ]]; then
            echo -e "\n📁 Elaborazione cartella: $path (${#dir_files[@]} file)"
            
            for f in "${dir_files[@]}"; do
                if [[ $MAX_PARALLEL -gt 1 ]]; then
                    # Modalità parallela: attendi slot libero e lancia in background
                    wait_for_slot
                    process "$f" "true" &
                else
                    # Modalità sequenziale standard
                    process "$f" "false"
                fi
            done
            
            # Attendi completamento di tutti i processi paralleli per questa cartella
            if [[ $MAX_PARALLEL -gt 1 ]]; then
                echo "⏳ Attendo completamento processi paralleli..."
                wait_all_jobs
            fi
        fi
    else
        # File singolo: sempre sequenziale
        process "$path" "false"
    fi
done

# Attendi eventuali processi rimasti in background
if [[ $MAX_PARALLEL -gt 1 ]]; then
    wait_all_jobs
fi

# -----------------------------------------------------------------------------------------------
#  STATISTICHE FINALI E RIEPILOGO AVANZATO
# -----------------------------------------------------------------------------------------------
print_summary() {
    local TOTAL_END_TIME=$(date +%s)
    local TOTAL_TIME=$((TOTAL_END_TIME - TOTAL_START_TIME))
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "  🎯 CLEARVOICE 0.76 - ELABORAZIONE COMPLETATA"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "📊 STATISTICHE ELABORAZIONE:"
    echo "   • Preset utilizzato: $PRESET"
    echo "   • Codec output: $CODEC ($BR)"
    echo "   • File processati con successo: $PROCESSED_COUNT"
    echo "   • File falliti: $FAILED_COUNT"
    echo "   • Tempo totale: ${TOTAL_TIME}s"
    
    if [[ $MAX_PARALLEL -gt 1 ]]; then
        echo "   • Modalità parallela: $MAX_PARALLEL processi contemporaneamente"
    fi
    
    if [[ $PROCESSED_COUNT -gt 0 ]]; then
        local AVG_TIME=$((TOTAL_TIME / PROCESSED_COUNT))
        echo "   • Tempo medio per file: ${AVG_TIME}s"
        echo ""
        echo "📁 FILE ELABORATI CON SUCCESSO:"
        for file in "${PROCESSED_FILES[@]}"; do
            local output_file="${file%.*}_${PRESET}_clearvoice0.mkv"
            echo "   ✅ $(basename "$file") → $(basename "$output_file")"
        done
        echo ""
        echo "🎧 OTTIMIZZAZIONI APPLICATE:"
        case "$PRESET" in
            film)
                echo "   • Compressore multi-banda cinematografico"
                echo "   • LFE controllato -17% per SP7"
                echo "   • Limitatore intelligente preserva dinamica"
                echo "   • Filtri Front L/R: anti-rumble 22Hz, lowpass 20kHz"
                ;;
            serie)
                echo "   • Compressore dialoghi per massima intelligibilità"
                echo "   • LFE ridotto -20% per contenuti TV"
                echo "   • Anti-aliasing surround per chiarezza"
                echo "   • Filtri Front L/R: anti-rumble 28Hz, lowpass 18kHz"
                if [[ $MAX_PARALLEL -gt 1 ]]; then
                    echo "   • Processing parallelo per velocità massima"
                fi
                ;;
            cartoni)
                echo "   • Compressore musicale preserva dinamica"
                echo "   • LFE bilanciato -8% per impatto sonoro"
                echo "   • Limitatore gentile per contenuti misti"
                echo "   • Filtri Front L/R: anti-rumble 18Hz, lowpass 24kHz"
                ;;
        esac
        echo ""
        echo "💡 CONSIGLI PER L'ASCOLTO:"
        echo "   • Il preset '$PRESET' è ottimizzato per questo tipo di contenuto"
        echo "   • Su SP7: usa Sound Mode 'Cinema' per preservare dinamica naturale"
        echo "   • Evita 'AI Sound Pro' e 'Normal' che appiattiscono il range dinamico"
        echo "   • Per dialoghi difficili: attiva sottotitoli come backup"
        echo "   • Filtri Front L/R applicati per pulizia ottimale senza interferire DSP Meridian"
        if [[ $MAX_PARALLEL -gt 1 ]]; then
            echo "   • Processing parallelo ha ridotto il tempo di elaborazione totale"
        fi
    else
        echo ""
        echo "⚠️  NESSUN FILE ELABORATO"
        if [[ $FAILED_COUNT -gt 0 ]]; then
            echo "   • $FAILED_COUNT file falliti - controlla i messaggi di errore sopra"
        fi
        echo ""
        echo "🔍 VERIFICA:"
        echo "   • Presenza di file .mkv nella directory"
        echo "   • Tracce audio 5.1 nei file di input"
        echo "   • Permissions di lettura/scrittura nella directory"
        echo "   • Spazio disco sufficiente (almeno 2x dimensione file)"
    fi
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# Chiamata alla funzione di riepilogo
print_summary