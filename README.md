# ClearVoice 5.1 🎧

**Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE**

[![Version](https://img.shields.io/badge/version-0.77-blue.svg)](https://github.com/Damocle77/Clearvoice_5.1/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2011%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](#installazione)
[![FFmpeg](https://img.shields.io/badge/ffmpeg-6.0%2B-orange.svg)](#requisiti-tecnici)

> **✨ Testato per sistemi LG Meridian SP7 5.1.2 e soundbar/AVR compatibili**

---

## 🚀 Quick Start

```bash
# Download e installazione rapida
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice077_preset.sh

# Uso immediato (preset automatico per serie TV, es. input.mkv -> input_serie_clearvoice0.mkv)
./clearvoice077_preset.sh *.mkv

# Film alta qualità (es. your_movie.mkv -> your_movie_film_clearvoice0.mkv)
./clearvoice077_preset.sh --film eac3 384k your_movie.mkv
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
- [Novità v0.77](#novità-v077)
- [Configurazione LG SP7](#configurazione-lg-sp7)
- [Troubleshooting](#troubleshooting)
- [Requisiti Tecnici](#requisiti-tecnici)
- [Contribuire](#contribuire)
- [Licenza](#licenza)

---

## ✨ Caratteristiche

### 🎯 **Ottimizzazioni Audio Avanzate**
- **Separazione e ottimizzazione individuale** di ogni canale 5.1 (FL/FR/FC/LFE/BL/BR)
- **Boost intelligente canale centrale (FC)** senza interferenze DSP Meridian
- **Controllo LFE anti-boom** con riduzione ~8-20% calibrata per preset e codec
- **Compressione dinamica multi-banda** per intelligibilità naturale
- **Limitatore intelligente anti-clipping** con lookahead adattivo

### 🔧 **Tecnologie Avanzate**
- **Crossover LFE precisione** con slopes controllati (es. ~25-115Hz, varia per codec/preset)
- **Resampling SoxR qualità audiophile** (precisione 28-bit)
- **Anti-aliasing surround** per canali posteriori cristallini
- **Filtri pulizia Front L/R** specifici per preset
- **Processing parallelo** (2 file contemporaneamente per serie TV con più file)

### ⚡ **Performance e Compatibilità**
- **Accelerazione hardware GPU** quando disponibile (tramite FFmpeg)
- **Threading ottimizzato** per CPU multi-core
- **Gestione robusta** file con layout audio "unknown"
- **Preservazione completa** video, tracce audio aggiuntive e sottotitoli
- **Validazione input avanzata** con analisi formati audio dettagliata
- **Compatibilità estesa** encoder DTS

---

## 🚀 Installazione

### 🪟 Windows 11 (Raccomandato)

<details>
<summary>📋 Installazione Automatica</summary>

```powershell
# Apri PowerShell come amministratore e esegui:
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install ffmpeg git awk -y # Aggiunto awk per completezza
```
</details>

#### 🛠️ Installazione Manuale
```powershell
# 1. Installa FFmpeg
winget install ffmpeg

# 2. Installa Git Bash (include awk)
winget install Git.Git

# 3. Riavvia il terminale e clona il repository
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice077_preset.sh
```

### 🐧 Linux

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg git awk -y

# Fedora/RHEL
sudo dnf install ffmpeg git gawk -y # gawk fornisce awk

# Arch Linux
sudo pacman -S ffmpeg git awk

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
brew install ffmpeg git awk

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
Output: `nomefile_[PRESET]_clearvoice0.mkv`

### 🎯 Esempi Base
```bash
# Auto-detect preset (serie TV) e codec/bitrate default (eac3 384k)
./clearvoice077_preset.sh *.mkv

# Preset specifici
./clearvoice077_preset.sh --serie *.mkv              # Serie TV ottimizzate (default eac3 384k)
./clearvoice077_preset.sh --film eac3 384k Film/     # Film alta qualità
./clearvoice077_preset.sh --cartoni ac3 448k /Anime/ # Cartoni/Musicali (default ac3 448k)
```

---

## 🎛️ Preset Disponibili

<details>
<summary>🎬 <strong>--film</strong> - Cinema/Action</summary>

**Ottimizzato per contenuti cinematografici con action e dialoghi intensi**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.5 | Boost dialoghi bilanciato |
| **LFE_VOL** | 0.24 (rid. ~17-18%) | Controllo sub per SP7 (varia per codec) |
| **SURROUND_VOL** | 3.6 | Effetti ambientali (varia per codec) |
| **COMPRESSIONE** | 0.35:1.30:40:390 | Multi-banda cinematografica |

**✨ Filtri Specifici:**
- **FC (Centro):** Highpass 115Hz, Lowpass 7900Hz (varia per codec DTS: HP 135Hz, LP 7700Hz)
- **FL/FR (Front):** Anti-rumble 22Hz, Lowpass 20kHz
- **BL/BR (Surround):** Filtri specifici (es. HP ~30-35Hz, LP ~18-19kHz, varia per codec)
- **LFE:** Crossover ~25-105Hz (Dolby) / ~30-115Hz (DTS)

</details>

<details>
<summary>📺 <strong>--serie</strong> - Serie TV/Dialoghi</summary>

**Massima intelligibilità per dialoghi sussurrati e problematici**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.6 | Boost dialoghi massimo |
| **LFE_VOL** | 0.24 (rid. ~15-20%) | Sub ridotto per TV (varia per codec) |
| **SURROUND_VOL** | 3.4 | Ambientali controllati (varia per codec) |
| **COMPRESSIONE** | 0.32:1.18:50:380 | Delicata anti-vibrazione |

**🚀 Caratteristiche Speciali:**
- **Processing Parallelo:** 2 file contemporaneamente (se più file input)
- **Filtri FC:** Highpass 120Hz, Lowpass 7600Hz (varia per codec DTS: HP 130Hz, LP 7500Hz)
- **Filtri FL/FR (Front):** Anti-rumble 28Hz, Lowpass 18kHz
- **BL/BR (Surround):** Filtri specifici (es. HP ~30-35Hz, LP ~18-19kHz, varia per codec)
- **LFE:** Crossover ~25-105Hz (Dolby) / ~30-115Hz (DTS)
- **Threading ottimizzato** per velocità massima

</details>

<details>
<summary>🎨 <strong>--cartoni</strong> - Animazione/Musicale</summary>

**Preservazione musicale e dinamica per contenuti misti**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.2 | Boost dialoghi leggero |
| **LFE_VOL** | 0.26 (rid. ~8%) | Sub bilanciato (varia per codec) |
| **SURROUND_VOL** | 3.5 | Preserva musicalità (varia per codec) |
| **COMPRESSIONE** | 0.40:1.15:50:330 | Minima per dinamica |

**🎵 Filtri Ottimizzati:**
- **FC (Centro):** Highpass 110Hz, Lowpass 6900Hz (varia per codec DTS: HP 125Hz, LP 6800Hz)
- **FL/FR (Front):** Anti-rumble 18Hz, Lowpass 24kHz
- **BL/BR (Surround):** Filtri specifici (es. HP ~30-35Hz, LP ~18-19kHz, varia per codec)
- **LFE:** Crossover ~25-105Hz (Dolby) / ~30-115Hz (DTS)
- **Limitatore gentile** per contenuti misti
- **Range esteso** per colonne sonore elaborate

</details>

---

## 🎵 Codec Supportati

| Codec | Qualità | Compatibilità | Bitrate Default (Script) | Ideale Per |
|-------|---------|---------------|--------------------------|------------|
| **🔥 EAC3** | ⭐⭐⭐⭐⭐ | Universale | 384k | Streaming, TV moderne |
| **🎯 AC3** | ⭐⭐⭐⭐ | Massima | 448k | Player legacy, universale |
| **💎 DTS** | ⭐⭐⭐⭐⭐ | Premium | 768k | Blu-ray, player avanzati |

<details>
<summary>📋 Dettagli Codec</summary>

### EAC3 (Enhanced AC3) - Raccomandato
```bash
./clearvoice077_preset.sh --serie eac3 384k *.mkv
```
- **Bitrate Default:** 384k (Opzioni: 256k, 448k, 640k)
- **Parametri Script:** `-channel_layout 5.1 -mixing_level 108 -room_type 1 -copyright 0 -dialnorm -27 -dsur_mode 2`

### AC3 (Dolby Digital) - Universale  
```bash
./clearvoice077_preset.sh --film ac3 448k *.mkv
```
- **Bitrate Default:** 448k (Opzioni: 384k, 640k)
- **Parametri Script:** `-channel_layout 5.1 -center_mixlev 0.594 -surround_mixlev 0.5 -dialnorm -27`

### DTS - Premium Quality
```bash
./clearvoice077_preset.sh --cartoni dts 768k *.mkv
```
- **Bitrate Default:** 768k (Opzioni: 640k, 1024k, 1536k)
- **Parametri Script:** `-strict -2 -ar 48000 -channel_layout 5.1(side) -compression_level 1`

</details>

---

## 📋 Esempi Pratici

<details>
<summary>🎬 Film Collection</summary>

```bash
# Film action con EAC3 ottimale (default 384k)
./clearvoice077_preset.sh --film eac3 /Movies/Action/*.mkv 
# Output: /Movies/Action/nomefilm_film_clearvoice0.mkv

# Film premium con DTS massima qualità (default 768k)
./clearvoice077_preset.sh --film dts /Movies/4K/*.mkv

# Processing batch di cartella (default eac3 384k per --film se non specificato)
./clearvoice077_preset.sh --film /Movies/Collection/
```
</details>

<details>
<summary>📺 Serie TV</summary>

```bash
# Serie con processing parallelo (2x velocità, default eac3 384k)
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
# Anime con preservazione musicale (default eac3 384k per --cartoni se non specificato)
./clearvoice077_preset.sh --cartoni /Anime/StudioGhibli/*.mkv

# Documentari con focus dialoghi (preset --serie, default eac3 384k)
./clearvoice077_preset.sh --serie /Documentaries/*.mkv

# Mix contenuti con preset automatico (serie, eac3 384k)
./clearvoice077_preset.sh /Media/Mixed/*.mkv
```
</details>

---

## 🆕 Novità v0.77

### 🔧 **Correzioni Critiche**
- ✅ **Fix parsing parametri** compressione dinamica
- ✅ **Gestione robusta** variabili locali nei filtri audio
- ✅ **Validazione input avanzata** con gestione array vuoti
- ✅ **Compatibilità DTS estesa** con layout `5.1(side)`

### 🎧 **Miglioramenti Audio**
- 🆕 **Compressore multi-banda** per processing naturale
- 🆕 **Limitatore intelligente** specifico per preset
- 🆕 **Crossover LFE precision** calibrato per SP7
- 🆕 **Resampling SoxR** 28-bit precision
- 🆕 **Anti-aliasing surround** per canali posteriori

### ⚡ **Performance**
- 🚀 **Processing parallelo** (2 file per preset `--serie` con più file)
- 📊 **Statistiche dettagliate** con tempo medio
- 🧠 **Auto-gestione risorse** CPU (bilanciamento thread in parallelo)
- 🔍 **Analisi formati** input avanzata

---

## 🎧 Configurazione per Soundbar LG SP7 5.1.2 o AVR equivalenti

### ⚙️ **Impostazioni Ottimali**
```
🔊 Sound Mode: Cinema (o Standard/Music a seconda del contenuto e preferenze)
❌ AI Sound Pro: OFF  
❌ Bass Boost: OFF (o minimo se necessario)
❌ Clear Voice (funzione TV/Soundbar): OFF (sostituito da questo script)
❌ Night Mode: OFF
🔧 EQ: Flat/Manuale (evitare curve estreme)
```

### 🧪 **Test Post-Processing**
1. **Dialoghi:** Scene sussurrate (intelligibilità)
2. **LFE:** Bassi intensi (controllo boom, no distorsione)
3. **Surround:** Effetti ambientali (chiarezza, spazialità)
4. **Dinamica:** Transizioni silenzio→forte (impatto preservato)

---

## 🔍 Troubleshooting

<details>
<summary>❌ Errori Comuni</summary>

### "File non 5.1 compatibile"
Lo script processa solo file con una traccia audio 5.1.
```bash
# Identifica il problema (controlla 'channels' e 'channel_layout')
ffprobe -show_streams input.mkv 

# Conversioni di esempio (da adattare):
# Stereo → 5.1 (upmix generico, qualità variabile)
ffmpeg -i input.mkv -af "surround" -c:v copy output_51.mkv

# 7.1 → 5.1 (downmix di esempio)
ffmpeg -i input.mkv -af "pan=5.1|FL=0.5*FL+0.707*FLC|FR=0.5*FR+0.707*FRC|FC=FC|LFE=LFE|BL=BL|BR=BR" -c:v copy output_51.mkv
```
Lo script fornisce suggerimenti di conversione durante la validazione.

### "DTS encoder not supported"
Assicurati che la tua build FFmpeg includa un encoder DTS (come `dcaenc`).
```bash
# Soluzione: Usa EAC3 o AC3 come codec di fallback
./clearvoice077_preset.sh --film eac3 384k file.mkv
```

### "FFmpeg non trovato" o "awk non trovato"
Assicurati che FFmpeg e awk siano installati e nel PATH di sistema.
```bash
# Windows (PowerShell)
winget install ffmpeg
# Git Bash per Windows include awk. Altrimenti, considera Chocolatey: choco install awk

# Linux (esempio Ubuntu/Debian)
sudo apt install ffmpeg awk

# Verifica
ffmpeg -version
awk --version
```
</details>

<details>
<summary>🐛 Debug Avanzato</summary>

```bash
# Analisi completa file (output JSON)
ffprobe -v quiet -print_format json -show_streams input.mkv

# Test con log dettagliato su file
./clearvoice077_preset.sh --serie input.mkv > debug.log 2>&1

# Monitor performance (Linux/macOS)
# Esegui lo script e poi in un altro terminale:
htop # cerca processi ffmpeg
# Su Windows, usa Task Manager.
```
</details>

---

## 📋 Requisiti Tecnici

<details>
<summary>💻 Requisiti Sistema</summary>

### Software
| Componente | Min | Raccomandato | Note |
|------------|-----|--------------|------|
| **FFmpeg** | 6.0+ | 7.1+ | Con supporto SoxR, encoder per codec scelti (eac3, ac3, dts) |
| **Bash**   | 4.0+ | 5.0+ | Git Bash su Windows |
| **awk**    | Standard | Standard | Utilità GNU awk o compatibile |
| **CPU**    | 2 core | 4+ core | Per processing parallelo |
| **RAM**    | 4GB | 8GB+ | Per file grandi |
| **Storage**| ~2x file size | SSD | Spazio per file temporanei e output |

### Input Supportati
- ✅ **5.1 Surround** (nativo, layout `5.1` o `5.1(side)`)
- ✅ **5.1 Unknown** (layout audio "unknown", script tenta auto-fix)
- ⚠️ **Stereo, Mono, 7.1, etc.** (conversione a 5.1 richiesta prima di usare lo script)

</details>

---

## 🤝 Contribuire

### 🐛 **Bug Report**
1. [Crea issue](https://github.com/Damocle77/Clearvoice_5.1/issues/new) usando il template.
2. Includi: OS, versione FFmpeg (`ffmpeg -version`), versione Bash (`bash --version`), versione awk (`awk --version`).
3. Fornisci un output `ffprobe -show_streams input.mkv` del file problematico.
4. Allega log completo: `./clearvoice077_preset.sh [parametri] file.mkv > log.txt 2>&1`

### 💡 **Feature Request**
1. Descrivi il caso d'uso specifico e il beneficio atteso.
2. Specifica l'hardware target (es. modello soundbar/AVR) se rilevante.
3. Fornisci esempi audio o scenari problematici, se possibile.

### 🧪 **Testing**
```bash
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
# Esegui test con file di esempio e diversi preset/codec
./clearvoice077_preset.sh --serie eac3 384k test_sample_serie.mkv
./clearvoice077_preset.sh --film dts 768k test_sample_film.mkv
```

---

## 📄 Licenza

```
MIT License - Copyright (c) 2025 Sandro "D@mocle77" Sabbioni
```

Sentiti libero di usare, modificare e distribuire secondo i termini della licenza MIT.

---

## 📞 Links e Supporto

### 🌐 **Repository**
- **Main:** https://github.com/Damocle77/Clearvoice_5.1
- **Issues:** https://github.com/Damocle77/Clearvoice_5.1/issues
- **Releases:** https://github.com/Damocle77/Clearvoice_5.1/releases

### 🚀 **One-Liner Setup (Linux/macOS)**
```bash
curl -fsSL https://raw.githubusercontent.com/Damocle77/Clearvoice_5.1/main/install.sh | bash
```
*(Nota: lo script `install.sh` deve essere creato e mantenuto nel repository)*

---

<div align="center">

## 🎧 **ClearVoice 5.1** 
### *Dialoghi Cristallini • Sub Controllato • Qualità Cinema*

[![⭐ Star](https://img.shields.io/github/stars/Damocle77/Clearvoice_5.1.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1)
[![🍴 Fork](https://img.shields.io/github/forks/Damocle77/Clearvoice_5.1.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1/fork)
[![📥 Download](https://img.shields.io/github/downloads/Damocle77/Clearvoice_5.1/total.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1/releases)

*Sound Engineering by Sandro 'D@mocle77' Sabbioni*

</div>