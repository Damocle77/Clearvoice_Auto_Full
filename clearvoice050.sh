#!/usr/bin/env bash
# ------------------------------------------------------------------
# CLEARVOICE - 5.1 dialog-enhancer (SP7-optimized)
# ------------------------------------------------------------------
#  ===== ESEMPIO SINOTTICO D'USO =========================================
# ./clearvoice04.sh [dts|eac3|ac3] 384k "Film.mkv"  (singolo file in EAC3 384 kbps)
# ./clearvoice04.sh [dts|eac3|ac3] 448k  (tutti i .mkv in cartella in AC3 448 kbps)
# ./clearvoice04.sh --no-keep-old dts 768k "Doc.mkv"  (esclusione tracce originali)
# KEEP_OLD (true/false) modificabile anche nel blocco PARAMETRI
# ========================================================================

set -euo pipefail

# ----------------------------
#  TUNING PARAMETRI
# ----------------------------
KEEP_OLD=true         # true = mantieni audio originale, false = solo Clearvoice
VOICE_VOL=5.9         # +12dB sui dialoghi (ad es. 4.40)
LFE_VOL=0.38          # -7dB sul subwoofer
LFE_LIMIT=0.75        # ceiling limiter LFE
FRONT_VOL=1.10        # +0.8dB sui frontali L/R
SURROUND_VOL=3.5      # +9dB sui surround
FL_DELAY=8            # ms front-left ritardo 
FR_DELAY=4            # ms front-right ritardo
SL_DELAY=4            # ms surround-left ritardo
SR_DELAY=2            # ms surround-right ritardo

# ----------------------------
#  ANALISI CLI
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

# ripiego posizionale
if [[ -z $CODEC && ${#INPUTS[@]} -ge 1 ]]; then
  CODEC="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi
if [[ -z $BR && ${#INPUTS[@]} -ge 1 && "${INPUTS[0]}" =~ ^[0-9]+[kK]$ ]]; then
  BR="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi

# per impostazione predefinita tutti i file .mkv in cwd se non vengono specificati input
if [[ ${#INPUTS[@]} -eq 0 ]]; then
  shopt -s nullglob
  for f in *.mkv; do INPUTS+=("$f"); done
  shopt -u nullglob
fi
[[ ${#INPUTS[@]} -eq 0 ]] && { echo "Error: no input file or directory specified"; exit 1; }

# selezione codec
CODEC="${CODEC:-eac3}"
case "${CODEC,,}" in
  eac3) ENC=eac3; BR=${BR:-384k}; TITLE="EAC3 Clearvoice 5.1";;
  ac3)  ENC=ac3;  BR=${BR:-448k}; TITLE="AC3 Clearvoice 5.1";;
  dts)  ENC=dts;  BR=${BR:-768k}; TITLE="DTS Clearvoice 5.1"; EXTRA="-strict -2 -ar 48000";;
  *) echo "Unsupported codec $CODEC"; exit 1;;
esac

# --------------------------------------------------------  
#  PIPELINE FILTRI AUDIO
# --------------------------------------------------------  
# PRE-SPLIT  
# [0:a] dynaudnorm=f=150:m=2:p=0.90       # +2 dB max make-up (finestra 150 ms, p=0.90)  
#       channelmap=5.1                    # normalizza layout in ingresso  
#       channelsplit=5.1 -> [fl][fr][fc][lfe][sl][sr]  

# CENTER  (fc = dialoghi)  
#   agate    -55 dB / 2:1    attack 5 ms / release 250 ms  # noise-gate morbido
#   acompressor  -30 dB / 1.6:1  attack 10 ms / release 200 ms  # corpo senza pompaggio  
#   deesser  0.27:0.015                      # limatura selettiva S/Z (6-8 kHz)  
#   highshelf f=9000 Hz / +1 dB              # aria extra sugli alti  
#   volume ${VOICE_VOL}  (=5.8)              # boost center circa +12 dB  

# LFE  (subwoofer arioso)  
#   highpass 38 Hz                           # taglio infrasuono  
#   EQ -5 dB @ 50 Hz; +1.2 dB @ 60 Hz; +0.5 dB @ 70 Hz; +0.8 dB @ 85 Hz  # armoniche udibili  
#   lowpass 90 Hz                            # confina LFE sotto 90 Hz  
#   acompressor  -18 dB / 3:1  attack 10 ms / release 150 ms  # smorza colpi  
#   volume ${LFE_VOL}  (=0.35)               # livello sub circa -6.5 dB  
#   alimiter limit=${LFE_LIMIT} (=0.75)      # ceiling di sicurezza  

# FRONT L/R  
#   adelay ${FL_DELAY} ms | ${FR_DELAY} ms    # micro-delay per scena frontale  
#   volume ${FRONT_VOL}  (=1.10)              # +0.8 dB sui frontali  

# SURROUND L/R  
#   adelay ${SL_DELAY} ms | ${SR_DELAY} ms    # sincronia posteriore  
#   volume ${SURROUND_VOL}  (=2.8)            # +8 dB sui rear  
#   aecho in=0.10 : out=0.15 : 100 ms / 0.15  # riverbero leggero, aria  

# JOIN & MASTER  
#   join -> 5.1 joined  
#   volume 1.2                                # alza mix globale circa +1.6 dB  
#   alimiter limit=0.95 : attack=5 ms / release=100 ms  # no-clipping finale  
#   asetpts=PTS-STARTPTS                      # reset timestamp  
# --------------------------------------------------------    

ADV_FILTER=$(cat <<EOF
[0:a]dynaudnorm=f=150:m=2:p=0.90,channelmap=channel_layout=5.1,\
    channelsplit=channel_layout=5.1[fl][fr][fc][lfe][sl][sr];

[fc]agate=threshold=-55dB:ratio=2:attack=5:release=250,\
    acompressor=threshold=-30dB:ratio=1.6:attack=10:release=200,\
    deesser=0.27:0.015,\
    highshelf=f=9000:g=+1.0,\
    volume=${VOICE_VOL}[fc_out];

[lfe]highpass=f=38:t=q:w=1.2,\
     equalizer=f=50:t=q:w=1.2:g=-5,\
     equalizer=f=60:t=q:w=1.4:g=+1.2,\
     equalizer=f=70:t=q:w=1.5:g=+0.5,\
     equalizer=f=85:t=q:w=1.4:g=+0.8,\
     lowpass=f=90,\
     acompressor=threshold=-18dB:ratio=3:attack=10:release=150:knee=6dB,\
     volume=${LFE_VOL},\
     alimiter=limit=${LFE_LIMIT}:attack=4:release=250[lfe_out];

[fl]adelay=delays=${FL_DELAY}:all=1,volume=${FRONT_VOL}[fl_out];
[fr]adelay=delays=${FR_DELAY}:all=1,volume=${FRONT_VOL}[fr_out];

[sl]adelay=delays=${SL_DELAY}:all=1,volume=${SURROUND_VOL},\
     aecho=in_gain=0.10:out_gain=0.15:delays=100:decays=0.15[sl_out];
[sr]adelay=delays=${SR_DELAY}:all=1,volume=${SURROUND_VOL},\
     aecho=in_gain=0.10:out_gain=0.15:delays=100:decays=0.15[sr_out];

[fl_out][fr_out][fc_out][lfe_out][sl_out][sr_out]join=inputs=6:channel_layout=5.1[joined];
[joined]volume=1.2,alimiter=limit=0.95:attack=5:release=100,asetpts=PTS-STARTPTS[out]
EOF
)

# ----------------------------
#  PROCESSING SU FILES
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
    ffmpeg -y -hide_banner -avoid_negative_ts make_zero -fflags +genpts \
      -hwaccel cuda -threads 0 -filter_threads 0 -filter_complex_threads 0 \
      -i "$input_file" -filter_complex "$ADV_FILTER" \
      -map 0:v -map "[out]" -map 0:a? -map 0:s? \
      -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
      -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:a:1 copy -c:s srt "$out"
  else
    ffmpeg -y -hide_banner -avoid_negative_ts make_zero -fflags +genpts \
      -hwaccel cuda -threads 0 -filter_threads 0 -filter_complex_threads 0 \
      -i "$input_file" -filter_complex "$ADV_FILTER" \
      -map 0:v -map "[out]" -map 0:a? -map 0:s? \
      -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
      -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:s srt "$out"
  fi
}

# ----------------------------
#  LOOP CATENA FILES
# ----------------------------
for path in "${INPUTS[@]}"; do
  if [[ -d $path ]]; then
    shopt -s nullglob
    for f in "$path"/*.mkv; do process "$f"; done
    shopt -u nullglob
  else
    process "$path"
  fi
done

echo "All done!"

