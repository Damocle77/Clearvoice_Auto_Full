# ClearVoice 5.1 🎧

**Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE**

[![Version](https://img.shields.io/badge/version-0.79-blue.svg)](https://github.com/Damocle77/Clearvoice_5.1/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2011%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](#installazione)
[![FFmpeg](https://img.shields.io/badge/ffmpeg-6.0%2B-orange.svg)](#requisiti-tecnici)

> **✨ Specificamente calibrato per sistemi LG Meridian SP7 5.1.2 e soundbar/AVR compatibili**

---

## 🚀 Quick Start

```bash
# Download e installazione rapida
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice079_preset.sh

# Uso immediato (preset automatico per serie TV)
./clearvoice079_preset.sh *.mkv

# Film alta qualità
./clearvoice079_preset.sh --film dts 768k your_movie.mkv
```

---

## 📖 Indice

- [Quick Start](#quick-start)
- [Caratteristiche](#caratteristiche)
- [Installazione](#installazione)
- [Uso](#uso)
- [Preset Disponibili](#preset-disponibili)
- [Codec Supportati](#codec-supportati)
- [Esempi Pratici](#esempi-pratici)
- [Novità v0.79](#novità-v079)
- [Configurazione LG SP7](#configurazione-lg-sp7)
- [Troubleshooting](#troubleshooting)
- [Requisiti Tecnici](#requisiti-tecnici)
- [Contribuire](#contribuire)
- [Licenza](#licenza)

---

## ✨ Caratteristiche

### 🎯 **Ottimizzazioni Audio Avanzate v0.79**
- **Separazione e ottimizzazione individuale** di ogni canale 5.1 (FL/FR/FC/LFE/BL/BR)
- **Boost intelligente canale centrale (FC)** senza interferenze DSP Meridian
- **Controllo LFE anti-boom** con riduzione 20-50% calibrata per preset
- **Compressione dinamica multi-banda** per intelligibilità naturale
- **Limitatore intelligente anti-clipping** con lookahead adattivo
- **Equalizzatore intelligibile specifico** per preset TV (canale centrale + front L/R)

### 🔧 **Tecnologie Avanzate**
- **Crossover LFE precisione** con slopes controllati per perfetta integrazione SP7
- **Resampling SoxR qualità audiophile** con dithering triangular
- **Anti-aliasing surround** per canali posteriori cristallini
- **Filtri pulizia Front L/R** anti-rumble e controllo frequenze acute
- **Preservazione stereofonía FL/FR e surround BL/BR** con processing ottimizzato
- **Processing sequenziale ottimizzato** per stabilità massima

### ⚡ **Performance e Compatibilità**
- **Accelerazione hardware GPU** quando disponibile
- **Threading ottimizzato** per CPU multi-core con queue size
- **Gestione robusta** file con layout audio "unknown" 
- **Preservazione completa** video, tracce audio aggiuntive e sottotitoli
- **Validazione input avanzata** con analisi formati audio dettagliata
- **Encoding ottimizzato specifico** per ogni codec (dialnorm, dsur_mode, dts)

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
chmod +x clearvoice079_preset.sh
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
chmod +x clearvoice079_preset.sh
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
chmod +x clearvoice079_preset.sh
```

---

## ⚡ Uso

### 📖 Sintassi
```bash
./clearvoice079_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
```

### 🎯 Esempi Base
```bash
# Auto-detect preset (serie TV)
./clearvoice079_preset.sh *.mkv

# Preset specifici
./clearvoice079_preset.sh --serie *.mkv              # Serie TV ottimizzate
./clearvoice079_preset.sh --film dts 768k Film/     # Film alta qualità
./clearvoice079_preset.sh --cartoni ac3 448k /Anime/ # Cartoni/Musicali
./clearvoice079_preset.sh --tv *.mkv                # Materiale problematico
```

---

## 🎛️ Preset Disponibili

<details>
<summary>🎬 <strong>--film</strong> - Cinema/Action</summary>

**Ottimizzato per contenuti cinematografici con action e dialoghi intensi**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.5 | Boost dialoghi bilanciato |
| **LFE_VOL** | 0.23 (-23%) | Controllo sub per SP7 |
| **SURROUND_VOL** | 3.6 | Effetti ambientali |
| **COMPRESSIONE** | 0.35:1.30:40:390 | Multi-banda cinematografica |

**✨ Filtri Specifici v0.79:**
- **FC (Centro):** Highpass 115Hz, Lowpass 7900Hz + Compressore multi-banda + Limitatore intelligente
- **FL/FR (Front):** Anti-rumble 22Hz, Lowpass 20kHz per pulizia conservativa
- **LFE:** Crossover precision 25-105Hz (EAC3/AC3) / 30-115Hz (DTS)
- **Surround:** Anti-aliasing + controllo frequenze per canali posteriori cristallini

</details>

<details>
<summary>📺 <strong>--serie</strong> - Serie TV/Dialoghi</summary>

**Massima intelligibilità per dialoghi sussurrati e problematici**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.6 | Boost dialoghi massimo |
| **LFE_VOL** | 0.23 (-23%) | Sub ridotto per TV |
| **SURROUND_VOL** | 3.4 | Ambientali controllati |
| **COMPRESSIONE** | 0.40:1.15:60:380 | Delicata anti-vibrazione |

**🚀 Caratteristiche Speciali v0.79:**
- **Filtri FC:** Highpass 130Hz, Lowpass 7800Hz + Compressore delicato + Anti-aliasing
- **FL/FR:** Anti-rumble 28Hz, Lowpass 18kHz per focus dialoghi
- **Processing sequenziale** ottimizzato per stabilità massima

</details>

<details>
<summary>🎨 <strong>--cartoni</strong> - Animazione/Musicale</summary>

**Preservazione musicale e dinamica per contenuti misti**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.4 | Boost dialoghi leggero |
| **LFE_VOL** | 0.23 (-23%) | Sub bilanciato |
| **SURROUND_VOL** | 3.5 | Preserva musicalità |
| **COMPRESSIONE** | 0.40:1.15:50:330 | Minima per dinamica |

**🎵 Filtri Ottimizzati v0.79:**
- **FC:** Highpass 110Hz, Lowpass 6900Hz + Compressione minima + Limitatore gentile
- **FL/FR:** Anti-rumble 18Hz, Lowpass 24kHz per brillantezza musicale
- **Range esteso** per contenuti con colonne sonore elaborate

</details>

<details>
<summary>⚠️ <strong>--tv</strong> - Materiale Problematico</summary>

**Ultra-conservativo per materiale di bassa qualità con equalizzazione intelligibile**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 5.8 | Boost dialoghi calibrato |
| **LFE_VOL** | 0.23 (-23%) | Sub controllato |
| **SURROUND_VOL** | 3.4 | Ambientali ridotti |
| **COMPRESSIONE** | 0.42:1.28:20:320 | Moderata preservando dinamica |

**🔧 Filtri Speciali v0.79:**
- **Equalizzatore intelligibile** specifico per canale centrale + front L/R
- **FC:** Highpass 180Hz, Lowpass 6000Hz + Equalizzatore dialoghi integrato
- **FL/FR:** Anti-rumble 150Hz, Lowpass 10kHz + EQ enfasi voce
- **Noise reduction aggressivo** per rip di bassa qualità

</details>

---

## 🎵 Codec Supportati

| Codec | Qualità | Compatibilità | Bitrate Default | Ideale Per |
|-------|---------|---------------|----------------|------------|
| **🔥 EAC3** | ⭐⭐⭐⭐⭐ | Universale | 768k | Serie TV, streaming |
| **🎯 AC3** | ⭐⭐⭐⭐ | Massima | 640k | Compatibilità universale |
| **💎 DTS** | ⭐⭐⭐⭐⭐ | Premium | 756k | Film, Blu-ray |

<details>
<summary>📋 Dettagli Codec v0.79</summary>

### EAC3 (Enhanced AC3) - Raccomandato per Serie TV
```bash
./clearvoice079_preset.sh --serie eac3 384k *.mkv
```
- **Parametri:** Mixing level 108, Room type 1, Dialnorm -27, DSur mode 2

### AC3 (Dolby Digital) - Compatibilità Universale  
```bash
./clearvoice079_preset.sh --film ac3 448k *.mkv
```
- **Parametri:** Center mixlev 0.594, Surround mixlev 0.5, Dialnorm -27

### DTS - Qualità Premium per Film e Blu-ray
```bash
./clearvoice079_preset.sh --film dts 768k *.mkv
```
- **Parametri:** Channel layout 5.1(side), Compression level 1

</details>

---

## 📋 Esempi Pratici

<details>
<summary>🎬 Film Collection</summary>

```bash
# Film action con DTS massima qualità
./clearvoice079_preset.sh --film dts 768k /Movies/Action/*.mkv

# Film con EAC3 bilanciato
./clearvoice079_preset.sh --film eac3 384k /Movies/Drama/*.mkv

# Processing batch di cartella
./clearvoice079_preset.sh --film /Movies/Collection/
```
</details>

<details>
<summary>📺 Serie TV</summary>

```bash
# Serie con processing sequenziale ottimizzato
./clearvoice079_preset.sh --serie /TV/BreakingBad/Season1/

# Serie con codec specifico
./clearvoice079_preset.sh --serie eac3 320k "Friends.S01*.mkv"

# Batch multiple cartelle
for season in /TV/Show/Season*; do
    ./clearvoice079_preset.sh --serie "$season"/
done
```
</details>

<details>
<summary>🎨 Contenuti Speciali</summary>

```bash
# Anime con preservazione musicale
./clearvoice079_preset.sh --cartoni ac3 448k /Anime/StudioGhibli/*.mkv

# Documentari con focus dialoghi
./clearvoice079_preset.sh --serie /Documentaries/*.mkv

# Materiale problematico con equalizzazione aggressiva
./clearvoice079_preset.sh --tv *.mkv
```
</details>

---

## 🆕 Novità v0.79

### 🎯 **Miglioramenti Qualità**
- 🆕 **Calcoli numerici sicuri** con fallback automatico (safe_awk_calc)
- 🆕 **Validazione robusta parametri** compressione dinamica
- 🆕 **Equalizzatore intelligibile specifico** per preset TV (canale centrale + front L/R)
- 🆕 **Correzioni parsing array** e variabili locali
- 🆕 **Ottimizzazione filtri audio** per maggiore stabilità

### 🔧 **Correzioni Tecniche**
- ✅ **Gestione errori avanzata** con safe_awk_calc
- ✅ **Validazione numerica input** con fallback intelligente
- ✅ **Miglioramento robustezza** costruzione filtri FFmpeg
- ✅ **Fix variabili globali** e inizializzazione timing
- ✅ **Gestione layout audio "unknown"** più robusta

### ⚡ **Performance e Compatibilità**
- 🚀 **Encoding ottimizzato specifico** per codec (dialnorm, dsur_mode, dts)
- 🚀 **Threading efficiente** con gestione automatica core CPU
- 📊 **Validazione input avanzata** con analisi formati audio dettagliata
- 📊 **Suggerimenti conversione automatici** per mono, stereo, 7.1 surround
- 📊 **Processing sequenziale ottimizzato** per stabilità massima
- 📊 **Statistiche processing complete** con tempo totale elaborazione

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

### 🧪 **Test Post-Processing v0.79**
1. **Dialoghi:** Scene sussurrate (intelligibilità con equalizzatore TV)
2. **LFE:** Bassi intensi (controllo boom migliorato)
3. **Surround:** Effetti ambientali (anti-aliasing cristallino)
4. **Dinamica:** Transizioni silenzio→forte (limitatore intelligente)
5. **Compressione:** Dialoghi naturali (multi-banda)

---

## 🔍 Troubleshooting

<details>
<summary>❌ Errori Comuni</summary>

### "File non 5.1 compatibile"
```bash
# Identifica il problema
ffprobe -show_streams input.mkv | grep channels

# Conversioni automatiche (v0.79 fornisce suggerimenti dettagliati)
# Stereo → 5.1
ffmpeg -i input.mkv -af "surround" -c:v copy output.mkv

# 7.1 → 5.1
ffmpeg -i input.mkv -af "pan=5.1|FL=0.5*FL+0.707*FLC|FR=0.5*FR+0.707*FRC|FC=FC|LFE=LFE|BL=BL|BR=BR" -c:v copy output.mkv
```

### "DTS encoder not supported"
```bash
# Fallback automatico a EAC3
./clearvoice079_preset.sh --film eac3 384k file.mkv
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
<summary>🐛 Debug Avanzato v0.79</summary>

```bash
# Analisi completa file
ffprobe -v quiet -print_format json -show_streams input.mkv

# Test con log dettagliato
./clearvoice079_preset.sh --serie input.mkv 2>&1 | tee debug.log

# Monitor performance
htop -p $(pgrep ffmpeg)

# Test preset specifici
./clearvoice079_preset.sh --tv problematic_file.mkv  # Per materiale problematico
```
</details>

---

## 📋 Requisiti Tecnici

<details>
<summary>💻 Requisiti Sistema</summary>

### Software
| Componente | Min | Raccomandato | Note |
|------------|-----|--------------|------|
| **FFmpeg** | 6.0+ | 7.x+ | Con support SoxR |
| **Bash** | 4.0+ | 5.0+ | Git Bash su Windows |
| **awk** | POSIX | GNU awk | Per calcoli sicuri |
| **CPU** | 2 core | 4+ core | Per threading ottimizzato |
| **RAM** | 4GB | 8GB+ | Per file grandi |
| **Storage** | 2x file size | SSD | Temp space |

### Input Supportati v0.79
- ✅ **5.1 Surround** (nativo)
- ✅ **5.1(side)** (compatibilità DTS)
- ✅ **5.1 Unknown** (auto-fix robusto)
- ⚠️ **Stereo** (conversione con suggerimenti automatici)
- ⚠️ **7.1** (downmix con suggerimenti automatici)
- ⚠️ **Mono** (conversione con suggerimenti automatici)

### Dipendenze
- **ffmpeg 6.0+** (richiesto)
- **awk** (richiesto) 
- **nproc** (opzionale, fallback a 4 thread)
</details>

---

## 🤝 Contribuire

### 🐛 **Bug Report**
1. [Crea issue](https://github.com/Damocle77/Clearvoice_5.1/issues/new) con template
2. Include: OS, FFmpeg version, preset utilizzato, file sample
3. Allega log completo: `./clearvoice079_preset.sh --serie file.mkv 2>&1 | tee debug.log`

### 💡 **Feature Request**
1. Descrivi caso d'uso specifico
2. Hardware target (soundbar/AVR model)
3. Esempi audio problematici
4. Preset preferito per il caso d'uso

### 🧪 **Testing v0.79**
```bash
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
# Test preset specifici
./clearvoice079_preset.sh --film test_sample.mkv
./clearvoice079_preset.sh --serie test_sample.mkv
./clearvoice079_preset.sh --cartoni test_sample.mkv
./clearvoice079_preset.sh --tv test_sample.mkv
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

---

<div align="center">

## 🎧 **ClearVoice 5.1 v0.79** 
### *Calcoli Sicuri • Equalizzazione TV • Dialoghi Cristallini • Processing Sequenziale*

[![⭐ Star](https://img.shields.io/github/stars/Damocle77/Clearvoice_5.1.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1)
[![🍴 Fork](https://img.shields.io/github/forks/Damocle77/Clearvoice_5.1.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1/fork)
[![📥 Download](https://img.shields.io/github/downloads/Damocle77/Clearvoice_5.1/total.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1/releases)

**Trasforma il tuo audio 5.1 con calcoli sicuri e 4 preset ottimizzati per LG SP7**

</div>
