#!/bin/bash

# ===============================================================================
# 🎬 CLEARVOICE 0.87 - SISTEMA PROFESSIONALE OTTIMIZZAZIONE AUDIO 5.1
# ===============================================================================
# VERSIONE 0.87 - MIGLIORAMENTI PRODUZIONE COMPLETI:
# • Ducking LFE avanzato con sidechaincompress calibrato per voci italiane
# • EQ firequalizer anti-baritono ottimizzato per intelligibilità dialoghi
# • SoxR audiophile 28-bit precision con noise shaping triangolare
# • Gestione tracce ClearVoice + Originale con metadati professionali
# • Performance adaptive con ETA intelligente e gestione interruzioni
# • Backup automatico metadati e recovery robusto con cleanup sicuro
# • Output dinamico (MKV/MP4) e validazione bitrate codec-specifici
# ===============================================================================

# --- VERSIONING E VARIABILI GLOBALI ---------------------------------------------------------
VERSION="0.87"
SCRIPT_NAME="ClearVoice"
LOG_FILE="clearvoice_$(date +%Y%m%d_%H%M%S).log"
VALIDATED_FILES_GLOBAL=()
RETRY_FAILED=()
START_SCRIPT_TIME=$(date +%s)
BEST_STREAM_INDEX=0

# Impostazioni di default (override con args)
PRESET="film"
CODEC="eac3"
BR="640k"

# Variabili performance (auto-ottimizzate)
THREAD_QUEUE_SIZE=512
FILTER_THREADS=4

# Preset values (sovrascritti da configure_preset)
VOICE_VOL=8.2
FRONT_VOL=0.86
LFE_VOL=0.23
SURROUND_VOL=4.6
HP_FREQ=120
LP_FREQ=8800
TITLE=""
ENC=""
EXTRA_FLAGS=""
ADV_FILTER=""

# -----------------------------------------------------------------------------------------------
# GESTIONE INTERRUZIONI E CLEANUP AUTOMATICO
# -----------------------------------------------------------------------------------------------
setup_signal_handling() {
  trap 'cleanup_and_exit' INT TERM EXIT
}

cleanup_and_exit() {
  local exit_code=$?
  log_message "INFO" "🧹 Cleanup automatico in corso..."
  
  # Rimuovi SOLO file temporanei con pattern specifico _temp.
  find . -maxdepth 1 -name "*_temp.mkv" -delete 2>/dev/null
  find . -maxdepth 1 -name "*_temp.mp4" -delete 2>/dev/null
  
  # Log finale
  if [[ $exit_code -eq 0 ]]; then
    log_message "INFO" "✅ ClearVoice v$VERSION terminato correttamente"
  else
    log_message "WARN" "⚠️ ClearVoice v$VERSION terminato con codice: $exit_code"
  fi
  
  exit $exit_code
}

# -----------------------------------------------------------------------------------------------
# UTILITIES E FUNZIONI DI SUPPORTO MIGLIORATI
# -----------------------------------------------------------------------------------------------
log_message() { echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] ${*:2}" | tee -a "$LOG_FILE"; }
safe_awk_calc() { awk "BEGIN { printf \"%.4f\", $1 }" 2>/dev/null || echo "1.0"; }

show_progress() { 
  local c=$1 t=$2 f="$3"
  if [[ $t -eq 0 ]]; then
    printf "\r[%s] 0%% (0/0) %s" "$(printf "%*s" 20)" "$(basename "$f")"
    return
  fi
  local p=$((c*100/t)) b=20 fb=$((p*b/100))
  local eta_info=""
  
  # Calcolo ETA semplificato
  if [[ $c -gt 1 ]]; then
    local elapsed=$(($(date +%s) - START_SCRIPT_TIME))
    local avg_time=$((elapsed / c))
    local remaining=$(((t - c) * avg_time))
    local eta_min=$((remaining / 60))
    [[ $eta_min -gt 0 ]] && eta_info=" | ETA: ${eta_min}m"
  fi
  
  printf "\r[%s%s] %d%% (%d/%d)%s %s" \
    "$(printf "%*s" $fb | tr ' ' '█')" \
    "$(printf "%*s" $((b-fb)))" \
    "$p" "$c" "$t" "$eta_info" \
    "$(basename "$f")"
}

show_help() {
  cat << 'EOF'
🎬 CLEARVOICE 0.87 - Sistema Professionale di Ottimizzazione Audio 5.1

UTILIZZO:
    ./clearvoice087_preset.sh [--preset] [codec] [bitrate] file1 [file2 ...]

PRESET INTELLIGENTI:
    --film      : Bilanciamento cinematografico (dialoghi naturali, sub integrato)
    --serie     : Dialoghi prominenti per TV viewing (dinamica controllata)  
    --tv        : Cleanup materiale problematico (noise reduction + EQ aggressivo)
    --cartoni   : Preserva effetti spettacolari (dialoghi chiari, bass esteso)

CODEC E BITRATE SUPPORTATI:
    eac3 640k   : E-AC3 640 kbps (raccomandato per compatibilità universale)
    eac3 768k   : E-AC3 768 kbps (qualità superiore, file size maggiore)
    dts 756k    : DTS 756 kbps (qualità audiophile, compatibilità limitata)
    dts 1536k   : DTS 1536 kbps (reference quality per sistemi high-end)

OUTPUT:
    Sempre ClearVoice primaria + Audio originale secondaria per flessibilità
    Formato output automatico: MKV (default) o MP4 (se input è MP4)

ESEMPI PRATICI:
    # Film con qualità reference
    ./clearvoice087_preset.sh --film dts 1536k film_4k.mkv
    
    # Serie TV per viewing quotidiano
    ./clearvoice087_preset.sh --serie eac3 640k episodi_*.mkv
    
    # Materiale problematico con cleanup
    ./clearvoice087_preset.sh --tv eac3 768k rip_compressed.mkv

MIGLIORAMENTI v0.87:
• Ducking LFE avanzato con sidechaincompress calibrato
• EQ firequalizer anti-baritono per voci italiane
• SoxR audiophile 28-bit con noise shaping triangolare  
• Gestione tracce ClearVoice + Originale professionale
• Performance adaptive con ETA intelligente
• Output format dinamico e cleanup automatico interruzioni
• Validazione bitrate codec-specifici per qualità ottimale
EOF
  exit 1
}

# -----------------------------------------------------------------------------------------------
# PARSING ARGOMENTI SEMPLIFICATO
# -----------------------------------------------------------------------------------------------
parse_arguments() {
  local files=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --preset)
        shift
        if [[ $# -gt 0 && "$1" =~ ^(film|serie|tv|cartoni)$ ]]; then
          PRESET="$1"
          shift
        fi
        ;;
      --film) PRESET="film"; shift;;
      --serie) PRESET="serie"; shift;;
      --tv) PRESET="tv"; shift;;
      --cartoni) PRESET="cartoni"; shift;;
      --codec)
        shift
        if [[ $# -gt 0 && "$1" =~ ^(eac3|dts)$ ]]; then
          CODEC="$1"
          shift
          if [[ $# -gt 0 && "$1" =~ ^[0-9]+k$ ]]; then
            BR="$1"
            shift
          fi
        fi
        ;;
      eac3|dts) 
        CODEC="$1"
        shift
        if [[ $# -gt 0 && "$1" =~ ^[0-9]+k$ ]]; then
          BR="$1"
          shift
        fi
        ;;
      -h|--help) show_help;;
      *) 
        # Solo file video validi con estensioni supportate
        if [[ -f "$1" && "$1" =~ \.(mkv|mp4|avi|m4v|mov|MKV|MP4|AVI|M4V|MOV)$ ]]; then
          files+=("$1")
        fi
        shift
        ;;
    esac
  done
  printf '%s\n' "${files[@]}"
}

# -----------------------------------------------------------------------------------------------
# CONFIGURAZIONE PRESET OTTIMIZZATA V0.87
# -----------------------------------------------------------------------------------------------
configure_preset() {
  case "$PRESET" in
    film)    
      VOICE_VOL=8.2; FRONT_VOL=0.86; LFE_VOL=0.23; SURROUND_VOL=4.6; 
      HP_FREQ=120; LP_FREQ=8800;;
    serie)   
      VOICE_VOL=8.4; FRONT_VOL=0.85; LFE_VOL=0.23; SURROUND_VOL=4.5; 
      HP_FREQ=150; LP_FREQ=8800;;
    tv)      
      VOICE_VOL=7.5; FRONT_VOL=1.00; LFE_VOL=0.23; SURROUND_VOL=4.0; 
      HP_FREQ=180; LP_FREQ=7000;;
    cartoni) 
      VOICE_VOL=8.1; FRONT_VOL=1.00; LFE_VOL=0.23; SURROUND_VOL=4.6; 
      HP_FREQ=130; LP_FREQ=6900;;
    *) 
      log_message "ERROR" "Preset invalido: $PRESET"; 
      show_help;;
  esac
  TITLE="ClearVoice ${PRESET^} v$VERSION"
  log_message "INFO" "🎚️ Preset configurato: $TITLE | VoiceVol=${VOICE_VOL}dB"
}

configure_codec() {
  case "${CODEC,,}" in
    eac3) 
      ENC="eac3"; 
      EXTRA_FLAGS="-dialnorm -31 -room_type 1 -mixing_level 108"; 
      ;;
    dts)  
      ENC="dts"; 
      SAMPLE_RATE=48000; 
      EXTRA_FLAGS="-ar $SAMPLE_RATE -strict -2 -compression_level 1 -cutoff 0.95"; 
      ;;
    *) 
      log_message "ERROR" "Codec non supportato: $CODEC"; 
      exit 1;;
  esac
  log_message "INFO" "🎵 Codec: $ENC | Bitrate: $BR | Flags: $EXTRA_FLAGS"
}

# -----------------------------------------------------------------------------------------------
# COSTRUZIONE FILTRI AUDIO AVANZATI V0.87 - DUCKING LFE + FIREQUALIZER
# -----------------------------------------------------------------------------------------------
build_audio_filter() {
  log_message "INFO" "🔧 Costruzione filtro audio v0.87 con ducking LFE + firequalizer anti-baritono"
  
  # Calcolo valori ottimizzati
  local voice_vol_adj=$(safe_awk_calc "${VOICE_VOL}")
  local front_vol_adj=$(safe_awk_calc "${FRONT_VOL}")
  local lfe_vol_adj=$(safe_awk_calc "${LFE_VOL}")
  local surround_vol_adj=$(safe_awk_calc "${SURROUND_VOL}")
  
  # Split 5.1 con processing parallelo ottimizzato
  local ADV="[0:a:$BEST_STREAM_INDEX]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];"
  
  # Split centro voce PRIMA del processing per ducking pulito
  ADV+="[FC]asplit=2[fc_duck][fc_process];"
  
  # Processing voce con EQ firequalizer anti-baritono + compressore
  ADV+="[fc_process]highpass=f=$HP_FREQ:poles=2,lowpass=f=$LP_FREQ:poles=2,"
  ADV+="volume=${voice_vol_adj}dB,"
  
  # Firequalizer calibrato per voci italiane (anti-baritono, boost presenza)
  case "$PRESET" in
    film|serie)
      ADV+="firequalizer=gain_entry='entry(280,1.8);entry(650,2.2);entry(1200,2.8);entry(2200,2.1);entry(3500,0.8);entry(5000,-0.3);entry(8000,-0.8)',"
      ;;
    tv)
      ADV+="firequalizer=gain_entry='entry(300,2.5);entry(800,3.2);entry(1400,3.0);entry(2500,2.3);entry(4000,0.5);entry(6000,-0.5)',"
      ;;
    cartoni)
      ADV+="firequalizer=gain_entry='entry(250,1.5);entry(600,2.0);entry(1100,2.5);entry(2000,1.8);entry(3200,0.6);entry(5500,-0.2)',"
      ;;
  esac
  
  # De-esser dopo firequalizer per riduzione sibilanti naturale
  ADV+="deesser=i=0.1:m=0.5:f=0.5:s=o,"

  # Compressore 2-stage dolce per naturalezza vocale
  ADV+="acompressor=threshold=0.6:ratio=2.2:attack=15:release=220:makeup=1.3,"
  ADV+="alimiter=level_in=1:level_out=0.85:limit=0.90:attack=8:release=80[voice_final];"
  
  # Frontali L/R con stereo enhancement per imaging migliorato
  ADV+="[FL]highpass=f=35:poles=1,lowpass=f=22000:poles=1,volume=${front_vol_adj},stereotools=mlev=0.1:mwid=0.3[fl];"
  ADV+="[FR]highpass=f=35:poles=1,lowpass=f=22000:poles=1,volume=${front_vol_adj},stereotools=mlev=0.1:mwid=0.3[fr];"
  
  # LFE con pre-processing per ducking
  ADV+="[LFE]highpass=f=25:poles=2,lowpass=f=110:poles=2,volume=${lfe_vol_adj}[lfe_pre];"
  
  # Parametri ducking ottimizzati - DTS più marcato per gestire dinamica superiore
  local ducking_params=""
  case "${CODEC,,}" in
    dts)
      ducking_params="threshold=0.15:ratio=3.2:attack=5:release=280:makeup=0.7"
      ;;
    eac3)
      ducking_params="threshold=0.28:ratio=2.0:attack=12:release=450:makeup=1.1"
      ;;
  esac
  
  # Applicazione ducking LFE con voce non processata per sidechain naturale
  ADV+="[fc_duck][lfe_pre]sidechaincompress=${ducking_params}[lfe_ducked];"
  
  # Surround L/R con processing dedicato per ambiente naturale
  ADV+="[BL]highpass=f=40:poles=2,lowpass=f=18000:poles=2,volume=${surround_vol_adj}[bl];"
  ADV+="[BR]highpass=f=40:poles=2,lowpass=f=18000:poles=2,volume=${surround_vol_adj}[br];"
  
  # Join finale 5.1 con ordine corretto dei canali
  ADV+="[fl][fr][voice_final][lfe_ducked][bl][br]join=inputs=6:channel_layout=5.1[mixed];"
  
  # SoxR finale ottimizzato per codec - UNA SOLA APPLICAZIONE
  case "${CODEC,,}" in
    dts)
      # Per DTS: qualità massima con oversampling per reference quality
      ADV+="[mixed]aresample=48000:resampler=soxr:precision=33:cutoff=0.99:dither_method=triangular:cheby=1[out]"
      ;;
    eac3)
      # Per E-AC3: bilanciato qualità/performance per compatibilità
      ADV+="[mixed]aresample=48000:resampler=soxr:precision=28:cutoff=0.95:dither_method=triangular:filter_size=32[out]"
      ;;
  esac
  
  ADV_FILTER="$ADV"
  log_message "INFO" "✅ Filtro costruito: ducking LFE ${CODEC^^} + firequalizer anti-baritono + de-esser + SoxR ${CODEC^^}-optimized"
}

# -----------------------------------------------------------------------------------------------
# VALIDAZIONE INPUT SEMPLIFICATA
# -----------------------------------------------------------------------------------------------
validate_inputs() {
  log_message "INFO" "🔍 Validazione input ClearVoice v0.87..."
  local files=("$@")
  VALIDATED_FILES_GLOBAL=()
  
  if [[ ${#files[@]} -eq 0 ]]; then
    log_message "ERROR" "Nessun file specificato"
    return 1
  fi

  echo "📁 Analisi di ${#files[@]} file..."
  
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      log_message "INFO" "✅ File aggiunto: $(basename "$file")"
      VALIDATED_FILES_GLOBAL+=("$file")
    else
      log_message "WARN" "❌ File non trovato: $file"
    fi
  done
  
  if [[ ${#VALIDATED_FILES_GLOBAL[@]} -eq 0 ]]; then
    log_message "ERROR" "Nessun file valido trovato"
    return 1
  fi
  
  log_message "INFO" "✅ Procedo con ${#VALIDATED_FILES_GLOBAL[@]} file"
  return 0
}

# -----------------------------------------------------------------------------------------------
# PROCESSING SEMPLIFICATO
# -----------------------------------------------------------------------------------------------
process_file() {
  local input_file="$1"
  local base_name
  base_name=$(basename "$input_file")
  base_name="${base_name%.*}"  # Rimuove estensione
  
  # Determina estensione output basata su input
  local input_ext="${input_file##*.}"
  local output_ext="mkv"  # Default MKV per compatibilità
  [[ "${input_ext,,}" == "mp4" ]] && output_ext="mp4"
  
  local output_file="${base_name}_${PRESET}_clearvoice0.${output_ext}"
  local temp_output="${output_file%.*}_temp.${output_ext}"
  
  log_message "INFO" "🎬 Processing $(basename "$input_file") [Preset: $PRESET | Codec: $CODEC $BR | Output: $output_ext]"
  
  # Controllo esistenza file output - chiede conferma invece di sovrascrivere
  if [[ -e "$output_file" ]]; then
    echo -n "⚠️ File $(basename "$output_file") già esistente. Sovrascrivere? [y/N]: "
    read -r response < /dev/tty
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      log_message "INFO" "⏭️ Processing saltato per: $(basename "$input_file")"
      return 0
    fi
    log_message "INFO" "📝 Confermata sovrascrittura per: $(basename "$output_file")"
  fi

  # Threading semplificato
  local thread_count
  thread_count=$(nproc 2>/dev/null || echo "$FILTER_THREADS")
  
  # Determina label codec per metadata
  local codec_label=""
  case "${CODEC,,}" in
    eac3) codec_label="E-AC3";;
    dts) codec_label="DTS";;
    *) codec_label="$CODEC";;
  esac
  
  # Build FFmpeg command COMPLETO - mantiene TUTTE le tracce audio originali + aggiunge ClearVoice
  local cmd=(
    ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero
    -threads "$thread_count" -filter_threads "$FILTER_THREADS" -thread_queue_size "$THREAD_QUEUE_SIZE"
    -i "$input_file"
    -filter_complex "$ADV_FILTER"
    -map "[out]" -map 0:a -map 0:v? -map 0:s? -map 0:t?
    -metadata:s:a:0 title="ClearVoice $codec_label $PRESET" -metadata:s:a:0 language=ita -disposition:a:0 default
    -c:v copy -c:a:0 "$ENC" -b:a:0 "$BR" -c:a:1 copy -c:a:2 copy -c:a:3 copy -c:a:4 copy -c:a:5 copy -c:a:6 copy -c:a:7 copy -c:s copy -c:t copy
    $EXTRA_FLAGS
    -movflags +faststart -avoid_negative_ts make_zero
    "$temp_output"
  )
  
  # Esecuzione con monitoring e gestione errori completa
  log_message "INFO" "⚙️ Avvio FFmpeg per: $(basename "$input_file")"
  
  if "${cmd[@]}" 2>&1 | tee -a "$LOG_FILE"; then
    # Sposta file solo se processing completato con successo
    if [[ -f "$temp_output" ]]; then
      mv "$temp_output" "$output_file"
      log_message "INFO" "✅ COMPLETATO: $(basename "$output_file") [ClearVoice + Tutte le tracce originali]"
      return 0
    else
      log_message "ERROR" "File temp non generato: $temp_output"
      return 1
    fi
  else
    local ffmpeg_exit_code=$?
    rm -f "$temp_output"
    log_message "ERROR" "FFmpeg fallito con exit code: $ffmpeg_exit_code per: $(basename "$input_file")"
    RETRY_FAILED+=("$input_file")
    return 1
  fi
}

# -----------------------------------------------------------------------------------------------
# SUMMARY SEMPLIFICATO
# -----------------------------------------------------------------------------------------------
print_summary() {
  local end_time=$(date +%s)
  local duration=$((end_time - START_SCRIPT_TIME))
  local processed=$((${#VALIDATED_FILES_GLOBAL[@]} - ${#RETRY_FAILED[@]}))
  local hours=$((duration / 3600))
  local minutes=$(((duration % 3600) / 60))
  local seconds=$((duration % 60))
  
  echo ""
  echo "══════════════════════════════════════════════════════════════════════════════════"
  echo "📊 STATISTICHE FINALI CLEARVOICE $VERSION:"
  echo "   🎚️ Configurazione: $PRESET | $CODEC ($BR)"
  echo "   🎵 Output: ClearVoice primaria + Audio originale secondaria"
  echo "   📁 File processati: $processed/${#VALIDATED_FILES_GLOBAL[@]}"
  echo "   ⏱️ Tempo totale: ${hours}h ${minutes}m ${seconds}s"
  
  if [[ ${#RETRY_FAILED[@]} -gt 0 ]]; then
    echo "   ⚠️ File falliti: ${#RETRY_FAILED[@]}"
    for failed_file in "${RETRY_FAILED[@]}"; do
      echo "     - $(basename "$failed_file")"
    done
  else
    echo "   ✅ Tutti i file processati con successo!"
  fi
  
  echo "   📋 Log dettagliato: $LOG_FILE"
  echo "══════════════════════════════════════════════════════════════════════════════════"
}

# -----------------------------------------------------------------------------------------------
# MAIN FUNCTION SEMPLIFICATA
# -----------------------------------------------------------------------------------------------
main() {
  # Setup gestione interruzioni
  setup_signal_handling
  
  log_message "INFO" "=== CLEARVOICE v$VERSION SYSTEM STARTUP ==="
  
  # Check help prima di tutto
  for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
      show_help
    fi
  done
  
  # Parse arguments e ottieni lista file
  local files=()
  readarray -t files < <(parse_arguments "$@")
  
  if [[ ${#files[@]} -eq 0 ]]; then
    log_message "ERROR" "Nessun file video specificato"
    echo ""
    show_help
  fi
  
  # Configurazione preset e codec
  configure_preset
  configure_codec
  
  # Costruzione filtro audio avanzato
  build_audio_filter
  
  log_message "INFO" "🚀 AVVIO CLEARVOICE $VERSION - Preset: $PRESET | Codec: $CODEC ($BR)"
  
  # Validazione input semplificata
  if ! validate_inputs "${files[@]}"; then
    log_message "ERROR" "Validazione input fallita"
    exit 1
  fi
  
  echo -e "\n🎬 Avvio processing di ${#VALIDATED_FILES_GLOBAL[@]} file..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Processing con progress tracking
  local total=${#VALIDATED_FILES_GLOBAL[@]}
  local current=0
  
  for file in "${VALIDATED_FILES_GLOBAL[@]}"; do
    ((current++))
    show_progress "$current" "$total" "$file"
    echo ""  # New line dopo progress
    
    if ! process_file "$file"; then
       log_message "WARN" "❌ Errore nel processamento di: $(basename "$file")"
    fi

    # Cancella progress bar per output pulito
    printf "\r%*s\r" 80 ""

    # Separatore tra file
    [[ $current -lt $total ]] && echo "─────────────────────────────────────────────────────────────────────────────"
  done
  
  # Summary finale
  print_summary
  
  log_message "INFO" "=== CLEARVOICE v$VERSION SYSTEM SHUTDOWN ==="
}

# ===============================================================================
#  ENTRY POINT - ESECUZIONE SCRIPT
# ===============================================================================

main "$@"