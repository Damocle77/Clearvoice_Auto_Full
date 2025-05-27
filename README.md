# ClearVoice 5.1 🎧

**Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE**

[![Version](https://img.shields.io/badge/version-0.77-blue.svg)](https://github.com/Damocle77/Clearvoice_5.1/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2011%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](#installazione)
[![FFmpeg](https://img.shields.io/badge/ffmpeg-6.0%2B-orange.svg)](#requisiti)

> **✨ Specificamente calibrato per sistemi LG Meridian SP7 5.1.2 e soundbar/AVR compatibili**

---

## 🚀 Quick Start

```bash
# Download e installazione rapida
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice077_preset.sh

# Uso immediato (preset automatico per serie TV)
./clearvoice077_preset.sh *.mkv

# Film alta qualità
./clearvoice077_preset.sh --film eac3 384k your_movie.mkv
```

---

## 📖 Indice

- [Quick Start](#-quick-start)
- [Caratteristiche](#-caratteristiche)
- [Installazione](#-installazione)
- [Uso](#-uso)
- [Preset Disponibili](#️-preset-disponibili)
- [Codec Supportati](#-codec-supportati)
- [Esempi Pratici](#-esempi-pratici)
- [Novità v0.77](#-novità-v077)
- [Configurazione LG SP7](#-configurazione-lg-sp7)
- [Troubleshooting](#-troubleshooting)
- [Requisiti Tecnici](#-requisiti-tecnici)
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
- **Resampling SoxR qualità audiophile** (quando supportato)
- **Anti-aliasing surround** per canali posteriori cristallini
- **Filtri pulizia Front L/R** specifici per preset
- **Processing parallelo** (2 file contemporaneamente per serie TV)

### ⚡ **Performance e Compatibilità**
- **Accelerazione hardware GPU** quando disponibile
- **Threading ottimizzato** per CPU multi-core
- **Gestione robusta** file con layout audio "unknown"
- **Preservazione completa** video, tracce audio aggiuntive e sottotitoli
- **Validazione input avanzata** con analisi formati audio dettagliata
- **Compatibilità estesa** encoder DTS con fallback automatico

---

## 🚀 Installazione

### 🪟 Windows 11 (Raccomandato)

<details>
<summary>📋 Installazione Automatica</summary>

```powershell
# Apri PowerShell come amministratore e esegui:
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install ffmpeg git -y
```
</details>

#### 🛠️ Installazione Manuale
```powershell
# 1. Installa FFmpeg
winget install ffmpeg

# 2. Installa Git Bash
winget install Git.Git

# 3. Riavvia il terminale e clona il repository
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice077_preset.sh
```

### 🐧 Linux

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg git -y

# Fedora/RHEL
sudo dnf install ffmpeg git -y

# Arch Linux
sudo pacman -S ffmpeg git

# Clone e setup
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice077_preset.sh
```

### 🍎 macOS

```bash
# Installa Homebrew se non presente
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installa dipendenze
brew install ffmpeg git

# Clone e setup
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice077_preset.sh
```

---

## ⚡ Uso

### 📖 Sintassi
```bash
./clearvoice077_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
```

### 🎯 Esempi Base
```bash
# Auto-detect preset (serie TV)
./clearvoice077_preset.sh *.mkv

# Preset specifici
./clearvoice077_preset.sh --serie *.mkv              # Serie TV ottimizzate
./clearvoice077_preset.sh --film eac3 384k Film/     # Film alta qualità
./clearvoice077_preset.sh --cartoni /Anime/          # Cartoni/Musicali
```

---

## 🎛️ Preset Disponibili

<details>
<summary>🎬 <strong>--film</strong> - Cinema/Action</summary>

**Ottimizzato per contenuti cinematografici con action e dialoghi intensi**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.5 | Boost dialoghi bilanciato |
| **LFE_VOL** | 0.24 (-17%) | Controllo sub per SP7 |
| **SURROUND_VOL** | 3.6 | Effetti ambientali |
| **COMPRESSIONE** | 0.35:1.30:40:390 | Multi-banda cinematografica |

**✨ Filtri Specifici:**
- **FC (Centro):** Highpass 115Hz, Lowpass 7900Hz
- **FL/FR (Front):** Anti-rumble 22Hz, Lowpass 20kHz  
- **BL/BR (Surround):** Anti-aliasing, pulizia fino 18kHz
- **LFE:** Crossover precision 30-115Hz

</details>

<details>
<summary>📺 <strong>--serie</strong> - Serie TV/Dialoghi</summary>

**Massima intelligibilità per dialoghi sussurrati e problematici**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.6 | Boost dialoghi massimo |
| **LFE_VOL** | 0.24 (-20%) | Sub ridotto per TV |
| **SURROUND_VOL** | 3.4 | Ambientali controllati |
| **COMPRESSIONE** | 0.32:1.18:50:380 | Delicata anti-vibrazione |

**🚀 Caratteristiche Speciali:**
- **Processing Parallelo:** 2 file contemporaneamente
- **Filtri FC:** Highpass 120Hz, Lowpass 7600Hz
- **Threading ottimizzato** per velocità massima

</details>

<details>
<summary>🎨 <strong>--cartoni</strong> - Animazione/Musicale</summary>

**Preservazione musicale e dinamica per contenuti misti**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.2 | Boost dialoghi leggero |
| **LFE_VOL** | 0.26 (-8%) | Sub bilanciato |
| **SURROUND_VOL** | 3.5 | Preserva musicalità |
| **COMPRESSIONE** | 0.40:1.15:50:330 | Minima per dinamica |

**🎵 Filtri Ottimizzati:**
- **FL/FR:** Anti-rumble 18Hz, Lowpass 24kHz
- **Limitatore gentile** per contenuti misti
- **Range esteso** per colonne sonore elaborate

</details>

---

## 🎵 Codec Supportati

| Codec | Qualità | Compatibilità | Bitrate Raccomandato | Ideale Per |
|-------|---------|---------------|---------------------|------------|
| **🔥 EAC3** | ⭐⭐⭐⭐⭐ | Universale | 384k | Streaming, TV moderne |
| **🎯 AC3** | ⭐⭐⭐⭐ | Massima | 448k | Player legacy, universale |
| **💎 DTS** | ⭐⭐⭐⭐⭐ | Premium | 768k | Blu-ray, player avanzati |

<details>
<summary>📋 Dettagli Codec</summary>

### EAC3 (Enhanced AC3) - Raccomandato
```bash
./clearvoice077_preset.sh --serie eac3 384k *.mkv
```
- **Bitrate:** 256k, 384k (default), 448k, 640k
- **Parametri:** Mixing level 108, Room type 1, Dialnorm -27

### AC3 (Dolby Digital) - Universale  
```bash
./clearvoice077_preset.sh --film ac3 448k *.mkv
```
- **Bitrate:** 384k, 448k (default), 640k
- **Parametri:** Center mixlev 0.594, Surround mixlev 0.5

### DTS - Premium Quality
```bash
./clearvoice077_preset.sh --cartoni dts 768k *.mkv
```
- **Bitrate:** 640k, 768k (default), 1024k, 1536k
- **Layout:** 5.1(side) per compatibilità estesa

</details>

---

## 📋 Esempi Pratici

<details>
<summary>🎬 Film Collection</summary>

```bash
# Film action con EAC3 ottimale
./clearvoice077_preset.sh --film eac3 384k /Movies/Action/*.mkv

# Film premium con DTS massima qualità
./clearvoice077_preset.sh --film dts 768k /Movies/4K/*.mkv

# Processing batch di cartella
./clearvoice077_preset.sh --film /Movies/Collection/
```
</details>

<details>
<summary>📺 Serie TV</summary>

```bash
# Serie con processing parallelo (2x velocità)
./clearvoice077_preset.sh --serie /TV/BreakingBad/Season1/

# Singola serie con codec specifico
./clearvoice077_preset.sh --serie eac3 384k "Friends.S01*.mkv"

# Batch multiple cartelle
for season in /TV/Show/Season*; do
    ./clearvoice077_preset.sh --serie "$season"/
done
```
</details>

<details>
<summary>🎨 Contenuti Speciali</summary>

```bash
# Anime con preservazione musicale
./clearvoice077_preset.sh --cartoni /Anime/StudioGhibli/*.mkv

# Documentari con focus dialoghi
./clearvoice077_preset.sh --serie /Documentaries/*.mkv

# Mix contenuti con preset automatico
./clearvoice077_preset.sh /Media/Mixed/*.mkv
```
</details>

---

## 🆕 Novità v0.77

### 🔧 **Correzioni Critiche**
- ✅ **Fix parsing parametri** compressione dinamica
- ✅ **Gestione robusta** variabili locali nei filtri audio
- ✅ **Validazione input avanzata** con gestione array vuoti
- ✅ **Compatibilità DTS estesa** con layout 5.1(side)

### 🎧 **Miglioramenti Audio**
- 🆕 **Compressore multi-banda** per processing naturale
- 🆕 **Limitatore intelligente** specifico per preset
- 🆕 **Crossover LFE precision** calibrato per SP7
- 🆕 **Resampling SoxR** 28-bit precision
- 🆕 **Anti-aliasing surround** per canali posteriori

### ⚡ **Performance**
- 🚀 **Processing parallelo** (2 file per serie TV)
- 📊 **Statistiche dettagliate** con tempo medio
- 🧠 **Auto-gestione risorse** CPU
- 🔍 **Analisi formati** input avanzata

---

## 🎧 Configurazione LG SP7

### ⚙️ **Impostazioni Ottimali**
```
🔊 Sound Mode: Cinema
❌ AI Sound Pro: OFF  
❌ Bass Boost: OFF
❌ Clear Voice: OFF (sostituito da ClearVoice)
❌ Night Mode: OFF
🔧 EQ: Flat/Manuale
```

### 🧪 **Test Post-Processing**
1. **Dialoghi:** Scene sussurrate (intelligibilità)
2. **LFE:** Bassi intensi (controllo boom)
3. **Surround:** Effetti ambientali (chiarezza)
4. **Dinamica:** Transizioni silenzio→forte

---

## 🔍 Troubleshooting

<details>
<summary>❌ Errori Comuni</summary>

### "File non 5.1 compatibile"
```bash
# Identifica il problema
ffprobe -show_streams input.mkv | grep channels

# Conversioni automatiche
# Stereo → 5.1
ffmpeg -i input.mkv -af "surround" -c:v copy output.mkv

# 7.1 → 5.1
ffmpeg -i input.mkv -af "pan=5.1|FL=0.5*FL+0.707*FLC|FR=0.5*FR+0.707*FRC|FC=FC|LFE=LFE|BL=BL|BR=BR" -c:v copy output.mkv
```

### "DTS encoder not supported"
```bash
# Fallback automatico a EAC3
./clearvoice077_preset.sh --film eac3 384k file.mkv
```

### "FFmpeg non trovato"
```bash
# Windows
winget install ffmpeg

# Linux
sudo apt install ffmpeg

# Verifica
ffmpeg -version
```
</details>

<details>
<summary>🐛 Debug Avanzato</summary>

```bash
# Analisi completa file
ffprobe -v quiet -print_format json -show_streams input.mkv

# Test con log dettagliato
./clearvoice077_preset.sh --serie input.mkv 2>&1 | tee debug.log

# Monitor performance
htop -p $(pgrep ffmpeg)
```
</details>

---

## 📋 Requisiti Tecnici

<details>
<summary>💻 Requisiti Sistema</summary>

### Software
| Componente | Min | Raccomandato | Note |
|------------|-----|--------------|------|
| **FFmpeg** | 6.0+ | 7.1+ | Con support SoxR |
| **Bash** | 4.0+ | 5.0+ | Git Bash su Windows |
| **CPU** | 2 core | 4+ core | Per processing parallelo |
| **RAM** | 4GB | 8GB+ | Per file grandi |
| **Storage** | 2x file size | SSD | Temp space |

### Input Supportati
- ✅ **5.1 Surround** (nativo)
- ✅ **5.1 Unknown** (auto-fix)
- ⚠️ **Stereo** (conversione richiesta)
- ⚠️ **7.1** (downmix richiesto)
</details>

---

## 🤝 Contribuire

### 🐛 **Bug Report**
1. [Crea issue](https://github.com/Damocle77/Clearvoice_5.1/issues/new) con template
2. Include: OS, FFmpeg version, file sample
3. Allega log completo: `script.sh file.mkv 2>&1 | tee log.txt`

### 💡 **Feature Request**
1. Descrivi caso d'uso specifico
2. Hardware target (soundbar/AVR model)
3. Esempi audio problematici

### 🧪 **Testing**
```bash
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
# Test su file di esempio
./clearvoice077_preset.sh --serie test_sample.mkv
```

---

## 📄 Licenza

```
MIT License - Copyright (c) 2025 Sandro "D@mocle77" Sabbioni
```

Sentiti libero di usare, modificare e distribuire secondo i termini MIT.

---

## 📞 Links e Supporto

### 🌐 **Repository**
- **Main:** https://github.com/Damocle77/Clearvoice_5.1
- **Issues:** https://github.com/Damocle77/Clearvoice_5.1/issues
- **Releases:** https://github.com/Damocle77/Clearvoice_5.1/releases

### 🚀 **One-Liner Setup**
```bash
curl -fsSL https://raw.githubusercontent.com/Damocle77/Clearvoice_5.1/main/install.sh | bash
```

---

<div align="center">

## 🎧 **ClearVoice 5.1** 
### *Dialoghi Cristallini • Sub Controllato • Qualità Cinema*

[![⭐ Star](https://img.shields.io/github/stars/Damocle77/Clearvoice_5.1.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1)
[![🍴 Fork](https://img.shields.io/github/forks/Damocle77/Clearvoice_5.1.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1/fork)

**Trasforma il tuo audio 5.1 con un click**

</div>
