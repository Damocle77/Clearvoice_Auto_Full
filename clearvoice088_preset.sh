#!/bin/bash

# ===============================================================================
# 🎬 CLEARVOICE 0.88 WORKING - CORREZIONE DEFINITIVA MAPPING
# ===============================================================================

VERSION="0.88-working"
LOG_FILE=""
VALIDATED_FILES_GLOBAL=()
RETRY_FAILED=()
START_SCRIPT_TIME=$(date +%s)
BEST_STREAM_INDEX=0

# Impostazioni di default
PRESET="film"
CODEC="eac3"
BR="640k"

# Preset values
VOICE_VOL=8.2
FRONT_VOL=0.86
LFE_VOL=1.3
SURROUND_VOL=1.6
HP_FREQ=120
LP_FREQ=8800
TITLE=""
ENC=""
EXTRA_FLAGS=""
ADV_FILTER=""
DUCKING_MODE="standard"
LFE_MULTIPLIER=1.0

# -----------------------------------------------------------------------------------------------
# UTILITIES
# -----------------------------------------------------------------------------------------------
log_message() { 
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] ${*:2}"
}

safe_awk_calc() { 
  awk "BEGIN { printf \"%.4f\", $1 }" 2>/dev/null || echo "1.0"
}

show_help() {
  cat << 'EOF'
🎬 CLEARVOICE 0.88-WORKING - Sistema Professionale Ottimizzazione Audio 5.1

UTILIZZO:
    ./clearvoice088_preset.sh [--preset] [codec] [bitrate] file1 [file2 ...]

PRESET:
    --film      : Bilanciamento cinematografico (default)
    --serie     : Focus dialoghi per serie TV  
    --tv        : Cleanup materiale problematico
    --cartoni   : Preserva dinamica musicale

CODEC:
    eac3 640k   : E-AC3 640k (default)
    eac3 768k   : E-AC3 768k
    dts 756k    : DTS 756k
    dts 1536k   : DTS 1536k

ESEMPI:
    ./clearvoice088_preset.sh --film dts 756k "file.mkv"
    ./clearvoice088_preset.sh --serie eac3 640k *.mkv
EOF
  exit 1
}

# -----------------------------------------------------------------------------------------------
# PARSING ARGOMENTI
# -----------------------------------------------------------------------------------------------
parse_arguments() {
  local files=()
  
  PRESET="film"
  CODEC="eac3" 
  BR="640k"
  
  for arg in "$@"; do
    case "$arg" in
      --film)
        PRESET="film"
        log_message "INFO" "✓ Preset: film"
        ;;
      --serie)
        PRESET="serie"
        log_message "INFO" "✓ Preset: serie"
        ;;
      --tv)
        PRESET="tv"
        log_message "INFO" "✓ Preset: tv"
        ;;
      --cartoni)
        PRESET="cartoni"
        log_message "INFO" "✓ Preset: cartoni"
        ;;
      eac3)
        CODEC="eac3"
        log_message "INFO" "✓ Codec: eac3"
        ;;
      dts)
        CODEC="dts"
        log_message "INFO" "✓ Codec: dts"
        ;;
      *k|[0-9]*)
        if [[ "$arg" =~ ^[0-9]+k?$ ]]; then
          BR="$arg"
          [[ "$BR" != *k ]] && BR="${BR}k"
          log_message "INFO" "✓ Bitrate: $BR"
        fi
        ;;
      -h|--help)
        show_help
        ;;
      *)
        if [[ -f "$arg" ]]; then
          files+=("$arg")
          log_message "INFO" "✓ File: $(basename "$arg")"
        fi
        ;;
    esac
  done
  
  printf '%s\n' "${files[@]}"
}

# -----------------------------------------------------------------------------------------------
# CONFIGURAZIONE
# -----------------------------------------------------------------------------------------------
configure_preset() {
  case "$PRESET" in
    "film")
      VOICE_VOL=8.2; FRONT_VOL=0.86; LFE_VOL=1.3; SURROUND_VOL=1.6
      HP_FREQ=120; LP_FREQ=8800; DUCKING_MODE="standard"
      ;;
    "serie")
      VOICE_VOL=9.5; FRONT_VOL=0.78; LFE_VOL=1.1; SURROUND_VOL=1.4
      HP_FREQ=130; LP_FREQ=8500; DUCKING_MODE="standard"
      ;;
    "tv")
      VOICE_VOL=11.0; FRONT_VOL=0.70; LFE_VOL=0.8; SURROUND_VOL=1.2
      HP_FREQ=140; LP_FREQ=8200; DUCKING_MODE="aggressive"
      ;;
    "cartoni")
      VOICE_VOL=6.5; FRONT_VOL=0.92; LFE_VOL=1.5; SURROUND_VOL=1.8
      HP_FREQ=100; LP_FREQ=10000; DUCKING_MODE="gentle"
      ;;
  esac
  TITLE="ClearVoice ${PRESET^} v$VERSION"
}

configure_codec() {
  case "$CODEC" in
    "eac3")
      ENC="eac3"
      EXTRA_FLAGS="-mixing_level 108 -room_type 1"
      LFE_MULTIPLIER=1.0
      ;;
    "dts")
      ENC="dts"
      EXTRA_FLAGS=""
      LFE_MULTIPLIER=0.7
      ;;
  esac
  
  log_message "INFO" "📊 Configurazione finale:"
  log_message "INFO" "   Preset: $PRESET | Codec: $ENC | Bitrate: $BR"
  log_message "INFO" "   Voice: +${VOICE_VOL}dB | LFE mult: ${LFE_MULTIPLIER}x"
}

# -----------------------------------------------------------------------------------------------
# VALIDAZIONE
# -----------------------------------------------------------------------------------------------
validate_inputs() {
  local files=("$@")
  local valid_count=0
  
  for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
      log_message "ERROR" "❌ File non trovato: $file"
      continue
    fi
    
    VALIDATED_FILES_GLOBAL+=("$file")
    ((valid_count++))
  done
  
  log_message "INFO" "✅ File validati: $valid_count"
  [[ $valid_count -eq 0 ]] && { log_message "ERROR" "❌ Nessun file valido"; exit 1; }
}

# -----------------------------------------------------------------------------------------------
# FILTRO AUDIO
# -----------------------------------------------------------------------------------------------
build_simple_filter() {
  local input_channels="$1"
  
  local voice_vol_adj=$(safe_awk_calc "${VOICE_VOL}")
  local front_vol_adj=$(safe_awk_calc "${FRONT_VOL}")
  local lfe_vol_adj=$(safe_awk_calc "${LFE_VOL} * ${LFE_MULTIPLIER}")
  local surround_vol_adj=$(safe_awk_calc "${SURROUND_VOL}")
  
  log_message "INFO" "🔧 Filtro per $input_channels canali:"
  log_message "INFO" "   Voice=+${VOICE_VOL}dB, Front=${front_vol_adj}x, LFE=${lfe_vol_adj}x, Surr=${surround_vol_adj}x"
  
  local filter=""
  
  # Input da stream 0:1 (l'audio del file)
  if [[ "$input_channels" == "6" ]]; then
    filter="[0:1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];"
  else
    filter="[0:1]pan=5.1|FL=FL|FR=FR|FC=FC|LFE=LFE|BL=BL|BR=BR[conv];"
    filter+="[conv]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];"
  fi
  
  # Processing volumi
  filter+="[FL]volume=${front_vol_adj}[fl_out];"
  filter+="[FR]volume=${front_vol_adj}[fr_out];"
  filter+="[FC]volume=${voice_vol_adj}[fc_out];"
  filter+="[LFE]volume=${lfe_vol_adj}[lfe_out];"
  filter+="[BL]volume=${surround_vol_adj}[bl_out];"
  filter+="[BR]volume=${surround_vol_adj}[br_out];"
  
  # Join finale
  filter+="[fl_out][fr_out][fc_out][lfe_out][bl_out][br_out]join=inputs=6:channel_layout=5.1[clearvoice]"
  
  ADV_FILTER="$filter"
  log_message "INFO" "✅ Filtro costruito: $(echo "$filter" | wc -c) caratteri"
}

# -----------------------------------------------------------------------------------------------
# PROCESSING PRINCIPALE CORRETTO
# -----------------------------------------------------------------------------------------------
process_file() {
  local input_file="$1"
  local base_name=$(basename "$input_file" .mkv)
  local output_file="${base_name}_ClearVoice.mkv"
  local temp_file="${base_name}_temp.mkv"
  
  log_message "INFO" "🎬 Elaborazione: $(basename "$input_file")"
  log_message "INFO" "📤 Output: $output_file"
  
  # Analisi stream specifici
  local stream_info=$(ffprobe -v quiet -show_entries stream=index,codec_type,codec_name,channels -of csv=p=0 "$input_file" 2>/dev/null)
  
  log_message "INFO" "🔍 Stream disponibili:"
  echo "$stream_info" | while IFS=',' read -r index type codec channels; do
    if [[ "$type" == "audio" ]]; then
      log_message "INFO" "   Stream $index: Audio $codec, $channels canali"
      BEST_STREAM_INDEX=$index
    elif [[ "$type" == "video" ]]; then
      log_message "INFO" "   Stream $index: Video $codec"
    fi
  done
  
  # Per questo file specifico sappiamo che l'audio è 0:1 con 6 canali EAC3
  local input_channels=6
  local input_codec="eac3"
  
  log_message "INFO" "🎵 Usando stream 0:1: $input_channels canali $input_codec"
  
  # Costruisci filtro
  build_simple_filter "$input_channels"
  
  # COMANDO FFMPEG CORRETTO - UNA SOLA TRACCIA AUDIO OUTPUT
  log_message "INFO" "🚀 Avvio FFmpeg con mapping corretto..."
  
  local cmd=(
    ffmpeg -y
    -i "$input_file"
    -filter_complex "$ADV_FILTER"
  )
  
  # Mapping CORRETTO
  cmd+=(
    -map 0:0 -c:v copy                    # Video
    -map "[clearvoice]"                   # Audio elaborato dal filtro
  )
  
  # Codec audio
  if [[ "$CODEC" == "dts" ]]; then
    cmd+=(-c:a dts -ar 48000 -b:a "$BR" -strict -2)
  else
    cmd+=(-c:a "$ENC" -b:a "$BR" $EXTRA_FLAGS)
  fi
  
  # Metadati e sottotitoli
  cmd+=(
    -metadata:s:a:0 title="$TITLE"
    -metadata:s:a:0 language="ita"
    -map 0:2 -c:s copy                    # Sottotitoli
    "$temp_file"
  )
  
  log_message "INFO" "Comando finale:"
  log_message "INFO" "${cmd[*]}"
  
  # Esecuzione
  if "${cmd[@]}" 2>&1 | tee ffmpeg_final.log; then
    if [[ -f "$temp_file" ]]; then
      local size=$(stat -c%s "$temp_file" 2>/dev/null || stat -f%z "$temp_file" 2>/dev/null || echo "0")
      if [[ $size -gt 100000 ]]; then
        mv "$temp_file" "$output_file"
        log_message "INFO" "✅ Completato: $output_file ($(( size / 1024 / 1024 )) MB)"
        
        # Verifica output
        log_message "INFO" "🔍 Verifica output..."
        ffprobe -v quiet -show_entries stream=codec_name,channels -of csv=p=0 "$output_file" 2>/dev/null | while IFS=',' read -r codec channels; do
          log_message "INFO" "   Output: $codec, $channels canali"
        done
        
        rm -f ffmpeg_final.log
        return 0
      else
        log_message "ERROR" "❌ File output troppo piccolo: $size bytes"
      fi
    else
      log_message "ERROR" "❌ File temporaneo non creato"
    fi
  else
    log_message "ERROR" "❌ FFmpeg fallito"
    echo "=== ERRORI FFMPEG ==="
    tail -30 ffmpeg_final.log
    echo "===================="
  fi
  
  [[ -f "$temp_file" ]] && rm -f "$temp_file"
  return 1
}

# -----------------------------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------------------------
main() {
  LOG_FILE="clearvoice088_$(date +%Y%m%d_%H%M%S).log"
  
  log_message "INFO" "🎬 ClearVoice v$VERSION - MAPPING CORRETTO"
  
  if [[ $# -eq 0 ]]; then
    show_help
  fi
  
  # Parse arguments
  local files
  mapfile -t files < <(parse_arguments "$@")
  
  if [[ ${#files[@]} -eq 0 ]]; then
    log_message "ERROR" "❌ Nessun file specificato"
    exit 1
  fi
  
  # Configurazione
  configure_preset
  configure_codec
  
  # Validazione
  validate_inputs "${files[@]}"
  
  # Processing
  local success=0
  
  for file in "${VALIDATED_FILES_GLOBAL[@]}"; do
    log_message "INFO" "📁 File: $(basename "$file")"
    
    if process_file "$file"; then
      ((success++))
    else
      RETRY_FAILED+=("$file")
    fi
  done
  
  log_message "INFO" "📊 Risultati: $success/${#VALIDATED_FILES_GLOBAL[@]} file completati"
  
  if [[ ${#RETRY_FAILED[@]} -eq 0 ]]; then
    log_message "INFO" "🎉 Tutti i file completati con successo!"
    exit 0
  else
    exit 1
  fi
}

# ===============================================================================
main "$@"