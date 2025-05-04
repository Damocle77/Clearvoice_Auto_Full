#!/usr/bin/env bash
# ------------------------------------------------------------------
# CLEARVOICE v4.1.4 — 5.1 dialog-enhancer & re-encoder
# ------------------------------------------------------------------
set -euo pipefail

# ----------------------------
#  USER-TUNABLE PARAMETERS
# ----------------------------
KEEP_OLD=true         # true = keep original audio, false = only Clearvoice
VOICE_VOL=1.8         # +5 dB dialog
LFE_VOL=0.79          # -2 dB sub
LFE_LIMIT=0.75        # limiter ceiling (0-1)
FRONT_VOL=1.12        # +1 dB front L/R
SURROUND_VOL=1.78     # +5 dB surround
FL_DELAY=4            # ms front-left delay
FR_DELAY=2            # ms front-right delay
SL_DELAY=4            # ms surround-left delay
SR_DELAY=6            # ms surround-right delay

# ----------------------------
#  PARSE CLI
# ----------------------------
CODEC=""; BR=""; INPUTS=(); EXTRA=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c) CODEC="$2"; shift 2;;
    -b) BR="$2";   shift 2;;
    --no-keep-old) KEEP_OLD=false; shift;;
    --keep-old)    KEEP_OLD=true;  shift;;
    -h|--help)
      sed -n '5,22p' "$0"; exit 0;;
    -*) echo "Unknown option $1"; exit 1;;
    *) INPUTS+=("$1"); shift;;
  esac
done

# Positional fallback for codec/bitrate
if [[ -z $CODEC && ${#INPUTS[@]} -ge 1 ]]; then
  CODEC="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi
if [[ -z $BR && ${#INPUTS[@]} -ge 1 && "${INPUTS[0]}" =~ ^[0-9]+[kK]$ ]]; then
  BR="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi

# se non ho ricevuto file in input, processa tutti i .mkv in cwd
if [[ ${#INPUTS[@]} -eq 0 ]]; then
  shopt -s nullglob
  for f in *.mkv; do
    INPUTS+=("$f")
  done
  shopt -u nullglob
fi

[[ ${#INPUTS[@]} -eq 0 ]] && { echo "Error: no input file or directory specified"; exit 1; }

# Codec selection
CODEC="${CODEC:-eac3}"
case "${CODEC,,}" in
  eac3) ENC=eac3; BR=${BR:-384k}; TITLE="EAC3 Clearvoice 5.1";;
  ac3)  ENC=ac3;  BR=${BR:-448k}; TITLE="AC3 Clearvoice 5.1";;
  dts)  ENC=dts;  BR=${BR:-768k}; TITLE="DTS Clearvoice 5.1"; EXTRA="-strict -2 -ar 48000";;
  *) echo "Unsupported codec $CODEC"; exit 1;;
esac

# ----------------------------
#  FILTER GRAPH
# ----------------------------
ADV_FILTER=$(cat <<EOF
[0:a]channelmap=channel_layout=5.1:channel_layout=5.1,channelsplit=channel_layout=5.1[fl][fr][fc][lfe][sl][sr];
[fc]highpass=f=90,acompressor=threshold=-20dB:ratio=3:attack=8:release=150:knee=4dB,alimiter=limit=0.9:attack=3:release=30,equalizer=f=6000:t=q:w=1.6:g=-3,equalizer=f=4000:t=q:w=1.2:g=-0.8,equalizer=f=250:t=q:w=1.5:g=+1.5,volume=${VOICE_VOL}[fc_p];
[lfe]highpass=f=28:t=q:w=1.2,equalizer=f=40:t=q:w=1.0:g=-5,lowpass=f=90,bass=g=2:f=75:t=q:w=1.2,volume=${LFE_VOL},alimiter=limit=${LFE_LIMIT}:attack=5:release=100[lfe_p];
[fl]adelay=delays=${FL_DELAY}:all=1,bass=g=0.3:f=90:t=q:w=1,volume=${FRONT_VOL}[fl_p];
[fr]adelay=delays=${FR_DELAY}:all=1,bass=g=0.3:f=90:t=q:w=1,volume=${FRONT_VOL}[fr_p];
[sl]adelay=delays=${SL_DELAY}:all=1,bass=g=0.2:f=90:t=q:w=1,volume=${SURROUND_VOL}[sl_p];
[sr]adelay=delays=${SR_DELAY}:all=1,bass=g=0.2:f=90:t=q:w=1,volume=${SURROUND_VOL}[sr_p];
[fl_p][fr_p][fc_p][lfe_p][sl_p][sr_p]join=inputs=6:channel_layout=5.1[out]
EOF
)

# ----------------------------
#  PROCESS ONE FILE
# ----------------------------
process() {
  local input_file="$1"
  local out="${input_file%.*}_clearvoice0.mkv"
  echo -e "\n→ Processing: $input_file"
  if [[ -e $out ]]; then
    read -p "Output exists. Overwrite? (y/n): " r
    [[ $r != y ]] && return
  fi

  if [[ "$KEEP_OLD" == true ]]; then
    ffmpeg -y -hide_banner -i "$input_file" -filter_complex "$ADV_FILTER" \
      -map 0:v -map "[out]" -map 0:a? -map 0:s? \
      -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
      -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:a:1 copy -c:s copy "$out"
  else
    ffmpeg -y -hide_banner -i "$input_file" -filter_complex "$ADV_FILTER" \
      -map 0:v -map "[out]" -map 0:s? \
      -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
      -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:s copy "$out"
  fi
}

# ----------------------------
#  LOOP OVER INPUTS (file or dir)
# ----------------------------
for path in "${INPUTS[@]}"; do
  if [[ -d $path ]]; then
    shopt -s nullglob
    for f in "$path"/*.mkv; do
      process "$f"
    done
    shopt -u nullglob
  else
    process "$path"
  fi
done

echo "All done!"
