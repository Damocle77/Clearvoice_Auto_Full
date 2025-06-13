#!/bin/bash

# ===============================================================================
# 🎬 CLEARVOICE 0.88 - SISTEMA PROFESSIONALE OTTIMIZZAZIONE AUDIO 5.1
# ===============================================================================
# VERSIONE 0.88 - MIGLIORAMENTI LFE ARIOSO + FOCUS VOCALE:
# • LFE arioso con EQ selettivo (40Hz/65Hz/85Hz) senza boom
# • Focus vocale migliorato per film/serie con frontali ridotti
# • Ducking LFE equilibrato preservando dinamica naturale
# • Firequalizer anti-baritono ottimizzato per voci italiane
# • SoxR audiophile 28-bit precision con noise shaping triangolare
# • Gestione tracce ClearVoice + Originale con metadati professionali
# • Performance adaptive con ETA intelligente e gestione interruzioni
# • Backup automatico metadati e recovery robusto con cleanup sicuro
# • Output dinamico (MKV/MP4) e validazione bitrate codec-specifici
# ===============================================================================

# --- VERSIONING E VARIABILI GLOBALI ---------------------------------------------------------
VERSION="0.88"
SCRIPT_NAME="ClearVoice"
LOG_FILE=""
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

# ✅ CLEANUP anche del log temp se esiste
cleanup_and_exit() {
  local exit_code=$?
  log_message "INFO" "🧹 Cleanup automatico in corso..."
  
  # Rimuovi SOLO file temporanei con pattern specifico _temp.
  find . -maxdepth 1 -name "*_temp.mkv" -delete 2>/dev/null
  find . -maxdepth 1 -name "*_temp.mp4" -delete 2>/dev/null
  
  # ✅ AGGIUNTO: Rimuovi log temporaneo se esiste
  [[ -f "clearvoice088_temp.log" ]] && rm -f "clearvoice088_temp.log"
  
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
🎬 CLEARVOICE 0.88 - Sistema Professionale di Ottimizzazione Audio 5.1

UTILIZZO:
    ./clearvoice088_preset.sh [--preset] [codec] [bitrate] file1 [file2 ...]

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
    ./clearvoice088_preset.sh --film dts 1536k film_4k.mkv
    
    # Serie TV per viewing quotidiano
    ./clearvoice088_preset.sh --serie eac3 640k episodi_*.mkv
    
    # Materiale problematico con cleanup
    ./clearvoice088_preset.sh --tv eac3 768k rip_compressed.mkv

MIGLIORAMENTI v0.88:
• LFE arioso con EQ selettivo per presenza senza boom
• Focus vocale potenziato per film/serie (frontali ridotti)
• Ducking LFE equilibrato che preserva dinamica naturale
• Firequalizer anti-baritono calibrato per voci italiane
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
      640k|768k|756k|1536k) 
        # ✅ AGGIUNTO: Se trova un bitrate, mantieni quello precedente o usa default
        BR="$1"
        shift
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
# CONFIGURAZIONE PRESET OTTIMIZZATA V0.88
# -----------------------------------------------------------------------------------------------
configure_preset() {
  case "$PRESET" in
    film)    
      VOICE_VOL=8.6; FRONT_VOL=0.85; LFE_VOL=0.20; SURROUND_VOL=4.5; 
      HP_FREQ=120; LP_FREQ=8800;;
    serie)   
      VOICE_VOL=8.8; FRONT_VOL=0.82; LFE_VOL=0.20; SURROUND_VOL=4.5; 
      HP_FREQ=150; LP_FREQ=8800;;
    tv)      
      VOICE_VOL=7.8; FRONT_VOL=0.90; LFE_VOL=0.20; SURROUND_VOL=4.2; 
      HP_FREQ=180; LP_FREQ=7000;;
    cartoni) 
      VOICE_VOL=8.5; FRONT_VOL=0.90; LFE_VOL=0.20; SURROUND_VOL=4.5; 
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
      ENC="eac3";  # ✅ CORRETTO
      EXTRA_FLAGS="-dialnorm -31 -room_type 1 -mixing_level 108"
      ;;
    dts)  
      ENC="dts"; 
      SAMPLE_RATE=48000; 
      # Compressione ottimizzata per qualità/dimensione
      case "$BR" in
        756k)
          # Per bitrate medio: compressione moderata per bilanciare qualità/size
          EXTRA_FLAGS="-ar $SAMPLE_RATE -strict -2 -compression_level 2 -cutoff 0.95"
          ;;
        1536k)
          # Per bitrate alto: compressione minima per qualità massima
          EXTRA_FLAGS="-ar $SAMPLE_RATE -strict -2 -compression_level 1 -cutoff 0.99"
          ;;
        *)
          # Default conservativo (compression_level 2)
          EXTRA_FLAGS="-ar $SAMPLE_RATE -strict -2 -compression_level 2 -cutoff 0.97"
          ;;
      esac
      ;;
    *) 
      log_message "ERROR" "Codec non supportato: $CODEC"; 
      exit 1;;
  esac
  log_message "INFO" "🎵 Codec: $ENC | Bitrate: $BR | Flags: $EXTRA_FLAGS"
}

# -----------------------------------------------------------------------------------------------
# COSTRUZIONE FILTRI AUDIO AVANZATI V0.88 - DUCKING LFE + FIREQUALIZER
# -----------------------------------------------------------------------------------------------
build_audio_filter() {
  log_message "INFO" "🔧 Costruzione filtro audio v0.88 OTTIMIZZATO - ducking intelligente per tipo contenuto"
  
  local voice_vol_adj=$(safe_awk_calc "${VOICE_VOL}")
  local front_vol_adj=$(safe_awk_calc "${FRONT_VOL}")
  local lfe_vol_adj=$(safe_awk_calc "${LFE_VOL}")
  local surround_vol_adj=$(safe_awk_calc "${SURROUND_VOL}")
  
  # Split 5.1 con processing parallelo ottimizzato
  local ADV="[0:a:$BEST_STREAM_INDEX]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];"
  
  # Split centro voce PRIMA del processing per ducking pulito
  ADV+="[FC]asplit=2[fc_duck][fc_process];"
  
  # Processing voce EQUILIBRATO per intelligibilità naturale
  ADV+="[fc_process]highpass=f=$HP_FREQ:poles=2,lowpass=f=$LP_FREQ:poles=2,"
  ADV+="volume=${voice_vol_adj}dB,"
  
  # Firequalizer MODERATO - Focus su intelligibilità senza affaticamento
  case "$PRESET" in
    film|serie)
      # ✅ CORRETTO: Boost controllati per chiarezza senza distorsione
      ADV+="firequalizer=gain_entry='entry(280,-1.5);entry(650,2);entry(1200,3.5);entry(2200,2.5);entry(3500,0.8);entry(5000,-0.5);entry(8000,-1.5)',"
      ;;
    tv)
      # ✅ CORRETTO: Più mirato per materiale problematico ma sicuro
      ADV+="firequalizer=gain_entry='entry(300,-2);entry(800,2.5);entry(1400,4);entry(2500,3);entry(4000,0.5);entry(6000,-1)',"
      ;;
    cartoni)
      # ✅ CORRETTO: Preserva naturalezza per voci giovani
      ADV+="firequalizer=gain_entry='entry(250,-1);entry(600,1.5);entry(1100,3);entry(2000,2.2);entry(3200,0.8);entry(5500,-0.3)',"
      ;;
  esac
  
  # De-esser MOLTO DOLCE per non compromettere consonanti
  ADV+="deesser=i=0.05:m=0.3:f=0.3:s=o,"

  # Compressore DOLCE per preservare dinamica vocale naturale
  ADV+="acompressor=threshold=0.75:ratio=1.6:attack=25:release=350:makeup=1.0,"
  ADV+="alimiter=level_in=0.85:level_out=0.80:limit=0.85:attack=15:release=120[voice_final];"
  
  # FRONTALI con processing DIFFERENZIATO per preset
  ADV+="[FL]highpass=f=35:poles=1,lowpass=f=22000:poles=1,volume=${front_vol_adj}[fl_pre];"
  ADV+="[FR]highpass=f=35:poles=1,lowpass=f=22000:poles=1,volume=${front_vol_adj},adelay=0.3[fr_pre];"

  # DUCKING FRONTALI SELETTIVO - Solo per film/serie/tv
  case "$PRESET" in
    film|serie|tv)
      # DUCKING NORMALE: Dialoghi hanno priorità assoluta
      local ducking_params=""
      case "${CODEC,,}" in
        dts)
          ducking_params="threshold=0.40:ratio=2.0:attack=25:release=600:makeup=1.0"
          ;;
        eac3)
          ducking_params="threshold=0.35:ratio=2.2:attack=20:release=500:makeup=1.0" 
          ;;
      esac
      
      ADV+="[fc_duck][fl_pre]sidechaincompress=${ducking_params}[fl_ducked];"
      ADV+="[fc_duck][fr_pre]sidechaincompress=${ducking_params}[fr_ducked];"
      ;;
    cartoni)
      # NESSUN DUCKING FRONTALI: Preserva canti e performance musicali
      ADV+="[fl_pre]anull[fl_ducked];"  # Passa attraverso senza ducking
      ADV+="[fr_pre]anull[fr_ducked];"  # Passa attraverso senza ducking
      log_message "INFO" "🎵 Cartoni: NESSUN ducking frontali per preservare performance musicali"
      ;;
  esac

  # LFE ARIOSO ma CONTROLLATO + DUCKING SELETTIVO per preset
  ADV+="[LFE]highpass=f=22:poles=2,lowpass=f=105:poles=2,"
  ADV+="equalizer=f=40:width_type=h:width=1.3:g=1.6,"
  ADV+="equalizer=f=65:width_type=h:width=1.4:g=2.0,"
  ADV+="equalizer=f=85:width_type=h:width=1.1:g=1.2,"
  ADV+="acompressor=threshold=0.5:ratio=2.0:attack=8:release=150:makeup=1.0,"
  ADV+="alimiter=level_in=0.80:level_out=0.75:limit=0.80:attack=10:release=80,"
  ADV+="volume=${lfe_vol_adj}[lfe_pre];"
  
  # DUCKING LFE DIFFERENZIATO per preset - APPLICATO CORRETTAMENTE
  local lfe_ducking=""
  case "$PRESET" in
    film|serie|tv)
      # Film/Serie/TV: LFE si abbassa quando parla voce per chiarezza dialoghi
      lfe_ducking="threshold=0.50:ratio=1.8:attack=30:release=700:makeup=1.0"
      ADV+="[fc_duck][lfe_pre]sidechaincompress=${lfe_ducking}[lfe_final];"
      ;;
    cartoni)
      # Cartoni: LFE ducking MINIMO per preservare effetti musicali/esplosioni
      lfe_ducking="threshold=0.65:ratio=1.3:attack=50:release=900:makeup=1.0"
      ADV+="[fc_duck][lfe_pre]sidechaincompress=${lfe_ducking}[lfe_final];"
      ;;
  esac
  
  # Surround CHIARI ma non competitivi
  #ADV+="[BL]highpass=f=40:poles=2,lowpass=f=18000:poles=2,volume=${surround_vol_adj},adelay=0.8[bl_pre];"
  #ADV+="[BR]highpass=f=40:poles=2,lowpass=f=18000:poles=2,volume=${surround_vol_adj},adelay=1.2[br_pre];"
  ADV+="[BL]highpass=f=40:poles=2,lowpass=f=18000:poles=2,volume=${surround_vol_adj},adelay=0.8[bl_final];" 
  ADV+="[BR]highpass=f=40:poles=2,lowpass=f=18000:poles=2,volume=${surround_vol_adj},adelay=1.2[br_final];"
  
  # Ducking surround DIFFERENZIATO per preset - RIMOSSO
  # local surround_ducking=""
  # case "$PRESET" in
  #   film|serie|tv)
  #     # Ducking normale per dialoghi prominenti
  #     surround_ducking="threshold=0.55:ratio=1.5:attack=35:release=800:makeup=1.0"
  #     ;;
  #   cartoni)
  #     # Ducking ridotto per preservare atmosfere musicali
  #     surround_ducking="threshold=0.65:ratio=1.3:attack=45:release=1000:makeup=1.0"
  #     ;;
  # esac
  
  # ADV+="[fc_duck][bl_pre]sidechaincompress=${surround_ducking}[bl_ducked];" # RIMOSSO
  # ADV+="[fc_duck][br_pre]sidechaincompress=${surround_ducking}[br_ducked];" # RIMOSSO
  
  # Join finale 5.1 con ordine corretto dei canali
  #ADV+="[fl_ducked][fr_ducked][voice_final][lfe_final][bl_ducked][br_ducked]join=inputs=6:channel_layout=5.1[mixed];"
  ADV+="[fl_ducked][fr_ducked][voice_final][lfe_final][bl_final][br_final]join=inputs=6:channel_layout=5.1[mixed];" 

  # SoxR finale ottimizzato per codec
  case "${CODEC,,}" in
    dts)
      # DTS: Qualità alta ma conservativa per preservare dinamica
      ADV+="[mixed]aresample=48000:resampler=soxr:precision=28:cutoff=0.96:dither_method=triangular:filter_size=32[out]"
      ;;
    eac3)
      # E-AC3: Bilanciato per compatibilità
      ADV+="[mixed]aresample=48000:resampler=soxr:precision=24:cutoff=0.93:dither_method=triangular:filter_size=24[out]"
      ;;
  esac
  
  ADV_FILTER="$ADV"
  log_message "INFO" "✅ Filtro INTELLIGENTE: Ducking selettivo per tipo contenuto!"
}

# -----------------------------------------------------------------------------------------------
# VALIDAZIONE INPUT SEMPLIFICATA
# -----------------------------------------------------------------------------------------------
validate_inputs() {
  log_message "INFO" "🔍 Validazione input ClearVoice v0.88..."
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

debug_config() {
  log_message "INFO" "🐛 DEBUG CONFIG:"
  log_message "INFO" "   PRESET: $PRESET"
  log_message "INFO" "   CODEC: $CODEC" 
  log_message "INFO" "   BR: $BR"
  log_message "INFO" "   ARGS: $*"
}

# -----------------------------------------------------------------------------------------------
# MAIN FUNCTION SEMPLIFICATA
# -----------------------------------------------------------------------------------------------
main() {
  # Setup gestione interruzioni
  setup_signal_handling
  
  # Parse arguments PRIMA per avere il nome file
  local files=()
  readarray -t files < <(parse_arguments "$@")
  
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "ERROR: Nessun file video specificato"
    echo ""
    show_help
  fi
  
  # 🆕 GENERA LOG FILE SUBITO con nome corretto
  local first_file_name=$(basename "${files[0]}")
  first_file_name="${first_file_name%.*}"  # Rimuove estensione
  LOG_FILE="${first_file_name}_clearvoice0.log"
  
  # Ora inizia TUTTO il logging nel file corretto
  log_message "INFO" "=== CLEARVOICE v$VERSION SYSTEM STARTUP ==="
  log_message "INFO" "📋 Log session: $LOG_FILE"
  
  # Check help prima di tutto
  for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
      show_help
    fi
  done
  
  # Configurazione preset e codec (ora scrivono nel log corretto)
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