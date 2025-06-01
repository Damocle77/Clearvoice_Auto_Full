<!-- filepath: f:\TESTSUB\README.md -->
# ClearVoice 5.1 🎧

**Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE**

[![Version](https://img.shields.io/badge/version-0.78-blue.svg)](https://github.com/Damocle77/Clearvoice_5.1/releases)
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
chmod +x clearvoice078_preset.sh

# Uso immediato (preset automatico per serie TV, es. input.mkv -> input_serie_clearvoice0.mkv)
./clearvoice078_preset.sh *.mkv

# Film alta qualità (es. your_movie.mkv -> your_movie_film_clearvoice0.mkv)
./clearvoice078_preset.sh --film dts 768k your_movie.mkv
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
- [Novità v0.78](#novità-v078)
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
- **Controllo LFE anti-boom** con riduzione 8-20% calibrata per preset e codec
- **Compressione dinamica multi-banda** per intelligibilità naturale
- **Limitatore intelligente anti-clipping** con lookahead adattivo

### 🔧 **Tecnologie Avanzate v0.78**
- **Equalizzatore intelligibile** specifico per preset TV (canale centrale + front L/R)
- **Crossover LFE precisione** con slopes controllati per perfetta integrazione SP7
- **Resampling SoxR qualità audiophile** con dithering triangular (precisione 28-bit)
- **Anti-aliasing surround** per canali posteriori cristallini
- **Filtri pulizia Front L/R** anti-rumble e controllo frequenze acute
- **Processing parallelo** (2 file contemporaneamente per preset --serie)

### ⚡ **Performance e Compatibilità**
- **Accelerazione hardware GPU** quando disponibile (tramite FFmpeg)
- **Threading ottimizzato** per CPU multi-core con queue size
- **Gestione robusta** file con layout audio "unknown"
- **Preservazione completa** video, tracce audio aggiuntive e sottotitoli
- **Validazione input avanzata** con analisi formati audio dettagliata e suggerimenti conversione
- **Bilanciamento automatico risorse** CPU per modalità parallela

---

## 🚀 Installazione

### 🪟 Windows 11 (Raccomandato)

<details>
<summary>📋 Installazione Automatica</summary>

```powershell
# Apri PowerShell come amministratore e esegui:
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install ffmpeg git awk bc -y
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
chmod +x clearvoice078_preset.sh
```

### 🐧 Linux

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg git awk bc -y

# Fedora/RHEL
sudo dnf install ffmpeg git gawk bc -y

# Arch Linux
sudo pacman -S ffmpeg git awk bc

# Clone e setup
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice078_preset.sh
```

### 🍎 macOS

```bash
# Installa Homebrew se non presente
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installa dipendenze
brew install ffmpeg git awk bc

# Clone e setup
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice078_preset.sh
```

---

## ⚡ Uso

### 📖 Sintassi
```bash
./clearvoice078_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
```
Output: `nomefile_[PRESET]_clearvoice0.mkv`

### 🎯 Esempi Base
```bash
# Auto-detect preset (serie TV) e codec/bitrate default (eac3 384k)
./clearvoice078_preset.sh *.mkv

# Preset specifici
./clearvoice078_preset.sh --serie *.mkv                    # Serie TV (2 file paralleli)
./clearvoice078_preset.sh --film dts 768k Film/           # Film DTS alta qualità
./clearvoice078_preset.sh --tv *.mkv                      # Materiale problematico + EQ
./clearvoice078_preset.sh --cartoni ac3 448k /Anime/      # Cartoni/Musicali
```

---

## 🎛️ Preset Disponibili

<details>
<summary>🎬 <strong>--film</strong> - Cinema/Action</summary>

**Ottimizzato per contenuti cinematografici con action e dialoghi intensi**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.5 | Boost dialoghi bilanciato |
| **LFE_VOL** | 0.24 (rid. ~17-20%) | Controllo sub per SP7 (varia per codec) |
| **SURROUND_VOL** | 3.6 | Effetti ambientali (varia per codec) |
| **COMPRESSIONE** | 0.35:1.30:40:390 | Multi-banda cinematografica |

**✨ Filtri Specifici:**
- **FC (Centro):** Highpass 115Hz, Lowpass 7900Hz (DTS: HP 135Hz, LP 7700Hz)
- **FL/FR (Front):** Anti-rumble 22Hz, Lowpass 20kHz per pulizia conservativa
- **LFE:** Crossover 25-105Hz (Dolby) / 30-115Hz (DTS) con precisione
- **Limitatore:** Cinematografico con preservazione dinamica

</details>

<details>
<summary>📺 <strong>--serie</strong> - Serie TV/Dialoghi</summary>

**Massima intelligibilità per dialoghi sussurrati e problematici**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.6 | Boost dialoghi massimo |
| **LFE_VOL** | 0.24 (rid. ~18-20%) | Sub controllato per TV (varia per codec) |
| **SURROUND_VOL** | 3.4 | Ambientali controllati (varia per codec) |
| **COMPRESSIONE** | 0.40:1.15:60:380 | Delicata anti-vibrazione |

**🚀 Caratteristiche Speciali:**
- **Processing Parallelo:** 2 file contemporaneamente per massima velocità
- **Filtri FC:** Highpass 130Hz, Lowpass 7800Hz (DTS: HP 135Hz, LP 8000Hz)
- **Filtri FL/FR:** Anti-rumble 28Hz, Lowpass 18kHz per focus dialoghi
- **Threading ottimizzato** per velocità massima con bilanciamento risorse

</details>

<details>
<summary>📺 <strong>--tv</strong> - Materiale Problematico + EQ Intelligibile</summary>

**Ultra-conservativo per audio compresso con equalizzazione specifica**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 7.3 | Boost dialoghi moderato |
| **LFE_VOL** | 0.23 (rid. ~23-30%) | Sub ultra-controllato |
| **SURROUND_VOL** | 3.4 | Ambientali controllati |
| **COMPRESSIONE** | 0.90:1.30:20:250 | Ultra-conservativa |

**🎛️ Equalizzazione Intelligibile (NOVITÀ v0.78):**
- **FC (Centro):** EQ dialoghi 300Hz-4kHz per massima intelligibilità
- **FL/FR (Front):** EQ enfasi voce 800Hz-3kHz per materiale problematico
- **Filtri:** Highpass 160Hz, Lowpass 7000Hz per pulizia estrema
- **Ideale per:** Rip di bassa qualità, audio compresso, materiale problematico

</details>

<details>
<summary>🎨 <strong>--cartoni</strong> - Animazione/Musicale</summary>

**Preservazione musicale e dinamica per contenuti misti**

| Parametro | Valore | Descrizione |
|-----------|--------|-------------|
| **VOICE_VOL** | 8.2 | Boost dialoghi leggero |
| **LFE_VOL** | 0.26 (rid. ~8-17%) | Sub bilanciato per musica |
| **SURROUND_VOL** | 3.5 | Preserva musicalità |
| **COMPRESSIONE** | 0.40:1.15:50:330 | Minima per dinamica |

**🎵 Filtri Ottimizzati:**
- **FC (Centro):** Highpass 110Hz, Lowpass 6900Hz (DTS: HP 125Hz, LP 6800Hz)
- **FL/FR (Front):** Anti-rumble 18Hz, Lowpass 24kHz per brillantezza musicale
- **Limitatore gentile** per preservare transitori musicali
- **Range esteso** per colonne sonore elaborate

</details>

---

## 🎵 Codec Supportati

| Codec | Qualità | Compatibilità | Bitrate Default | Ideale Per |
|-------|---------|---------------|-----------------|------------|
| **🔥 EAC3** | ⭐⭐⭐⭐⭐ | Universale | 384k | Streaming, TV moderne |
| **🎯 AC3** | ⭐⭐⭐⭐ | Massima | 448k | Player legacy, universale |
| **💎 DTS** | ⭐⭐⭐⭐⭐ | Premium | 768k | Blu-ray, player avanzati |

<details>
<summary>📋 Dettagli Codec con Parametri Qualità v0.78</summary>

### EAC3 (Enhanced AC3) - Raccomandato
```bash
./clearvoice078_preset.sh --serie eac3 320k *.mkv
```
- **Bitrate:** 256k, 320k, **384k** (default), 448k, 640k
- **Parametri Qualità:** `-channel_layout 5.1 -mixing_level 108 -room_type 1 -copyright 0 -dialnorm -27 -dsur_mode 2`

### AC3 (Dolby Digital) - Universale  
```bash
./clearvoice078_preset.sh --film ac3 448k *.mkv
```
- **Bitrate:** 384k, **448k** (default), 640k
- **Parametri Qualità:** `-channel_layout 5.1 -center_mixlev 0.594 -surround_mixlev 0.5 -dialnorm -27`

### DTS - Premium Quality
```bash
./clearvoice078_preset.sh --cartoni dts 768k *.mkv
```
- **Bitrate:** 640k, **768k** (default), 1024k, 1536k
- **Parametri Qualità:** `-strict -2 -ar 48000 -channel_layout 5.1(side) -compression_level 1`

</details>

---

## 📋 Esempi Pratici

<details>
<summary>🎬 Film Collection</summary>

```bash
# Film action con EAC3 ottimale
./clearvoice078_preset.sh --film eac3 384k /Movies/Action/*.mkv 
# Output: /Movies/Action/nomefilm_film_clearvoice0.mkv

# Film premium con DTS massima qualità
./clearvoice078_preset.sh --film dts 768k /Movies/4K/*.mkv

# Processing batch di cartella (default per --film: eac3 384k)
./clearvoice078_preset.sh --film /Movies/Collection/
```
</details>

<details>
<summary>📺 Serie TV con Processing Parallelo</summary>

```bash
# Serie con processing parallelo (2x velocità)
./clearvoice078_preset.sh --serie /TV/BreakingBad/Season1/

# Singola serie con codec specifico e processing parallelo
./clearvoice078_preset.sh --serie eac3 320k "Friends.S01*.mkv"

# Batch multiple cartelle con parallelizzazione automatica
for season in /TV/Show/Season*; do
    ./clearvoice078_preset.sh --serie "$season"/
done
```
</details>

<details>
<summary>📺 Materiale Problematico + EQ</summary>

```bash
# Rip di bassa qualità con equalizzazione intelligibile
./clearvoice078_preset.sh --tv /Downloads/LowQuality/*.mkv

# Materiale compresso con preset conservativo
./clearvoice078_preset.sh --tv eac3 384k "problematic_audio.mkv"

# Batch materiale misto problematico
./clearvoice078_preset.sh --tv /Media/Problematic/
```
</details>

<details>
<summary>🎨 Contenuti Speciali</summary>

```bash
# Anime con preservazione musicale
./clearvoice078_preset.sh --cartoni /Anime/StudioGhibli/*.mkv

# Documentari con focus dialoghi (preset --serie)
./clearvoice078_preset.sh --serie /Documentaries/*.mkv

# Mix contenuti con preset automatico (serie, eac3 384k)
./clearvoice078_preset.sh /Media/Mixed/*.mkv
```
</details>

---

## 🆕 Novità v0.78

### 🎛️ **Equalizzatore Intelligibile (NUOVO)**
- 🆕 **Preset TV avanzato** con EQ specifico per materiale problematico
- 🆕 **EQ canale centrale** 300Hz-4kHz per massima intelligibilità dialoghi
- 🆕 **EQ Front L/R** 800Hz-3kHz per enfasi voce su materiale compresso
- 🆕 **Parametri TV aggiornati** per maggiore chiarezza (VOICE_VOL=7.3, compressione leggera)

### 🔧 **Correzioni e Miglioramenti**
- ✅ **Fix definitivo loop principale** per processing completo senza doppia validazione
- ✅ **Rimozione validazione ridondante** dalla funzione process()
- ✅ **Correzioni parsing** parametri compressione dinamica
- ✅ **Fix variabili locali** e gestione array nei filtri audio
- ✅ **Attivazione processing parallelo** per serie TV anche con pattern *.mkv

### 🎧 **Qualità Audio Avanzata**
- 🆕 **Compressore multi-banda** per processing più naturale
- 🆕 **Limitatore intelligente** anti-clipping adattivo specifico per preset
- 🆕 **Crossover LFE precisione** calibrato per SP7 (slopes controllati)
- 🆕 **Resampling SoxR** qualità audiophile con dithering triangular
- 🆕 **Anti-aliasing surround** per canali posteriori cristallini
- 🆕 **Filtri pulizia Front L/R** specifici per ogni preset

### ⚡ **Performance e Usabilità**
- 🚀 **Processing parallelo** (2 processi max per preset --serie con più file)
- 📊 **Statistiche dettagliate** con tempo medio per file
- 🧠 **Gestione automatica risorse** per evitare sovraccarico CPU
- 🔍 **Validazione input avanzata** con analisi formati dettagliata
- 💡 **Suggerimenti conversione** per mono, stereo, 7.1 surround
- 🛠️ **Encoding ottimizzato** (dialnorm, dsur_mode, dts) per ogni codec
- ⚡ **Threading efficiente** con thread_queue_size ottimizzato

---

## 🎧 Configurazione per Soundbar LG SP7 5.1.2 o AVR equivalenti

### ⚙️ **Impostazioni Ottimali**
```
🔊 Sound Mode: Cinema (o Standard/Music a seconda del contenuto)
❌ AI Sound Pro: OFF  
❌ Bass Boost: OFF (controllo LFE già ottimizzato nello script)
❌ Clear Voice (funzione TV/Soundbar): OFF (sostituito da ClearVoice)
❌ Night Mode: OFF
🔧 EQ: Flat/Manuale (evitare curve estreme che interferiscono)
```

### 🧪 **Test Post-Processing**
1. **Dialoghi:** Scene sussurrate (intelligibilità massima)
2. **LFE:** Bassi intensi (controllo boom, no distorsione)
3. **Surround:** Effetti ambientali (chiarezza spaziale)
4. **Dinamica:** Transizioni silenzio→forte (impatto preservato)
5. **Preset TV:** Materiale problematico (chiarezza con EQ)

---

## 🔍 Troubleshooting

<details>
<summary>❌ Errori Comuni</summary>

### "File non 5.1 compatibile"
Lo script processa solo file con traccia audio 5.1. La validazione v0.78 fornisce suggerimenti automatici:
```bash
# Lo script rileva automaticamente il formato e suggerisce:
# MONO rilevato
# 💡 Conversione: ffmpeg -i "file.mkv" -af "pan=5.1|FL=FC|FR=FC|FC=FC|LFE=0|BL=0|BR=0" -c:v copy output_51.mkv

# STEREO rilevato  
# 💡 Upmix a 5.1: ffmpeg -i "file.mkv" -af "surround" -c:v copy output_51.mkv

# 7.1 SURROUND rilevato
# 💡 Downmix a 5.1: ffmpeg -i "file.mkv" -af "pan=5.1|FL=0.5*FL+0.707*FLC|FR=0.5*FR+0.707*FRC|FC=FC|LFE=LFE|BL=BL|BR=BR" -c:v copy output_51.mkv
```

### "DTS encoder not supported"
```bash
# Verifica supporto DTS
ffmpeg -encoders | grep -i dts

# Soluzione: Usa EAC3 o AC3
./clearvoice078_preset.sh --film eac3 384k file.mkv
```

### Processing Parallelo Non Attivo
Il processing parallelo si attiva automaticamente solo per preset `--serie` con più file:
```bash
# ✅ Attiva processing parallelo (2 file contemporaneamente)
./clearvoice078_preset.sh --serie *.mkv          # Più file
./clearvoice078_preset.sh --serie /series/dir/   # Cartella con più file

# ❌ Processing sequenziale (altri preset o singolo file)
./clearvoice078_preset.sh --film file.mkv        # Singolo file
./clearvoice078_preset.sh --cartoni *.mkv        # Altri preset
```
</details>

<details>
<summary>🐛 Debug Avanzato</summary>

```bash
# Analisi completa file con formati supportati
ffprobe -v quiet -print_format json -show_streams input.mkv

# Test con validazione avanzata (fornisce suggerimenti automatici)
./clearvoice078_preset.sh --serie *.mkv

# Debug completo con log
./clearvoice078_preset.sh --film eac3 384k input.mkv > debug.log 2>&1

# Monitor performance processing parallelo (Linux/macOS)
htop # cerca processi ffmpeg multipli
# Windows: Task Manager -> Processi
```
</details>

---

## 📋 Requisiti Tecnici

<details>
<summary>💻 Requisiti Sistema</summary>

### Software
| Componente | Min | Raccomandato | Note |
|------------|-----|--------------|------|
| **FFmpeg** | 6.0+ | 7.1+ | Con supporto SoxR, encoder codec (eac3, ac3, dts) |
| **Bash**   | 4.0+ | 5.0+ | Git Bash su Windows |
| **awk**    | Standard | GNU awk | Parsing parametri e calcoli |
| **bc**     | Standard | Standard | Calcoli matematici avanzati (opzionale) |
| **CPU**    | 2 core | 4+ core | Per processing parallelo ottimale |
| **RAM**    | 4GB | 8GB+ | Per file grandi e processing parallelo |
| **Storage**| ~2x file size | SSD | Spazio per temporanei e output |

### Input Supportati v0.78
- ✅ **5.1 Surround** (layout `5.1` o `5.1(side)` o `unknown`)
- ⚠️ **Altri formati** (conversione automatica suggerita dallo script)

### Output Qualità
- **EAC3:** 320k-640k (default 384k)
- **AC3:** 384k-640k (default 448k)  
- **DTS:** 640k-1536k (default 768k)

</details>

---

## 🤝 Contribuire

### 🐛 **Bug Report**
1. [Crea issue](https://github.com/Damocle77/Clearvoice_5.1/issues/new) usando il template
2. Includi: OS, FFmpeg version (`ffmpeg -version`), bash version
3. Output validazione: `./clearvoice078_preset.sh --serie *.mkv` (mostra analisi formati)
4. Log completo: `./clearvoice078_preset.sh [args] > log.txt 2>&1`

### 💡 **Feature Request**
1. Descrivi caso d'uso e beneficio specifico
2. Specifica hardware target (soundbar/AVR model) se rilevante
3. Fornisci esempi audio problematici, se possibile

### 🧪 **Testing v0.78**
```bash
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1

# Test preset con EQ intelligibile
./clearvoice078_preset.sh --tv test_problematic.mkv

# Test processing parallelo
./clearvoice078_preset.sh --serie test_serie_*.mkv

# Test codec DTS con nuovi parametri
./clearvoice078_preset.sh --film dts 768k test_film.mkv
```

---

## 📄 Licenza

```
MIT License 2025
Copyright (c) Sandro "D@mocle77" Sabbioni
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

---

<div align="center">

## 🎧 **ClearVoice 5.1 v0.78** 
### *Dialoghi Cristallini • Sub Controllato • EQ Intelligibile • Processing Parallelo*

[![⭐ Star](https://img.shields.io/github/stars/Damocle77/Clearvoice_5.1.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1)
[![🍴 Fork](https://img.shields.io/github/forks/Damocle77/Clearvoice_5.1.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1/fork)
[![📥 Download](https://img.shields.io/github/downloads/Damocle77/Clearvoice_5.1/total.svg?style=for-the-badge&logo=github)](https://github.com/Damocle77/Clearvoice_5.1/releases)

*Audio Engineering by Sandro 'D@mocle77' Sabbioni • v0.78 • 2025*

</div>