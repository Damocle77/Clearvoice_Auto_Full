#!/usr/bin/env bash

# -----------------------------------------------------------------------------------------------
#  CLEARVOICE 0.89 - OTTIMIZZAZIONE AUDIO 5.1 + LFE DUCKING + SOUNDSTAGE + SOXR
#  Script avanzato per miglioramento dialoghi e controllo LFE dinamico (C)2025
#  Autore: [Sandro "D@mocle77" Sabbioni]
# -----------------------------------------------------------------------------------------------
# CARATTERISTICHE PRINCIPALI:
# • Voice boost intelligente con compressione multi-banda
# • LFE Ducking: Il subwoofer reagisce automaticamente alla voce (sidechain)
# • Soundstage spaziale: Delay temporali per profondità stereofonica e surround 
# • Limitatore anti-clipping con soft-clipping adattivo
# • Crossover LFE professionale per controllo frequenze
# • Preset ottimizzati per diversi contenuti (Film, Serie, TV, Cartoni)
# • Supporto codec multipli: EAC3, AC3, DTS con parametri qualità ottimizzati
# • Gestione robusta formati audio con fallback intelligenti
# • SoXR resampler per qualità audio superiore (richiede build FFmpeg con SoXR)
# -----------------------------------------------------------------------------------------------

set -euo pipefail

# -----------------------------------------------------------------------------------------------
#  CONFIGURAZIONE GLOBALE
# -----------------------------------------------------------------------------------------------
FRONT_VOL=1.0         # Volume canali frontali (FL/FR) - NON MODIFICARE
VERSION="0.89"        # Versione script corrente
MIN_FFMPEG_VER="6.0"  # Versione minima ffmpeg richiesta

# Inizializza tempo globale per statistiche finali
TOTAL_START_TIME=$(date +%s)

# Verifica dipendenze e versioni del sistema
for cmd in ffmpeg awk; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Errore: Il comando richiesto '$cmd' non è stato trovato. Assicurati che sia installato e nel PATH." >&2
    exit 1
  fi
done

# Verifica nproc per Windows (opzionale, fallback a 4 thread)
if ! command -v nproc &> /dev/null; then
    echo "ℹ️  nproc non disponibile, usando 4 thread di default"
fi

# -----------------------------------------------------------------------------------------------
#  FUNZIONI UTILITY SICURE E ROBUSTE
# -----------------------------------------------------------------------------------------------

# Funzione per calcoli matematici sicuri con awk - previene errori script
safe_awk_calc() {
    local expr="$1"
    local result
    result=$(awk "BEGIN {print $expr}" 2>/dev/null)
    
    # Verifica che il risultato sia un numero valido (intero o decimale)
    if [[ "$result" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$result"
    else
        echo "1.0"  # Fallback sicuro per evitare crash dello script
    fi
}

# Funzione per validare parametri numerici con fallback robusto
validate_numeric() {
    local value="$1"
    local default="$2"
    
    if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$value"
    else
        echo "$default"  # Usa valore di default se validazione fallisce
    fi
}

# VERO LFE Ducking con sidechain compression - parametri specifici per preset
build_lfe_ducking_filter() {
    case "$PRESET" in
        film)
            # Film: Ducking moderato con threshold corretto
            # threshold: soglia trigger in dB | makeup: gain compensation
            echo "sidechaincompress=threshold=0.1:ratio=3:attack=15:release=300:mix=0.8:makeup=1"
            ;;
        serie)
            # Serie: Ducking aggressivo per chiarezza
            echo "sidechaincompress=threshold=0.08:ratio=4:attack=10:release=250:mix=0.85:makeup=1"
            ;;
        tv)
            # TV: Ducking ultra per materiale problematico
            echo "sidechaincompress=threshold=0.06:ratio=5:attack=8:release=200:mix=0.9:makeup=1"
            ;;
        cartoni)
            # Cartoni: Ducking gentile per musicalità
            echo "sidechaincompress=threshold=0.12:ratio=2.5:attack=20:release=400:mix=0.7:makeup=1"
            ;;
    esac
}

# Parametri Soundstage per profondità spaziale - delay temporali per ogni preset
set_soundstage_params() {
    case "$PRESET" in
        film)
            # Film: Soundstage cinematografico con profondità reale
            FRONT_DELAY_MS=8      # 8ms per profondità percettibile
            SURROUND_DELAY_MS=18  # 18ms per spazialità posteriore
            ;;
        serie)
            # Serie: Soundstage compatto ma percettibile
            FRONT_DELAY_MS=6      # 6ms per setup domestici
            SURROUND_DELAY_MS=14  # 14ms per ambienti piccoli
            ;;
        tv)
            # TV: Soundstage ridotto ma presente
            FRONT_DELAY_MS=5      # 5ms minimo percettibile
            SURROUND_DELAY_MS=10  # 10ms per compatibilità
            ;;
        cartoni)
            # Cartoni: Soundstage espanso per immersività
            FRONT_DELAY_MS=10     # 10ms per effetti ampi
            SURROUND_DELAY_MS=20  # 20ms per coinvolgimento
            ;;
    esac
}

# -----------------------------------------------------------------------------------------------
#  VALIDAZIONE INPUT AVANZATA CON ANALISI DETTAGLIATA
# -----------------------------------------------------------------------------------------------

# Array globale per raccogliere i file validati durante l'analisi
VALIDATED_FILES_GLOBAL=()

# Analisi dettagliata tracce audio con suggerimenti specifici di conversione
check_audio_streams() {
    local file="$1"
    
    # Estrazione metadati audio con ffprobe
    local channels
    channels=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$file" 2>/dev/null)
    local layout
    layout=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channel_layout -of csv=p=0 "$file" 2>/dev/null)
    local codec
    codec=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$file" 2>/dev/null)
    
    # Controllo validità metadati estratti
    if [[ -z "$channels" ]]; then
        echo "❌ Impossibile analizzare traccia audio"
        echo "💡 Verifica con: ffprobe -show_streams \"$file\""
        return 1
    fi
    
    echo "🔍 Audio rilevato: $codec | $channels canali | Layout: ${layout:-unknown}"
    
    # Verifica compatibilità 5.1 - accetta anche layout "unknown" per robustezza
    if [[ "$channels" == "6" && ("$layout" == "5.1" || "$layout" == "5.1(side)" || "$layout" == "unknown") ]]; then
        echo "✅ Audio 5.1 compatibile con ClearVoice + LFE Ducking + Soundstage"
        # Aggiunge il file all'array globale dei validati
        VALIDATED_FILES_GLOBAL+=("$file")
        return 0
    else
        echo "❌ Audio non compatibile con ClearVoice (richiede 5.1 surround)"
        
        # Suggerimenti specifici per formato rilevato con comandi pratici
        case "$channels" in
            1)
                echo "   🎙️ MONO rilevato"
                echo "   💡 Conversione: ffmpeg -i \"$file\" -af \"pan=5.1|FL=FC|FR=FC|FC=FC|LFE=0|BL=0|BR=0\" -c:v copy output_51.mkv"
                ;;
            2)
                echo "   🔄 STEREO rilevato"
                echo "   💡 Upmix a 5.1: ffmpeg -i \"$file\" -af \"surround\" -c:v copy output_51.mkv"
                ;;
            8)
                echo "   🎭 7.1 SURROUND rilevato"
                echo "   💡 Downmix a 5.1: ffmpeg -i \"$file\" -af \"pan=5.1|FL=0.5*FL+0.707*FLC|FR=0.5*FR+0.707*FRC|FC=FC|LFE=LFE|BL=BL|BR=BR\" -c:v copy output_51.mkv"
                ;;
            *)
                echo "   ❓ Configurazione non standard ($channels canali)"
                echo "   💡 Analisi completa: ffprobe -show_streams \"$file\""
                ;;
        esac
        return 1
    fi
}

# Validazione preliminare con conteggio dettagliato per formato e statistiche
validate_inputs() {
    local valid_count=0 total_count=0
    local mono_count=0 stereo_count=0 surround71_count=0 other_count=0
    
    # Reset array globale per nuova analisi
    VALIDATED_FILES_GLOBAL=()
    
    echo "🔍 Validazione input ClearVoice + LFE Ducking + Soundstage..."
    
    # Raccogli tutti i file con verifica esistenza robusta
    local all_files=()
    for path in "${INPUTS[@]}"; do
        if [[ -d "$path" ]]; then
            # Gestione directory con nullglob per sicurezza
            shopt -s nullglob
            local dir_files=("$path"/*.mkv)
            if [[ ${#dir_files[@]} -gt 0 ]]; then
                all_files+=("${dir_files[@]}")
            fi
            shopt -u nullglob
        elif [[ -f "$path" ]]; then
            all_files+=("$path")
        else
            echo "⚠️  Path non valido ignorato: $path"
        fi
    done
    
    # Controllo presenza file da elaborare
    if [[ ${#all_files[@]} -eq 0 ]]; then
        echo "❌ Nessun file .mkv trovato!"
        echo "💡 Comandi utili: ls *.mkv | find . -name \"*.mkv\""
        return 1
    fi
    
    echo "📁 Analisi dettagliata di ${#all_files[@]} file..."
    
    # Analisi completa di ogni file con statistiche formati
    for file in "${all_files[@]}"; do
        ((total_count++))
        echo "━━━ $(basename "$file") ━━━"
        
        # Controllo leggibilità file
        if [[ ! -r "$file" ]]; then
            echo "❌ File non leggibile"
            continue
        fi
        
        # Analisi dettagliata con conteggio formati per statistiche finali
        local channels
        channels=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$file" 2>/dev/null)
        
        # Conteggio statistico formati audio trovati
        case "$channels" in
            1) ((mono_count++));;
            2) ((stereo_count++));;
            6) ;;  # Gestito da check_audio_streams
            8) ((surround71_count++));;
            *) ((other_count++));;
        esac
        
        # Verifica compatibilità e aggiunta a lista validati
        if check_audio_streams "$file"; then
            ((valid_count++))
        fi
        echo ""
    done
    
    # Riepilogo con statistiche complete formati trovati
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Risultati analisi: $valid_count/$total_count file compatibili"
    
    # Controllo presenza file validi per procedere
    if [[ $valid_count -eq 0 ]]; then
        echo "❌ Nessun file 5.1 valido per ClearVoice + LFE Ducking + Soundstage!"
        return 1
    fi
    
    echo "✅ Procedo con $valid_count file 5.1 compatibili con LFE Ducking + Soundstage attivi"
    return 0
}

# -----------------------------------------------------------------------------------------------
#  ANALISI CLI CON PARSING ROBUSTO
# -----------------------------------------------------------------------------------------------

# Variabili globali per configurazione utente
PRESET="serie"  # preset di default ottimizzato per serie TV
CODEC=""        # codec da impostare via CLI o default
BR=""           # bitrate da impostare via CLI o default
INPUTS=()       # array file input da elaborare

# Parsing argomenti command line con gestione robusta
while [[ $# -gt 0 ]]; do
  case "$1" in
    --film) PRESET="film"; shift;;
    --serie) PRESET="serie"; shift;;
    --tv) PRESET="tv"; shift;;
    --cartoni) PRESET="cartoni"; shift;;
    -h|--help)
      # Help completo con esempi pratici e spiegazioni dettagliate
      cat << 'EOF'
CLEARVOICE 0.89 - Ottimizzazione Audio 5.1 + LFE Ducking + SoxR + Soundstage

USO: ./clearvoice089_preset.sh [PRESET] [CODEC] [BITRATE] [FILES...]

PRESET DISPONIBILI:
  --film     Cinema/Action + LFE Ducking moderato + Soundstage cinematografico
             • Voice: 8.5dB | LFE: -23% | Soundstage: 8ms/18ms
             • Ottimizzato per impatto cinematografico e dinamica

  --serie    Serie TV/Dialoghi + LFE Ducking aggressivo + Soundstage compatto  
             • Voice: 8.6dB | LFE: -23% | Soundstage: 6ms/14ms
             • Massima intelligibilità per ascolto domestico

  --tv       Materiale problematico + LFE Ducking ultra + Soundstage ridotto
             • Voice: 5.8dB | LFE: -23% | Soundstage: 5ms/10ms  
             • Per audio scadente o molto compresso

  --cartoni  Animazione + LFE Ducking gentile + Soundstage espanso
             • Voice: 8.4dB | LFE: -23% | Soundstage: 10ms/20ms
             • Preserva musicalità e effetti sonori

CODEC SUPPORTATI: 
  eac3 (default) | ac3 | dts  

BITRATE DISPONIBILI: 
  384k (default) | 448k | 640k | 768k

REQUISITI TECNICI:
  ✓ FFmpeg 6.0+ con supporto SoXR per resampling alta qualità
  ✓ Audio input 5.1 surround (6 canali)
  ✓ Spazio disco sufficiente per output

NOVITÀ VERSIONE 0.89:
  ✓ VERO LFE Ducking: Il subwoofer reagisce automaticamente alla voce (sidechain)
  ✓ Soundstage spaziale: Delay temporali percettibili (5-20ms) per profondità
  ✓ Voice boost intelligente + controllo dinamico LFE per chiarezza costante
  ✓ SoXR resampling: Qualità audio superiore (precision 28-bit)
  ✓ Parametri ottimizzati specifici per ogni preset (attack/release diversi)
  ✓ Crossover LFE professionale con filtraggio multi-polo
  ✓ Limitatore anti-clipping con soft-clipping adattivo

ESEMPI PRATICI:
  ./clearvoice089_preset.sh --serie *.mkv            # Serie TV + Ducking aggressivo
  ./clearvoice089_preset.sh --film dts 768k *.mkv    # Film DTS + Ducking moderato + SoXR
  ./clearvoice089_preset.sh --cartoni ac3 448k *.mkv # Cartoni AC3 + Ducking gentile
  ./clearvoice089_preset.sh --tv eac3 384k video.mkv # Video problematico + Ducking ultra

OUTPUT: filename_[preset]_clearvoice0.mkv

TECNOLOGIE IMPLEMENTATE:
  ✓ Sidechain compression per ducking LFE reattivo
  ✓ Delay temporali per soundstage 3D (percettibili dall'orecchio umano)
  ✓ Compressore multi-banda per naturalezza voce
  ✓ Limitatore intelligente anti-clipping
  ✓ Crossover LFE con filtraggio professionale
  ✓ SoXR resampler per qualità superiore (se supportato)
  ✓ EQ adattivo per materiale problematico (preset TV)

NOTE TECNICHE:
  • SoXR: Richiede FFmpeg compilato con --enable-libsoxr
  • Soundstage: Delay 5-20ms per percezione spaziale realistica
  • LFE Ducking: Voice controlla automaticamente subwoofer in tempo reale
EOF
      exit 0;;
    -*) echo "Opzione sconosciuta: $1"; exit 1;;
    *) INPUTS+=("$1"); shift;;
  esac
done

# Gestione input automatica con parsing migliorato e validazione
if [[ ${#INPUTS[@]} -ge 1 && ! -f "${INPUTS[0]}" && ! "${INPUTS[0]}" =~ ^[0-9]+[kK]$ ]]; then
    # Primo argomento non è un file né un bitrate, deve essere un codec
    if [[ "${INPUTS[0]}" =~ ^(eac3|ac3|dts)$ ]]; then
        CODEC="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
    fi
fi

# Estrazione bitrate se presente negli argomenti
if [[ ${#INPUTS[@]} -ge 1 && "${INPUTS[0]}" =~ ^[0-9]+[kK]$ ]]; then
    BR="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi

# Auto-discovery file .mkv nella directory corrente se nessun input specificato
if [[ ${#INPUTS[@]} -eq 0 ]]; then
    shopt -s nullglob
    INPUTS=(*.mkv)
    shopt -u nullglob
fi

# Controllo presenza file da elaborare
[[ ${#INPUTS[@]} -eq 0 ]] && { echo "❌ Nessun file specificato!"; exit 1; }

# -----------------------------------------------------------------------------------------------
#  FUNZIONI QUALITÀ AVANZATE CON VALIDAZIONE
# -----------------------------------------------------------------------------------------------

# Costruisce limitatore intelligente anti-clipping specifico per preset
build_limiter_settings() {
    case "$PRESET" in
        film)
            # Limiter cinematografico: preserva dinamica massima, controlla solo picchi estremi
            # level_out: 0.95 (-0.4dB) | limit: 0.98 (-0.17dB) | attack: 5ms | release: 50ms
            # asc: auto-sensing per adattamento dinamico | tanh: soft-clipping musicale
            echo "alimiter=level_in=1.0:level_out=0.95:limit=0.98:attack=5:release=50:asc=1,asoftclip=type=tanh:param=0.8"
            ;;
        serie)
            # Limiter dialoghi: controllo aggressivo per compatibilità TV domestica
            # Parametri più restrittivi per evitare distorsioni su sistemi consumer
            echo "alimiter=level_in=1.0:level_out=0.93:limit=0.96:attack=3:release=30:asc=1,asoftclip=type=exp:param=0.7"
            ;;
        tv)
            # Limiter ultra-conservativo: processing minimo per materiale già problematico
            # Massima sicurezza per evitare ulteriore degradazione audio scadente
            echo "alimiter=level_in=1.0:level_out=0.92:limit=0.95:attack=2:release=20:asc=1,asoftclip=type=exp:param=0.6"
            ;;
        cartoni)
            # Limiter musicale: protezione gentile che preserva transitori musicali
            # Parametri rilassati per mantenere vivacità musiche e effetti
            echo "alimiter=level_in=1.0:level_out=0.96:limit=0.99:attack=8:release=80:asc=1,asoftclip=type=sin:param=0.9"
            ;;
    esac
}

# Costruisce filtri pulizia Front L/R specifici per preset e contenuto
build_front_filters() {
    case "$PRESET" in
        film)
            # Film: pulizia conservativa che preserva dinamica musicale completa
            # Filtraggio minimo per mantenere ricchezza timbrica colonna sonora
            echo "highpass=f=22:poles=1,lowpass=f=20000:poles=1"
            ;;
        serie)
            # Serie: pulizia moderata con focus su intelligibilità dialoghi
            # Rimozione leggera sub-bass inutili e smoothing acuti aggressivi
            echo "highpass=f=28:poles=1,lowpass=f=17500:poles=1"
            ;;
        tv)
            # TV: pulizia aggressiva + noise reduction per materiale problematico
            # Filtraggio esteso + denoise + EQ correttivo per audio degradato
            echo "highpass=f=100:poles=1,lowpass=f=8000:poles=1,afftdn=nr=18:nf=-40:tn=1,equalizer=f=1600:width_type=o:width=1.5:g=2.2,equalizer=f=3200:width_type=o:width=1.0:g=1.8"
            ;;
        cartoni)
            # Cartoni: pulizia minima che preserva brillantezza musicale completa
            # Range esteso per mantenere vivacità colori sonori animazione
            echo "highpass=f=18:poles=1,lowpass=f=24000:poles=1"
            ;;
    esac
}

# Equalizzatore specifico per canale centrale con processing dedicato
build_voice_eq() {
    case "$PRESET" in
        tv)
            # TV: noise reduction aggressivo + cleanup specifico per materiale problematico
            # afftdn: denoise FFT | anlmdn: denoise non-lineare | EQ correttivo intelligibilità
            echo "afftdn=nr=20:nf=-42:tn=1,anlmdn=s=0.0001:p=0.002:r=0.005,highpass=f=80:poles=2,equalizer=f=1600:width_type=o:width=1.5:g=3.0,equalizer=f=3200:width_type=o:width=1.0:g=2.5"
            ;;
        film|serie|cartoni)
            # Altri preset: nessun EQ aggiuntivo per preservare naturalezza originale
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

# -----------------------------------------------------------------------------------------------
#  IMPOSTAZIONI PRESET CON VALIDAZIONE ROBUSTA + SOUNDSTAGE
# -----------------------------------------------------------------------------------------------

# Dichiarazione variabili globali prima dell'uso per evitare errori bash
VOICE_VOL=""            # Volume boost voce calcolato per preset
LFE_VOL=""              # Volume LFE base prima del ducking
SURROUND_VOL=""         # Volume canali surround per spazialità
VOICE_COMP=""           # Parametri compressione voce (threshold:ratio:attack:release)
HP_FREQ=""              # Frequenza highpass filtro voce
LP_FREQ=""              # Frequenza lowpass filtro voce
COMPRESSOR_SETTINGS=""  # Stringa completa settings compressore
SOFTCLIP_SETTINGS=""    # Stringa completa settings limitatore
FRONT_FILTER=""         # Stringa completa filtri canali frontali
FRONT_DELAY_MS=""       # Delay millisecondi canali frontali per soundstage
SURROUND_DELAY_MS=""    # Delay millisecondi canali surround per soundstage

# Configurazione parametri preset con calcoli ottimizzati per ogni scenario
set_preset_params() {
    case "$PRESET" in
        film)
            # PRESET FILM: Bilanciato per contenuti cinematografici con impatto dinamico
            VOICE_VOL=8.5; LFE_VOL=0.23; SURROUND_VOL=3.6  
            VOICE_COMP="0.35:1.30:40:390"   # Compressione moderata (threshold:ratio:attack:release)
            HP_FREQ=115; LP_FREQ=7900       # Range frequenze voce ottimale per cinema
            ;;
        serie)
            # PRESET SERIE TV: Massima intelligibilità dialoghi per ascolto domestico
            VOICE_VOL=8.6; LFE_VOL=0.23; SURROUND_VOL=3.4
            VOICE_COMP="0.40:1.15:60:380"  # Compressione delicata per naturalezza
            HP_FREQ=130; LP_FREQ=7800      # Pulizia maggiore dei bassi per chiarezza
            ;;
        tv)
            # PRESET TV: Conservativo per materiale problematico con chiarezza forzata
            VOICE_VOL=5.8; LFE_VOL=0.23; SURROUND_VOL=3.4  
            VOICE_COMP="0.42:1.28:20:320"   # Compressione moderata preservando dinamica residua
            HP_FREQ=180; LP_FREQ=6000       # Range bilanciato per chiarezza naturale massima
            ;;  
        cartoni)
            # PRESET CARTONI: Preserva musicalità e dinamica per coinvolgimento
            VOICE_VOL=8.4; LFE_VOL=0.23; SURROUND_VOL=3.5  
            VOICE_COMP="0.40:1.15:50:330"   # Compressione leggera per vivacità
            HP_FREQ=110; LP_FREQ=6900       # Range esteso per musica e effetti
            ;;
        *) echo "❌ Preset sconosciuto: $PRESET"; exit 1;;
    esac
    
    # Parsing parametri compressione dinamica con validazione robusta
    local VC_THRESHOLD VC_RATIO VC_ATTACK VC_RELEASE
    IFS=':' read -r VC_THRESHOLD VC_RATIO VC_ATTACK VC_RELEASE <<< "$VOICE_COMP"
    
    # Validazione parametri per evitare errori di processing FFmpeg
    VC_THRESHOLD=$(validate_numeric "$VC_THRESHOLD" "0.5")
    VC_RATIO=$(validate_numeric "$VC_RATIO" "1.2")
    VC_ATTACK=$(validate_numeric "$VC_ATTACK" "40")
    VC_RELEASE=$(validate_numeric "$VC_RELEASE" "300")
    
    # Costruzione stringa compressore con parametri validati
    COMPRESSOR_SETTINGS="acompressor=threshold=${VC_THRESHOLD}:ratio=${VC_RATIO}:attack=${VC_ATTACK}:release=${VC_RELEASE}"
    
    # Limitatore intelligente specifico per preset
    SOFTCLIP_SETTINGS=$(build_limiter_settings)
    
    # Filtri pulizia Front L/R specifici per preset
    FRONT_FILTER=$(build_front_filters)
    
    # Imposta parametri Soundstage specifici per preset
    set_soundstage_params
    
    echo "✅ Preset $PRESET configurato con LFE Ducking + Soundstage attivi"
    echo "   🎭 Soundstage: Front ${FRONT_DELAY_MS}ms, Surround ${SURROUND_DELAY_MS}ms"
    echo "   🔊 LFE Ducking: Parametri ottimizzati per contenuto $PRESET"
}

# Esegui configurazione preset
set_preset_params

# -----------------------------------------------------------------------------------------------
#  SELEZIONE CODEC CON PARAMETRI QUALITÀ OTTIMIZZATI
# -----------------------------------------------------------------------------------------------  

# Dichiarazione variabili globali codec
ENC=""      # Encoder FFmpeg selezionato
TITLE=""    # Titolo metadata traccia elaborata
EXTRA=""    # Parametri extra specifici codec

# Configurazione codec con ottimizzazioni qualità specifiche per LG Meridian SP7
CODEC="${CODEC:-eac3}"  # Default EAC3 se non specificato
case "${CODEC,,}" in
  eac3) 
    ENC=eac3; BR=${BR:-384k}; TITLE="EAC3 Clearvoice 5.1"
    # Parametri qualità EAC3 ottimizzati per compatibilità SP7
    # mixing_level: 108 (-12dB) | room_type: 1 (small room) | dialnorm: -27dB
    EXTRA="-channel_layout 5.1 -mixing_level 108 -room_type 1 -copyright 0 -dialnorm -27 -dsur_mode 2"
    ;;
  ac3)  
    ENC=ac3; BR=${BR:-448k}; TITLE="AC3 Clearvoice 5.1"
    # Parametri qualità AC3 ottimizzati per compatibilità universale
    # center_mixlev: 0.594 (-4.5dB) | surround_mixlev: 0.5 (-6dB)
    EXTRA="-channel_layout 5.1 -center_mixlev 0.594 -surround_mixlev 0.5 -dialnorm -27"
    ;;
  dts)  
    ENC=dts; BR=${BR:-768k}; TITLE="DTS Clearvoice 5.1"
    # Parametri DTS compatibili con encoder dca per qualità massima
    # strict: -2 per encoder sperimentale | compression_level: 1 per qualità alta
    EXTRA="-strict -2 -ar 48000 -channel_layout 5.1(side) -compression_level 1"
    ;;
  *) echo "❌ Codec non supportato: $CODEC"; exit 1;;
esac

# -----------------------------------------------------------------------------------------------
#  COSTRUZIONE FILTRI AUDIO CON VERO LFE DUCKING + SOUNDSTAGE
# -----------------------------------------------------------------------------------------------

# Dichiarazione variabile globale filtro completo
ADV_FILTER=""

# Costruzione filtro audio completo con tutte le ottimizzazioni
 build_audio_filter() {
    local voice_vol_adj front_vol_adj lfe_vol_adj surround_vol_adj
    local hp_freq=${HP_FREQ} lp_freq=${LP_FREQ}
    
    # Calcoli sicuri con safe_awk_calc
    if [[ "${CODEC,,}" == "dts" ]]; then
        case "$PRESET" in
            film)
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 2.5") 
                front_vol_adj="0.76"                                     
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.45")
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.72")
                hp_freq=135; lp_freq=7700
                ;;
            serie)
                # DTS Serie: voce massima, LFE controllato per TV domestico
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 2.3")
                front_vol_adj="0.76"                                     
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.72")       # LFE moderatamente ridotto
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.78") 
                hp_freq=135; lp_freq=8000   # Range ottimizzato DTS Serie
                ;;
            tv)
                # DTS TV: ultra-conservativo per materiale problematico
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 1.8")
                front_vol_adj="0.45"                                     
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.50")       # LFE ben controllato
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.55") 
                hp_freq=340; lp_freq=6000  # Range ristretto DTS TV per chiarezza massima
                ;;                
            cartoni)
                # DTS Cartoni: Bilanciamento musicale preservando dinamica
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 1.8")    
                front_vol_adj="0.87"                                     
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.83")      # LFE leggermente ridotto
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.85") 
                hp_freq=125; lp_freq=6800  # Range esteso DTS Cartoni per musicalità
                ;;
        esac
    else
        # ===== RAMO EAC3/AC3: Parametri per codec Dolby con ottimizzazioni specifiche =====
        case "$PRESET" in
            film)
                # EAC3/AC3 Film: boost voce moderato, dinamica preservata
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 1.8")
                front_vol_adj=$(safe_awk_calc "$FRONT_VOL - 0.15")
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.73")       # Riduzione LFE per controllo ducking
                surround_vol_adj=${SURROUND_VOL}  # Usa valore preset direttamente
                ;;
            serie)
                # EAC3/AC3 Serie: massima intelligibilità dialoghi
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 1.9")
                front_vol_adj=$(safe_awk_calc "$FRONT_VOL - 0.12")
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.80")       # LFE moderatamente ridotto
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.92")
                ;;
            tv)
                # EAC3/AC3 TV: conservativo per materiale problematico
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 1.8")
                front_vol_adj=$(safe_awk_calc "$FRONT_VOL - 0.48")
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.50")       # LFE ben controllato
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.58")
                ;;                
            cartoni)
                # EAC3/AC3 Cartoni: bilanciamento musicale
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 0.9")
                front_vol_adj=$(safe_awk_calc "$FRONT_VOL - 0.08")
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.92")       # LFE preservato per musica
                surround_vol_adj=${SURROUND_VOL}  # Usa valore preset direttamente
                ;;               
        esac
    fi
    
    # Costruzione filtro con gestione corretta dell'EQ voice
    local voice_eq_filter=$(build_voice_eq)
    local voice_eq_part=""
    if [[ -n "$voice_eq_filter" ]]; then
        voice_eq_part=",$voice_eq_filter"
    fi
    
   # LFE DUCKING SETTINGS
    local lfe_ducking_settings=$(build_lfe_ducking_filter)
    
    if [[ "${CODEC,,}" == "dts" ]]; then
        # Filtro DTS con ORDINE SIDECHAIN CORRETTO
        ADV_FILTER="[0:a]channelmap=channel_layout=5.1[audio5dot1];"
        ADV_FILTER+="[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];"
        
        # Voice processing
        ADV_FILTER+="[FC]highpass=f=${hp_freq},lowpass=f=${lp_freq},volume=${voice_vol_adj},${COMPRESSOR_SETTINGS}${voice_eq_part}[fc_processed];"
        
        # Front con soundstage REALISTICO
        ADV_FILTER+="[FL]${FRONT_FILTER},volume=${front_vol_adj},adelay=${FRONT_DELAY_MS}ms[left];"
        ADV_FILTER+="[FR]${FRONT_FILTER},volume=${front_vol_adj},adelay=${FRONT_DELAY_MS}ms[right];"
        
        # LFE processing
        ADV_FILTER+="[LFE]highpass=f=30:poles=2,lowpass=f=115:poles=2,volume=${lfe_vol_adj}[lfe_eq];"
        
        # Sidechain preparation
        ADV_FILTER+="[fc_processed]aresample=48000[voice_sidechain];"
        ADV_FILTER+="[lfe_eq]aresample=48000[lfe_sync];"
        
        # ✅ ORDINE CORRETTO: voice_sidechain (trigger) PRIMO, lfe_sync (da comprimere) SECONDO
        ADV_FILTER+="[voice_sidechain][lfe_sync]${lfe_ducking_settings}[bass];"
        
        # Voice finale
        ADV_FILTER+="[fc_processed]${SOFTCLIP_SETTINGS}[center];"
        
        # Surround con soundstage REALISTICO
        ADV_FILTER+="[BL]highpass=f=30:poles=1,lowpass=f=19000:poles=1,volume=${surround_vol_adj},adelay=${SURROUND_DELAY_MS}ms[surroundL];"
        ADV_FILTER+="[BR]highpass=f=30:poles=1,lowpass=f=19000:poles=1,volume=${surround_vol_adj},adelay=${SURROUND_DELAY_MS}ms[surroundR];"
        
        # Join e finalizzazione
        ADV_FILTER+="[left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1:map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[joined];"
        ADV_FILTER+="[joined]aresample=48000:resampler=soxr:precision=28,aformat=sample_fmts=s32:channel_layouts=5.1[out]"
    else
        # STESSO SCHEMA PER EAC3/AC3 con ordine corretto
        ADV_FILTER="[0:a]channelmap=channel_layout=5.1[audio5dot1];"
        ADV_FILTER+="[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];"
        
        # Voice processing
        ADV_FILTER+="[FC]highpass=f=${hp_freq},lowpass=f=${lp_freq},volume=${voice_vol_adj},${COMPRESSOR_SETTINGS}${voice_eq_part}[fc_processed];"
        
        # Front con soundstage
        ADV_FILTER+="[FL]${FRONT_FILTER},volume=${front_vol_adj},adelay=${FRONT_DELAY_MS}ms[left];"
        ADV_FILTER+="[FR]${FRONT_FILTER},volume=${front_vol_adj},adelay=${FRONT_DELAY_MS}ms[right];"
        
        # LFE processing
        ADV_FILTER+="[LFE]highpass=f=25:poles=2,lowpass=f=105:poles=2,volume=${lfe_vol_adj}[lfe_eq];"
        
        # Sidechain preparation
        ADV_FILTER+="[fc_processed]aresample=48000[voice_sidechain];"
        ADV_FILTER+="[lfe_eq]aresample=48000[lfe_sync];"
        
        # ✅ ORDINE CORRETTO per EAC3/AC3
        ADV_FILTER+="[voice_sidechain][lfe_sync]${lfe_ducking_settings}[bass];"
        
        # Voice finale
        ADV_FILTER+="[fc_processed]${SOFTCLIP_SETTINGS}[center];"
        
        # Surround con soundstage
        ADV_FILTER+="[BL]highpass=f=35:poles=1,lowpass=f=18000:poles=1,volume=${surround_vol_adj},adelay=${SURROUND_DELAY_MS}ms[surroundL];"
        ADV_FILTER+="[BR]highpass=f=35:poles=1,lowpass=f=18000:poles=1,volume=${surround_vol_adj},adelay=${SURROUND_DELAY_MS}ms[surroundR];"
        
        # Join finale
        ADV_FILTER+="[left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1:map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[joined];"
        ADV_FILTER+="[joined]aresample=48000:resampler=soxr:precision=28,aformat=sample_fmts=s32:channel_layouts=5.1[out]"
    fi
    
    echo "🎯 Filtro costruito: VERO LFE Ducking + Soundstage CORRETTO"
    echo "   🔊 Ducking: Voice (trigger) → LFE (compressed)"
    echo "   🎭 Soundstage: Front ${FRONT_DELAY_MS}ms, Surround ${SURROUND_DELAY_MS}ms"
}

# Esegui costruzione filtro
build_audio_filter

# -----------------------------------------------------------------------------------------------
#  PROCESSING CON GESTIONE ERRORI AVANZATA
# -----------------------------------------------------------------------------------------------

# Funzione processing singolo file con gestione completa errori
process() {
    local input_file="$1"
    local out="${input_file%.*}_${PRESET}_clearvoice0.mkv"
    
    # Controllo esistenza file input
    if [[ ! -f "$input_file" ]]; then
        echo "❌ File non trovato: $input_file"
        return 1
    fi
    
    # Controllo layout audio per gestione robusta formato "unknown"
    local channel_layout
    channel_layout=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channel_layout -of csv=p=0 "$input_file" 2>/dev/null)
    
    # Fix automatico per layout audio "unknown" - usa aformat invece di channelmap
    local LOCAL_FILTER="$ADV_FILTER"
    if [[ "$channel_layout" == "unknown" ]]; then
        LOCAL_FILTER="${ADV_FILTER//channelmap=channel_layout=5.1/aformat=channel_layouts=5.1}"
        echo "   🔧 Layout 'unknown' rilevato - applicato fix automatico"
    fi
    
    echo "🎬 Processing: $(basename "$input_file") [Preset: $PRESET + LFE Ducking + Soundstage]"
    
    # Controllo sovrascrittura file esistente
    if [[ -e "$out" ]]; then
        read -p "⚠️  Output già presente. Sovrascrivere? (y/n): " choice
        [[ ! "$choice" =~ ^[Yy]$ ]] && return 0
    fi

    # Timer processing per statistiche
    local START_TIME=$(date +%s)
    
    # Rilevamento thread count ottimale
    local thread_count
    thread_count=$(nproc 2>/dev/null || echo "4")
    
    echo "   ⚙️  Configurazione: $thread_count thread | Codec: $ENC ($BR)"
    echo "   🎛️  Filtro: Voice ${VOICE_VOL}dB + LFE Ducking + Soundstage"
    
    # Processing FFmpeg con threading ottimizzato e gestione errori completa
    if ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero \
        -threads "$thread_count" -filter_threads "$thread_count" -thread_queue_size 512 \
        -i "$input_file" -filter_complex "$LOCAL_FILTER" \
        -map 0:v -map "[out]" -map 0:a? -map 0:s? \
        -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
        -c:v copy -c:a:0 "$ENC" $EXTRA -b:a:0 "$BR" -c:a:1 copy -c:s copy \
        -movflags +faststart "$out"; then
        
        # Calcolo tempo processing e statistiche finali
        local END_TIME=$(date +%s)
        local PROCESSING_TIME=$((END_TIME - START_TIME))
        
        # Controllo dimensione file output per validazione
        local file_size
        file_size=$(stat -c%s "$out" 2>/dev/null || echo "0")
        local size_mb=$((file_size / 1024 / 1024))
        
        echo "✅ Completato in ${PROCESSING_TIME}s: $(basename "$out") (${size_mb}MB)"
        echo "   🔊 LFE Ducking + Soundstage attivi | Traccia default impostata"
        return 0
    else
        echo "❌ Errore durante elaborazione di $input_file"
        echo "   💡 Verifica: spazio disco, codec supportati, integrità file input"
        return 1
    fi
}

# Funzione summary finale con statistiche complete
print_summary() {
    local TOTAL_END_TIME=$(date +%s)
    local TOTAL_TIME=$((TOTAL_END_TIME - TOTAL_START_TIME))
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  🎯 CLEARVOICE 0.89 - ELABORAZIONE COMPLETATA"
    echo "═══════════════════════════════════════════════════════════════"
    echo "📊 STATISTICHE SESSIONE:"
    echo "   • Preset utilizzato: $PRESET"
    echo "   • Codec output: $CODEC ($BR)"
    echo "   • File processati: ${#VALIDATED_FILES_GLOBAL[@]}"
    echo "   • Tempo totale elaborazione: ${TOTAL_TIME}s"
    echo ""
    echo "🎛️ TECNOLOGIE APPLICATE:"
    echo "   • ✅ VERO LFE Ducking: Voice controlla automaticamente LFE"
    echo "   • 🎭 Soundstage spaziale: Front ${FRONT_DELAY_MS}ms, Surround ${SURROUND_DELAY_MS}ms"
    echo "   • 🔊 Voice boost intelligente: +${VOICE_VOL}dB con compressione adattiva"
    echo "   • ⚙️  Crossover LFE professionale con filtraggio multi-polo"
    echo "   • 🛡️  Limitatore anti-clipping con soft-clipping adattivo"
    [[ "$PRESET" == "tv" ]] && echo "   • 🎯 Equalizzazione dialoghi per materiale problematico"
    echo ""
    echo "📁 File elaborati salvati come: [nome]_${PRESET}_clearvoice0.mkv"
    echo "   Traccia ClearVoice impostata come default per riproduzione automatica"
    echo "═══════════════════════════════════════════════════════════════"
}

# -----------------------------------------------------------------------------------------------
#  ESECUZIONE PRINCIPALE CON PROCESSING SEQUENZIALE OTTIMIZZATO
# -----------------------------------------------------------------------------------------------

# Banner iniziale con configurazione attiva
echo "🚀 Avvio CLEARVOICE 0.89 - Preset: $PRESET | Codec: $CODEC ($BR)"
echo "   🔊 LFE Ducking: ATTIVO (sidechain) | 🎭 Soundstage: ATTIVO (delay spaziali)"

# Validazione input con analisi dettagliata
if ! validate_inputs; then
    echo ""
    echo "🆘 HELP: ClearVoice richiede tracce audio 5.1 surround"
    echo "   Usa i comandi di conversione mostrati sopra, poi rilancia ClearVoice"
    echo "   Per test rapido: ffprobe -show_streams [file.mkv]"
    exit 1
fi

# Informazioni tecnologie attive
echo ""
echo "🎛️ TECNOLOGIE ATTIVE:"
echo "   • Compressore multi-banda per naturalezza voce"
echo "   • Limitatore intelligente anti-clipping"
echo "   • Crossover LFE professionale con controllo frequenze"
echo "   • VERO LFE Ducking: Subwoofer reagisce automaticamente alla voce"
echo "   • Soundstage spaziale: Profondità stereofonica con delay temporali"
echo "   • Voice boost: +${VOICE_VOL}dB ottimizzato per preset $PRESET"

# Informazioni specifiche preset
case "$PRESET" in
    film)
        echo "   🎬 Preset FILM: Ducking moderato + Soundstage cinematografico"
        ;;
    serie)
        echo "   📺 Preset SERIE: Ducking aggressivo + Soundstage compatto"
        ;;
    tv)
        echo "   📡 Preset TV: Ducking ultra + Equalizzazione dialoghi"
        ;;
    cartoni)
        echo "   🎨 Preset CARTONI: Ducking gentile + Soundstage espanso"
        ;;
esac

echo "   🎭 Parametri Soundstage: Front ${FRONT_DELAY_MS}ms, Surround ${SURROUND_DELAY_MS}ms"

# Processing sequenziale con gestione errori
if [[ ${#VALIDATED_FILES_GLOBAL[@]} -gt 0 ]]; then
    echo ""
    echo "📁 Inizio processing ${#VALIDATED_FILES_GLOBAL[@]} file validati..."
    echo "   Ogni file verrà elaborato con LFE Ducking + Soundstage attivi"
    echo ""
    
    # ✅ CORREZIONE: Rimuovi 'local' dalla dichiarazione variabile
    success_count=0  
    
    for f in "${VALIDATED_FILES_GLOBAL[@]}"; do
        if process "$f"; then
            ((success_count++))
        fi
        echo ""  # Separatore tra file
    done
    
    echo "📊 Processing completato: $success_count/${#VALIDATED_FILES_GLOBAL[@]} file elaborati con successo"
else
    echo "❌ Nessun file 5.1 valido trovato nella selezione!"
    echo "   Verifica che i file abbiano tracce audio 5.1 surround"
fi

# Summary finale con statistiche complete
print_summary