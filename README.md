# ClearVoice 5.1 🎧

**Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE**

[![Version](https://img.shields.io/badge/version-0.77-blue.svg)](https://github.com/Damocle77/Clearvoice_5.1/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2011%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](#installazione)
[![FFmpeg](https://img.shields.io/badge/ffmpeg-6.0%2B-orange.svg)](#requisiti)

> **Specificamente calibrato per sistemi LG Meridian SP7 5.1.2 e soundbar/AVR compatibili**

---

## 📖 Indice

- [Caratteristiche](#-caratteristiche)
- [Installazione](#-installazione)
- [Uso Rapido](#-uso-rapido)
- [Preset Disponibili](#-preset-disponibili)
- [Codec Supportati](#-codec-supportati)
- [Esempi Pratici](#-esempi-pratici)
- [Miglioramenti v0.77](#-miglioramenti-v077)
- [Requisiti Tecnici](#-requisiti-tecnici)
- [Troubleshooting](#-troubleshooting)
- [Contribuire](#-contribuire)
- [Licenza](#-licenza)

---

## ✨ Caratteristiche

### 🎯 **Ottimizzazioni Audio Avanzate**
- **Separazione e ottimizzazione individuale** di ogni canale 5.1 (FL/FR/FC/LFE/BL/BR)
- **Boost intelligente canale centrale (FC)** senza interferenze DSP Meridian
- **Controllo LFE anti-boom** con riduzione 8-20% calibrata per preset
- **Compressione dinamica multi-banda** per intelligibilità naturale
- **Limitatore intelligente anti-clipping** con lookahead adattivo

### 🔧 **Tecnologie Avanzate**
- **Crossover LFE precisione** con slopes controllati per SP7
- **Resampling SoxR qualità audiophile** con dithering triangular
- **Anti-aliasing surround** per canali posteriori cristallini
- **Filtri pulizia Front L/R** specifici per preset
- **Processing parallelo** (2 file contemporaneamente per serie TV)

### ⚡ **Performance e Compatibilità**
- **Accelerazione hardware GPU** quando disponibile
- **Threading ottimizzato** per CPU multi-core
- **Gestione robusta** file con layout audio "unknown"
- **Preservazione completa** video, tracce audio aggiuntive e sottotitoli
- **Validazione input avanzata** con analisi formati audio dettagliata

---

## 🚀 Installazione

### Windows 11 (Raccomandato)

#### 1. Installa FFmpeg con Winget
```powershell
# Apri PowerShell come amministratore
winget install ffmpeg
```

#### 2. Installa Git Bash
```powershell
winget install Git.Git
```

#### 3. Clona il repository
```bash
# Apri Git Bash
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
```

#### 4. Rendi eseguibile lo script
```bash
chmod +x clearvoice077_preset.sh
```

### Linux/macOS

#### Prerequisiti
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg git

# macOS (Homebrew)
brew install ffmpeg git

# Arch Linux
sudo pacman -S ffmpeg git
```

#### Installazione
```bash
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice077_preset.sh
```

---

## ⚡ Uso Rapido

### Sintassi Base
```bash
./clearvoice077_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
```

### Esempi Immediati
```bash
# Preset automatico (serie TV con EAC3 384k)
./clearvoice077_preset.sh *.mkv

# Serie TV ottimizzata
./clearvoice077_preset.sh --serie *.mkv

# Film alta qualità DTS
./clearvoice077_preset.sh --film dts 768k Film/

# Cartella con processing parallelo
./clearvoice077_preset.sh --serie /path/to/series/
```

---

## 🎛️ Preset Disponibili

### 🎬 `--film` - Cinema/Action
**Ottimizzato per contenuti cinematografici con action e dialoghi intensi**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.5 | Boost dialoghi bilanciato |
| **LFE_VOL** | 0.24 (-17%) | Controllo sub per SP7 |
| **SURROUND_VOL** | 3.6 | Effetti ambientali |
| **COMPRESSIONE** | 0.35:1.30:40:390 | Multi-banda cinematografica |

**Filtri Specifici:**
- **FC (Centro):** Highpass 115Hz, Lowpass 7900Hz
- **FL/FR (Front):** Anti-rumble 22Hz, Lowpass 20kHz  
- **BL/BR (Surround):** Anti-aliasing, pulizia fino 18kHz
- **LFE:** Crossover precision 30-115Hz

**Ideale per:** Film d'azione, thriller, drammi con effetti sonori intensi

---

### 📺 `--serie` - Serie TV/Dialoghi
**Massima intelligibilità per dialoghi sussurrati e problematici**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.6 | Boost dialoghi massimo |
| **LFE_VOL** | 0.24 (-20%) | Sub ridotto per TV |
| **SURROUND_VOL** | 3.4 | Ambientali controllati |
| **COMPRESSIONE** | 0.32:1.18:50:380 | Delicata anti-vibrazione |

**Caratteristiche Speciali:**
- **Processing Parallelo:** 2 file contemporaneamente per cartelle
- **Filtri FC:** Highpass 120Hz, Lowpass 7600Hz (pulizia maggiore)
- **Threading ottimizzato** per velocità massima

**Ideale per:** Serie TV, documentari, contenuti con dialoghi difficili

---

### 🎨 `--cartoni` - Animazione/Musicale
**Preservazione musicale e dinamica per contenuti misti**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.2 | Boost dialoghi leggero |
| **LFE_VOL** | 0.26 (-8%) | Sub bilanciato |
| **SURROUND_VOL** | 3.5 | Preserva musicalità |
| **COMPRESSIONE** | 0.40:1.15:50:330 | Minima per dinamica |

**Filtri Ottimizzati:**
- **FL/FR:** Anti-rumble 18Hz, Lowpass 24kHz (brillantezza musicale)
- **Limitatore gentile** per contenuti misti
- **Range esteso** per colonne sonore elaborate

**Ideale per:** Cartoni animati, anime, contenuti con colonne sonore elaborate

---

## 🎵 Codec Supportati

### 🔥 **EAC3** (Enhanced AC3/DD+) - *Raccomandato*
```bash
./clearvoice077_preset.sh --serie eac3 384k *.mkv
```
- **Bitrate:** 384k (default), 256k, 448k, 640k
- **Qualità:** Ottima compressione/qualità
- **Compatibilità:** Streaming, TV moderne
- **Parametri:** Mixing level 108, Room type 1, Dialnorm -27

### 🎯 **AC3** (Dolby Digital) - *Universale*
```bash
./clearvoice077_preset.sh --film ac3 448k Film/
```
- **Bitrate:** 448k (default), 384k, 640k
- **Qualità:** Standard industry
- **Compatibilità:** Universale (tutti i player)
- **Parametri:** Center mixlev 0.594, Surround mixlev 0.5

### 💎 **DTS** - *Premium Quality*
```bash
./clearvoice077_preset.sh --cartoni dts 768k *.mkv
```
- **Bitrate:** 768k (default), 640k, 1024k, 1536k
- **Qualità:** Massima fedeltà
- **Compatibilità:** Player avanzati, Blu-ray
- **Parametri:** DTS-HD, Compression level 0, 48kHz

---

## 📋 Esempi Pratici

### 🎬 Elaborazione Film Collection
```bash
# Film d'azione con qualità DTS massima
./clearvoice077_preset.sh --film dts 768k /Movies/Action/*.mkv

# Film misti con AC3 universale
./clearvoice077_preset.sh --film ac3 448k *.mkv
```

### 📺 Serie TV con Processing Parallelo
```bash
# Cartella serie con 2 file paralleli (speed boost)
./clearvoice077_preset.sh --serie /TV/Shows/Season1/

# Serie specifica con codec ottimizzato
./clearvoice077_preset.sh --serie eac3 384k "Breaking.Bad.S01*.mkv"
```

### 🎨 Animazione e Documentari
```bash
# Anime con preservazione musicale
./clearvoice077_preset.sh --cartoni eac3 384k /Anime/*.mkv

# Documentari con focus dialoghi
./clearvoice077_preset.sh --serie ac3 448k /Documentaries/*.mkv
```

### ⚡ Batch Processing Avanzato
```bash
# Auto-detect: tutti i .mkv con default serie
./clearvoice077_preset.sh

# Mixed content con preset diversi
for dir in /Movies/*; do
    if [[ "$dir" == *"Action"* ]]; then
        ./clearvoice077_preset.sh --film dts 768k "$dir"/*.mkv
    elif [[ "$dir" == *"TV"* ]]; then
        ./clearvoice077_preset.sh --serie "$dir"/
    fi
done
```

---

## 🆕 Miglioramenti v0.77

### 🔧 **Correzioni Tecniche**
- ✅ **Fix parsing parametri** compressione dinamica
- ✅ **Correzione variabile lp_freq** mancante preset cartoni DTS
- ✅ **Gestione migliorata** variabili locali nel filtro audio
- ✅ **Validazione input robusta** con gestione array vuoti

### 🎧 **Qualità Audio Avanzata**
- 🆕 **Compressore multi-banda** per processing più naturale
- 🆕 **Limitatore intelligente** specifico per ogni preset
- 🆕 **Crossover LFE** con poles controllati per SP7
- 🆕 **Resampling SoxR** precision 28-bit con dithering triangular
- 🆕 **Anti-aliasing** su canali surround posteriori
- 🆕 **Filtri pulizia** Front L/R specifici per preset

### ⚡ **Performance e Usabilità**
- 🚀 **Processing parallelo** per serie TV (2 file contemporaneamente)
- 📊 **Statistiche processing** con tempo medio per file
- 🧠 **Gestione automatica risorse** per evitare sovraccarico CPU
- 🔍 **Validazione input avanzata** con analisi formati dettagliata
- 💡 **Suggerimenti conversione** per mono, stereo, 7.1 surround

### 🎯 **Encoding Ottimizzato**
- 🔧 **Parametri codec** ottimizzati (dialnorm, dsur_mode, dts_hd)
- 🧵 **Threading efficiente** con thread_queue_size
- 📈 **Accelerazione hardware** GPU quando disponibile

---

## 📋 Requisiti Tecnici

### Software Richiesto
| Componente | Versione Minima | Windows 11 | Linux | macOS |
|------------|-----------------|------------|-------|--------|
| **FFmpeg** | 6.0+ | ✅ Winget | ✅ APT/YUM | ✅ Homebrew |
| **Bash** | 4.0+ | ✅ Git Bash | ✅ Nativo | ✅ Nativo |
| **AWK** | Any | ✅ Git Bash | ✅ Nativo | ✅ Nativo |

### Hardware Raccomandato
- **CPU:** Multi-core (4+ thread per performance ottimali)
- **RAM:** 8GB+ per processing parallelo
- **Storage:** SSD raccomandato, ~2x spazio file per elaborazione
- **GPU:** Opzionale (accelerazione hardware quando supportata)

### Audio Input Supportati
| Formato | Canali | Layout | Compatibilità |
|---------|--------|--------|---------------|
| **5.1 Surround** | 6 | 5.1, 5.1(side) | ✅ **Nativo** |
| **5.1 Unknown** | 6 | unknown | ✅ **Auto-fix** |
| **Stereo** | 2 | stereo | ⚠️ **Conversione richiesta** |
| **7.1 Surround** | 8 | 7.1 | ⚠️ **Downmix richiesto** |
| **Mono** | 1 | mono | ⚠️ **Upmix richiesto** |

---

## 🔍 Troubleshooting

### ❌ Errori Comuni

#### "File non 5.1 compatibile"
```bash
# Identifica formato audio
ffprobe -show_streams input.mkv

# Conversioni automatiche:
# Stereo → 5.1
ffmpeg -i input.mkv -af "surround" -c:v copy output_51.mkv

# 7.1 → 5.1  
ffmpeg -i input.mkv -af "pan=5.1|FL=0.5*FL+0.707*FLC|FR=0.5*FR+0.707*FRC|FC=FC|LFE=LFE|BL=BL|BR=BR" -c:v copy output_51.mkv
```

#### "FFmpeg non trovato"
```bash
# Windows 11
winget install ffmpeg
# Riavvia Git Bash

# Linux
sudo apt install ffmpeg

# Verifica installazione
ffmpeg -version
```

#### "Permission denied"
```bash
# Rendi eseguibile
chmod +x clearvoice077_preset.sh

# Verifica permessi directory
ls -la
```

### 🐛 Debug Avanzato

#### Analisi File Audio Dettagliata
```bash
# Analisi completa tracce
ffprobe -v quiet -print_format json -show_streams input.mkv

# Test filtro ClearVoice
ffmpeg -i input.mkv -af "channelmap=channel_layout=5.1" -f null -
```

#### Performance Monitoring
```bash
# Monitor risorse durante elaborazione
top -p $(pgrep ffmpeg)

# Verifica threading
./clearvoice077_preset.sh --serie input.mkv
# Output mostrerà thread utilizzati
```

#### Log Errors
```bash
# Esecuzione con log dettagliato
./clearvoice077_preset.sh --serie input.mkv 2>&1 | tee clearvoice.log
```

---

## 🎧 Consigli per LG SP7 5.1.2

### ⚙️ Configurazione Ottimale SP7
```
Sound Mode: Cinema (preserva dinamica ClearVoice)
AI Sound Pro: OFF (interferisce con processing)
Bass Boost: OFF (LFE già ottimizzato)
Clear Voice: OFF (sostituito da ClearVoice)
Night Mode: OFF (dinamica gestita da script)
```

### 🔊 Test Audio Post-Processing
1. **Test Dialoghi:** Scene conversazione sussurrate
2. **Test LFE:** Scene con bassi intensi (non dovrebbe essere eccessivo)
3. **Test Surround:** Scene con effetti ambientali
4. **Test Dinamica:** Transizioni silenzio→forte

### 📊 Confronto Before/After
```bash
# Analizza livelli audio pre/post processing
ffmpeg -i original.mkv -af "astats=metadata=1:reset=1" -f null -
ffmpeg -i processed_clearvoice.mkv -af "astats=metadata=1:reset=1" -f null -
```

---

## 📁 Struttura Output

### File Generati
```
input_file.mkv → input_file_[preset]_clearvoice0.mkv
```

### Esempi Output
```
Matrix.mkv → Matrix_film_clearvoice0.mkv
Breaking.Bad.S01E01.mkv → Breaking.Bad.S01E01_serie_clearvoice0.mkv
Spirited.Away.mkv → Spirited.Away_cartoni_clearvoice0.mkv
```

### Metadata Ottimizzati
- **Traccia Audio:** Marcata come default, lingua ITA
- **Titolo:** "[CODEC] Clearvoice 5.1"
- **Video/Sottotitoli:** Preservati identici
- **Tracce aggiuntive:** Mantenute come backup

---

## 🤝 Contribuire

### 🔧 Segnalazione Bug
1. **Crea issue** con template bug report
2. **Includi:** Versione OS, FFmpeg, file di test
3. **Log completo:** Output errore con `2>&1 | tee log.txt`

### 💡 Richieste Feature
1. **Descrivi caso d'uso** specifico
2. **Hardware target** (soundbar, AVR model)
3. **Esempi audio** problematici

### 🧪 Testing
```bash
# Test suite completo
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1/tests
./run_tests.sh
```

### 📝 Documentazione
- **Miglioramenti README:** Chiarezza, esempi
- **Traduzioni:** EN, ES, FR, DE
- **Guide video:** Tutorial YouTube

---

## 🏆 Riconoscimenti

### 👨‍💻 Sviluppo
- **Autore:** Sandro "D@mocle77" Sabbioni
- **Testing:** Community LG SP7 users
- **Audio Engineering:** Meridian DSP research

### 🎯 Ottimizzazioni Specifiche
- **LG SP7 5.1.2:** Calibrazione crossover LFE
- **Meridian DSP:** Bypass interference
- **Windows 11:** Compatibilità GitBash/PowerShell

### 🙏 Contributi Community
- **Bug reports:** Issue tracker GitHub
- **Feature requests:** Discussion forum
- **Audio samples:** Testing database

---

## 📄 Licenza

```
MIT License

Copyright (c) 2025 Sandro "D@mocle77" Sabbioni

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Contatti e Supporto

### 🌐 Links Utili
- **Repository:** https://github.com/Damocle77/Clearvoice_5.1
- **Issues:** https://github.com/Damocle77/Clearvoice_5.1/issues
- **Releases:** https://github.com/Damocle77/Clearvoice_5.1/releases
- **Discussions:** https://github.com/Damocle77/Clearvoice_5.1/discussions

### 🚀 Quick Start Links
```bash
# Clone and run in one command
git clone https://github.com/Damocle77/Clearvoice_5.1.git && cd Clearvoice_5.1 && chmod +x clearvoice077_preset.sh && ./clearvoice077_preset.sh --help
```

---

<div align="center">

**🎧 Trasforma il tuo audio 5.1 con ClearVoice**

*Dialoghi cristallini • Sub controllato • Qualità cinema*

[![GitHub stars](https://img.shields.io/github/stars/Damocle77/Clearvoice_5.1.svg?style=social&label=Star)](https://github.com/Damocle77/Clearvoice_5.1)
[![GitHub forks](https://img.shields.io/github/forks/Damocle77/Clearvoice_5.1.svg?style=social&label=Fork)](https://github.com/Damocle77/Clearvoice_5.1/fork)

</div>
