# CLEARVOICE 0.76 🎧

**Script avanzato per ottimizzazione audio 5.1 testato su sistemi LG Meridian SP7**

> **Autore:** Sandro "D@mocle77" Sabbioni  
> **Versione:** 0.76  
> **Testato su:** LG SP7 5.1.2, Windows 11, ffmpeg 7.x

---

## 🎯 Panoramica

CLEARVOICE 0.76 è uno script Bash avanzato progettato per risolvere i problemi di intelligibilità dei dialoghi nei contenuti 5.1, con particolare focus sui sistemi audio LG Meridian SP7. Lo script applica elaborazioni audio sofisticate per migliorare la chiarezza vocale senza compromettere la qualità complessiva del mix audio.

### ✨ Caratteristiche Principali

- **🎬 3 Preset Specializzati:** Film, Serie TV, Cartoni Animati
- **🔧 Processing Multi-Canale:** Ottimizzazione individuale di ogni canale 5.1
- **🚀 Elaborazione Parallela:** 2 file contemporaneamente per serie TV
- **🎛️ Codec Multipli:** EAC3, AC3, DTS con parametri ottimizzati
- **🔊 Controllo LFE Anti-Boom:** Riduzione calibrata del subwoofer
- **🎚️ Compressione Intelligente:** Multi-banda per naturalezza

---

## 📋 Requisiti di Sistema

### Dipendenze Richieste
- **ffmpeg** 7.0+ (con supporto hardware acceleration)
- **awk** (GNU awk raccomandato)
- **bash** 4.0+

### Sistemi Operativi Supportati
- ✅ Linux (Ubuntu, RHEL)
- ✅ Windows (WSL, GitBash)

---

## 🚀 Installazione e Configurazione

### Download Script
```bash
# Clone del repository (se disponibile)
git clone https://github.com/Damocle77/Clearvoice_5.1/
cd clearvoice076

# Oppure download diretto
wget https://github.com/Damocle77/Clearvoice_5.1/clearvoice076_preset.sh
chmod +x clearvoice076_preset.sh
```

### Verifica Installazione
```bash
./clearvoice076_preset.sh --help
```

### Test Rapido
```bash
# Test con file di esempio
./clearvoice076_preset.sh --serie esempio.mkv
```

---

## 📖 Guida all'Uso

### Sintassi Base
```bash
./clearvoice076_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
```

### 🎭 Preset Disponibili

| Preset | Descrizione | Parametri Chiave | Ideale Per |
|--------|-------------|-------------------|------------|
| `--film` | Cinema/Action bilanciato | VOICE: 8.5, LFE: -17% | Film d'azione, thriller, drammi |
| `--serie` | Dialoghi TV ottimizzati | VOICE: 8.6, LFE: -20% | Serie TV, documentari, dialoghi difficili |
| `--cartoni` | Preserva musicalità | VOICE: 8.2, LFE: -8% | Animazione, anime, colonne sonore |

### 🎵 Codec Supportati

| Codec | Bitrate Default | Qualità | Raccomandato Per |
|-------|----------------|---------|------------------|
| `eac3` | 384k | Ottima | Serie TV, streaming |
| `ac3` | 640k | Buona | Compatibilità universale |
| `dts` | 768k | Premium | Film Blu-ray, qualità audiophile |

---

## 💡 Esempi Pratici

### Elaborazione Singolo File
```bash
# Serie TV con preset ottimizzato
./clearvoice076_preset.sh --serie eac3 384k "Serie_S01E01.mkv"

# Film d'azione alta qualità
./clearvoice076_preset.sh --film dts 756k "Film.mkv"

# Cartone animato bilanciato
./clearvoice076_preset.sh --cartoni ac3 768k "Cartoon.mkv"
```

### Elaborazione Batch
```bash
# Tutti i file .mkv nella directory corrente
./clearvoice076_preset.sh --serie

# File multipli specifici
./clearvoice076_preset.sh --film dts 768k *.mkv

# Pattern di file specifico
./clearvoice076_preset.sh --cartoni ac3 448k "cartoon*.mkv"
```

### Elaborazione Cartelle (con Processing Parallelo)
```bash
# Cartella serie TV - 2 file contemporaneamente
./clearvoice076_preset.sh --serie /path/to/series/Season1/

# Cartella film
./clearvoice076_preset.sh --film dts 768k /movies/action/
```

### Utilizzo Avanzato
```bash
# Auto-configurazione (preset: serie, codec: eac3, bitrate: 384k)
./clearvoice076_preset.sh

# Serie TV con codec DTS premium
./clearvoice076_preset.sh --serie dts 768k /series/

# Film con codec compatibilità universale
./clearvoice076_preset.sh --film ac3 448k /movies/
```

---

## ⚙️ Elaborazioni Audio Avanzate

### 🎚️ Compressore Multi-Banda
- **Film:** Preserva dinamica cinematografica
- **Serie:** Controllo range dinamico per TV
- **Cartoni:** Bilanciamento musicale

### 🔊 Limitatore Intelligente Anti-Clipping
```
Film:    Lookahead 5ms, Release 50ms (preserva dinamica)
Serie:   Lookahead 3ms, Release 30ms (controllo aggressivo)
Cartoni: Lookahead 8ms, Release 80ms (protezione gentile)
```

### 📊 Crossover LFE Precisione SP7
- **EAC3/AC3:** 25-105Hz con poles controllati
- **DTS:** 30-115Hz con slopes ottimizzati
- **Riduzione Anti-Boom:** 8-20% secondo preset

### 🎛️ Filtri Pulizia Front L/R
| Preset | Anti-Rumble | Lowpass | Caratteristica |
|--------|-------------|---------|----------------|
| Film | 22Hz | 20kHz | Conservativo |
| Serie | 28Hz | 18kHz | Focus dialoghi |
| Cartoni | 18Hz | 24kHz | Brillantezza musicale |

---

## 🔧 Configurazioni Avanzate

### Threading e Performance
```bash
# Il script ottimizza automaticamente:
# - Thread count basato su CPU cores
# - Queue size per streaming fluido
# - Bilanciamento risorse per modalità parallela
```

### Accelerazione Hardware
```bash
# Supporto automatico per:
# - NVIDIA NVENC
# - Intel QuickSync
# - AMD VCE
```

### Gestione Memoria
```bash
# Validazioni automatiche:
# - Spazio disco (2x dimensione file)
# - Verifica integrità audio 5.1
# - Controllo layout "unknown"
```

---

## 📁 Struttura Output

### Nome File Output
```
input_file.mkv → input_file_[preset]_clearvoice0.mkv
```

### Esempi
```
Breaking_Bad_S01E01.mkv → Breaking_Bad_S01E01_serie_clearvoice0.mkv
Avengers_Endgame.mkv   → Avengers_Endgame_film_clearvoice0.mkv
Spirited_Away.mkv      → Spirited_Away_cartoni_clearvoice0.mkv
```

### Metadata Ottimizzati
- **Lingua:** ITA (predefinita)
- **Titolo:** "[CODEC] Clearvoice 5.1"
- **Traccia Default:** Prima traccia audio
- **Preservazione:** Video, sottotitoli, tracce audio aggiuntive

---

## 🚀 Modalità Processing Parallelo

### Attivazione Automatica
La modalità parallela si attiva automaticamente per:
- **Preset:** `--serie` 
- **Input:** Cartelle (non file singoli)
- **Processi:** 2 contemporaneamente

### Vantaggi
- ⚡ **Velocità:** Riduzione ~40% tempo totale
- 🔄 **Efficienza:** Bilanciamento automatico CPU
- 💾 **Memoria:** Thread ridotti per evitare sovraccarico
- ✅ **Affidabilità:** Skip automatico file esistenti

### Esempio Pratico
```bash
# Cartella con 10 episodi - Processing parallelo automatico
./clearvoice076_preset.sh --serie /series/Breaking_Bad_S01/

# Output esempio:
# 🔄 Modalità parallela attivata: elaborazione 2 file contemporaneamente
# 🎬 Processing: S01E01.mkv [PARALLEL]
# 🎬 Processing: S01E02.mkv [PARALLEL]
# ✅ Completato: S01E01_serie_clearvoice0.mkv
# 🎬 Processing: S01E03.mkv [PARALLEL]
```

---

## 📊 Statistiche e Monitoraggio

### Output di Esempio
```
═══════════════════════════════════════════════════════════════════════════════
  🎯 CLEARVOICE 0.76 - ELABORAZIONE COMPLETATA
═══════════════════════════════════════════════════════════════════════════════

📊 STATISTICHE ELABORAZIONE:
   • Preset utilizzato: serie
   • Codec output: eac3 (384k)
   • File processati con successo: 8
   • File falliti: 0
   • Tempo totale: 2847s
   • Modalità parallela: 2 processi contemporaneamente
   • Tempo medio per file: 356s

🎧 OTTIMIZZAZIONI APPLICATE:
   • Compressore dialoghi per massima intelligibilità
   • LFE ridotto -20% per contenuti TV
   • Anti-aliasing surround per chiarezza
   • Filtri Front L/R: anti-rumble 28Hz, lowpass 18kHz
   • Processing parallelo per velocità massima
```

---

## 🎧 Consigli per l'Ascolto Ottimale

### Impostazioni LG SP7 Raccomandate
- **Sound Mode:** `Cinema` (preserva dinamica naturale)
- **AI Sound Pro:** `OFF` (evita appiattimento range dinamico)
- **Night Mode:** `OFF` (mantiene elaborazione script)
- **Bass Level:** `0` o `+1` (LFE già ottimizzato)

### Configurazione Ambiente
1. **Posizionamento:** Soundbar centrata, subwoofer angolo
2. **Calibrazione:** Room Correction attiva se disponibile
3. **Volume:** 70-80% per utilizzo normale
4. **Backup:** Sottotitoli per dialoghi molto difficili

### Verifica Qualità
```bash
# Analisi spettrale prima/dopo (opzionale)
ffprobe -f lavfi -i "amovie=input.mkv,asplit[out0][a];[a]showspectrum[out1]" -t 10

# Controllo dinamica range
ffmpeg -i input_film_clearvoice0.mkv -af "astats=metadata=1:reset=1" -f null -
```

---

## 🛠️ Risoluzione Problemi

### Errori Comuni

#### "Command not found: ffmpeg"
```bash
# Verifica installazione
which ffmpeg
ffmpeg -version

# Reinstallazione Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg
```

#### "No 5.1 audio track found"
```bash
# Verifica tracce audio
ffprobe -v quiet -show_streams input.mkv | grep -E "(channels|channel_layout)"

# Il file deve avere:
# channels=6
# channel_layout=5.1 (o unknown con 6 canali)
```

#### "Insufficient disk space"
```bash
# Verifica spazio
df -h .

# Regola: almeno 2x dimensione file input
# Esempio: file 4GB → servono 8GB liberi
```

#### Processing Lento
```bash
# Verifica accelerazione hardware
ffmpeg -hwaccels

# Se disponibile NVENC/QSV/VCE, verrà usato automaticamente
# Altrimenti: processing solo CPU (normale ma più lento)
```

### Debugging Avanzato

#### Modalità Verbose
```bash
# Modifica temporanea per debug
sed -i 's/-hide_banner/-v info/g' clearvoice076_preset.sh
```

#### Test Singolo Canale
```bash
# Estrazione canale centrale per test
ffmpeg -i input.mkv -af "channelmap=map=FC-mono" -t 30 test_center.wav
```

#### Verifica Filtri
```bash
# Test filtro voce isolato
ffmpeg -i input.mkv -af "highpass=f=120,lowpass=f=7600" -t 10 test_voice.wav
```

---

## 🔄 Aggiornamenti e Versioning

### Storia Versioni
- **v0.76:** Compressore multi-banda, limitatore intelligente, processing parallelo
- **v0.75:** Crossover LFE precisione, filtri Front L/R
- **v0.74:** Resampling SoxR, anti-aliasing surround
- **v0.73:** Encoding ottimizzato per codec, threading efficiente

### Aggiornamento Script
```bash
# Backup versione corrente
cp clearvoice076_preset.sh clearvoice076_preset.sh.backup

# Download nuova versione
wget https://[url]/clearvoice076_preset.sh
chmod +x clearvoice076_preset.sh

# Verifica versione
./clearvoice076_preset.sh --help | head -1
```

### Compatibilità Versioni
- **Output Files:** Compatibili tra versioni 0.7x
- **Preset:** Mantengono nomenclatura consistente
- **Metadata:** Standard preservati

---

## 🤝 Contributi e Community

### Segnalazione Bug
1. **Sistema:** OS, versione ffmpeg, hardware audio
2. **File:** Tipo input, codec, durata
3. **Errore:** Output completo, log ffmpeg
4. **Reproducibilità:** Step per replicare

### Suggerimenti Miglioramenti
- **Preset Aggiuntivi:** Nuovi casi d'uso
- **Codec Support:** Formati emergenti
- **Performance:** Ottimizzazioni specifiche hardware
- **Usabilità:** GUI, configurazioni semplificate

### Testing e Feedback
Il testing su diversi sistemi audio è sempre benvenuto:
- **Soundbar:** LG, Samsung, Sony, JBL
- **AVR:** Denon, Yamaha, Pioneer, Marantz  
- **Contenuti:** Film, serie, documentari, anime
- **Codec:** Diverse sorgenti e bitrate

---

## 📄 Licenza e Credits

### Licenza
Questo script è rilasciato sotto licenza open source. Utilizzabile liberamente per scopi personali e commerciali.

### Credits
- **Autore:** Sandro "D@mocle77" Sabbioni
- **Testing:** Community LG SP7 users
- **Ispirazione:** Necessità reali di miglioramento dialoghi audio
- **Tecnologie:** ffmpeg, SoxR, audio engineering best practices

### Disclaimer
Lo script è fornito "as-is" senza garanzie. L'autore non è responsabile per eventuali danni ai file o sistemi. Si raccomanda sempre di mantenere backup dei file originali.

---

## 📞 Supporto e Contatti

Per supporto, domande o feedback:
- **Issues:** Repository GitHub (se disponibile)
- **Email:** [contatto se pubblico]
- **Community:** Forum audio, Reddit r/hometheater
- **Documentation:** Questo README sempre aggiornato

---

**CLEARVOICE 0.76** - *Making dialogue crystal clear, one file at a time* 🎧✨