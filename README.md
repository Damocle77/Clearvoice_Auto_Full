# 🎧 CLEARVOICE - Suite Avanzata per l'Ottimizzazione Audio 5.1

**Script professionali per l'elaborazione audio ottimizzati per chiarezza dialoghi e controllo LFE**

[![Versione](https://img.shields.io/badge/versione-0.76-blue.svg)](https://github.com/Damocle77/Clearvoice_5.1/releases)
[![Licenza](https://img.shields.io/badge/licenza-Open%20Source-green.svg)](LICENSE)
[![Piattaforma](https://img.shields.io/badge/piattaforma-Linux%20%7C%20Windows-lightgrey.svg)](#requisiti)
[![Audio](https://img.shields.io/badge/audio-5.1%20Surround-orange.svg)](#caratteristiche)

> **Autore:** Sandro "D@mocle77" Sabbioni  
> **Testato su:** LG SP7 5.1.2, Sistemi AVR vari, Windows 11, Linux, ffmpeg 7.x

---

## 📁 Struttura Repository

Questo repository contiene due versioni dello script con preset ottimizzati:

### 🎬 [CLEARVOICE 0.76 - Preset Avanzato](docs/README_clearvoice076_preset.md)
**Raccomandato per la maggior parte degli utenti** - Versione più recente con funzionalità avanzate

- **File:** `clearvoice076_preset.sh`
- **Caratteristiche:** 3 preset specializzati + processing parallelo
- **Novità:** Elaborazione 2 file contemporaneamente per serie TV
- **Ideale per:** Utilizzo quotidiano, batch processing veloce
- **Documentazione:** [📖 Guida Completa v0.76](docs/README_clearvoice076_preset.md)

### 🎭 [CLEARVOICE 0.75 - Preset Base](docs/README_clearvoice075_preset.md)
**Versione stabile** - Funzionalità essenziali senza complessità aggiuntive

- **File:** `clearvoice075_preset.sh`
- **Caratteristiche:** 3 preset specializzati base
- **Focus:** Stabilità, compatibilità, semplicità
- **Ideale per:** Sistemi più vecchi, uso occasionale
- **Documentazione:** [📖 Guida Completa v0.75](docs/README_clearvoice075_preset.md)

---

## 🚀 Guida alla Scelta

### Quale Versione Usare?

| Script | Raccomandato Per | Vantaggi | Limitazioni |
|--------|------------------|----------|-------------|
| **v0.76** | Utenti normali, elaborazione frequente | ⚡ Processing parallelo<br>🔧 Funzioni avanzate<br>📊 Statistiche dettagliate | Maggiore complessità |
| **v0.75** | Sistemi legacy, uso sporadico | 🛡️ Massima stabilità<br>💾 Meno risorse<br>✅ Compatibilità estesa | Nessun processing parallelo |

### 💡 Raccomandazioni d'Uso

#### Scegli **v0.76** se:
- ✅ Elabori spesso cartelle con molti file (serie TV)
- ✅ Hai un sistema moderno (CPU multi-core, RAM 8GB+)
- ✅ Vuoi le migliori performance

#### Scegli **v0.75** se:
- ✅ Sistema più vecchio o con risorse limitate
- ✅ Elabori principalmente file singoli
- ✅ Preferisci la massima stabilità

---

## 🚀 Avvio Rapido

### 1. Installazione

```bash
# Clona repository
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1

# Rendi eseguibili gli script
chmod +x clearvoice076_preset.sh
chmod +x clearvoice075_preset.sh

# Verifica installazione
./clearvoice076_preset.sh --help
```

### 2. Test Rapido

```bash
# Test v0.76 (raccomandato)
./clearvoice076_preset.sh --serie "test.mkv"

# Test v0.75 (stabile)
./clearvoice075_preset.sh --serie "test.mkv"
```

### 3. Esempi Pratici

#### CLEARVOICE 0.76 (Processing Parallelo)
```bash
# Serie TV - 2 file contemporaneamente
./clearvoice076_preset.sh --serie /path/to/series/

# Film singolo alta qualità
./clearvoice076_preset.sh --film dts 768k "Film.mkv"

# Cartoni animati con codec AC3
./clearvoice076_preset.sh --cartoni ac3 448k "Anime.mkv"

# Elaborazione tutti i .mkv nella cartella corrente
./clearvoice076_preset.sh --serie eac3 384k
```

#### CLEARVOICE 0.75 (Stabile)
```bash
# Serie TV elaborazione sequenziale
./clearvoice075_preset.sh --serie *.mkv

# Film con preset ottimizzato
./clearvoice075_preset.sh --film dts 768k "Film.mkv"

# Batch processing con preset default
./clearvoice075_preset.sh --cartoni
```

---

## ✨ Confronto Caratteristiche

### Funzionalità Base (Entrambe le Versioni)

| Caratteristica | v0.75 | v0.76 |
|----------------|-------|-------|
| **3 Preset Specializzati** | ✅ | ✅ |
| **Multi-Codec Support** | ✅ | ✅ |
| **Controllo LFE Anti-Boom** | ✅ | ✅ |
| **Accelerazione Hardware** | ✅ | ✅ |
| **Batch Processing** | ✅ | ✅ |

### Funzionalità Avanzate

| Caratteristica | v0.75 | v0.76 |
|----------------|-------|-------|
| **Processing Parallelo** | ❌ | ✅ (2 file) |
| **Compressore Multi-Banda** | ❌ | ✅ |
| **Limitatore Intelligente** | ❌ | ✅ |
| **Statistiche Dettagliate** | Basic | ✅ Avanzate |
| **Threading Ottimizzato** | ❌ | ✅ |
| **Gestione Risorse Avanzata** | Basic | ✅ Intelligente |

---

## 📊 Performance Benchmark

### Tempo Elaborazione (Serie TV - 10 Episodi)

| Versione | Modalità | Tempo Stimato | Utilizzo CPU | Raccomandato Per |
|----------|----------|---------------|--------------|------------------|
| **v0.76** | Parallelo | ~25-30 min | 80-95% | CPU 6+ core |
| **v0.75** | Sequenziale | ~40-50 min | 60-80% | CPU 4+ core |

### Risorse Sistema

| Versione | RAM Minima | Storage Temp | Complessità |
|----------|------------|--------------|-------------|
| **v0.76** | 6GB | 2x file size | ⭐⭐⭐ |
| **v0.75** | 4GB | 2x file size | ⭐⭐☆ |

---

## 🎭 Preset Disponibili

### Configurazioni Ottimizzate

| Preset | Voice Boost | LFE Control | Compressione | Ideale Per |
|--------|-------------|-------------|--------------|------------|
| **--film** | 8.5 (+1.2) | -17% | Cinematografica | Action, Drama, Thriller |
| **--serie** | 8.6 (+1.5) | -20% | TV Optimized | Serie TV, Documentari |
| **--cartoni** | 8.2 (+0.8) | -8% | Musicale | Animazione, Anime |

### Miglioramenti v0.76

- 🎛️ **Compressore Multi-Banda:** Controllo naturale range dinamico
- 🔊 **Limitatore Intelligente:** Anti-clipping con lookahead adattivo
- 📊 **Crossover LFE Precisione:** Sintonia specifica per SP7
- 🚀 **Processing Parallelo:** Solo per preset `--serie` su cartelle

---

## 📋 Requisiti di Sistema

### Dipendenze Essenziali
- **ffmpeg** 6.0+ (7.0+ raccomandato per v0.76)
- **awk** (GNU awk preferito)
- **bash** 4.0+

### Piattaforme Supportate
- ✅ **Linux** (Ubuntu, Debian, CentOS, Arch)
- ✅ **Windows** (WSL, Git Bash, MSYS2)

### Hardware Raccomandato

| Componente | v0.75 Minimo | v0.76 Raccomandato |
|------------|--------------|-------------------|
| **CPU** | 4 core | 6+ core |
| **RAM** | 4GB | 8GB |
| **GPU** | Opzionale | NVIDIA/Intel/AMD |

---

## 📚 Documentazione Completa

### Guide Specifiche per Versione
- 📖 **[CLEARVOICE 0.76 - Guida Completa](docs/README_clearvoice076_preset.md)**
  - Processing parallelo
  - Funzioni avanzate v0.76
  - Ottimizzazioni performance
  - Risoluzione problemi specifici

- 📖 **[CLEARVOICE 0.75 - Guida Completa](docs/README_clearvoice075_preset.md)**
  - Versione stabile
  - Compatibilità estesa
  - Utilizzo base
  - Troubleshooting comune

### Risorse Aggiuntive
- [Guida Installazione Rapida](docs/QUICK_INSTALL.md)
- [Risoluzione Problemi](docs/TROUBLESHOOTING.md)
- [Ottimizzazione Performance](docs/PERFORMANCE.md)
- [Impostazioni Audio Sistema](docs/AUDIO_SETUP.md)

---

## 🔄 Migrazione tra Versioni

### Da v0.75 a v0.76
```bash
# Backup configurazione attuale
cp clearvoice075_preset.sh clearvoice075_preset.sh.backup

# Test v0.76 con stesso preset
./clearvoice076_preset.sh --serie test_file.mkv

# Se soddisfatto, usa v0.76 come principale
```

### Compatibilità Output
- ✅ **File Output:** Compatibili tra tutte le versioni
- ✅ **Metadata:** Standard mantenuti
- ✅ **Codec:** Stessi parametri di qualità
- ✅ **Naming:** Schema consistente `_[preset]_clearvoice0.mkv`

---

## 🛠️ Installazione Automatica

### Installer Intelligente
```bash
# Download e setup automatico
curl -fsSL https://raw.githubusercontent.com/Damocle77/Clearvoice_5.1/main/install.sh | bash

# L'installer:
# 1. Rileva il sistema
# 2. Installa dipendenze
# 3. Configura script
# 4. Esegue test di verifica
# 5. Raccomanda versione ottimale
```

### Setup Personalizzato
```bash
# Clone manuale
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1

# Installa solo dipendenze necessarie
./setup.sh --minimal  # v0.75
./setup.sh --full     # v0.76
```

---

## 🤝 Contribuire al Progetto

### Come Contribuire
1. **Fork** del repository
2. **Crea** branch feature (`git checkout -b feature/miglioramento`)
3. **Test** su entrambe le versioni se applicabile
4. **Commit** modifiche (`git commit -m 'Descrizione'`)
5. **Push** al branch (`git push origin feature/miglioramento`)
6. **Apri** Pull Request

### Aree Prioritarie
- 🆕 **Nuovi Preset:** Casi d'uso aggiuntivi
- 🚀 **Performance v0.76:** Ottimizzazioni processing parallelo
- 🛡️ **Stabilità v0.75:** Compatibilità sistemi legacy
- 📖 **Documentazione:** Guide specifiche per versione
- 🧪 **Testing:** Diversi sistemi audio e configurazioni

---

## 📞 Supporto e Community

### Ottenere Aiuto

#### Per Problemi Specifici Versione
- **v0.76:** [Issues v0.76](https://github.com/Damocle77/Clearvoice_5.1/issues?q=label%3Av0.76)
- **v0.75:** [Issues v0.75](https://github.com/Damocle77/Clearvoice_5.1/issues?q=label%3Av0.75)

#### Supporto Generale
- 📋 **GitHub Issues:** Problemi tecnici
- 💬 **Discussions:** Domande generali
- 📖 **Wiki:** FAQ e guide approfondite

### Community
- 🎧 **Reddit:** r/hometheater, r/audiophile
- 💭 **Discord:** [Community Audio Processing](link-to-discord)
- 📺 **YouTube:** Tutorial e confronti

---

## 📄 Licenza e Informazioni

### Licenza
Open Source - Libero per uso personale e commerciale

### Versioning e Support
- **v0.76:** Versione attiva, aggiornamenti continui
- **v0.75:** Versione LTS, solo bugfix critici

### Credits
- **Autore:** Sandro "D@mocle77" Sabbioni
- **Testing Community:** Utenti LG SP7 e sistemi audio vari
- **Tecnologie:** ffmpeg, SoxR, best practice ingegneria audio

---

**CLEARVOICE Suite** - *La soluzione completa per dialoghi cristallini* 🎧✨

[📖 v0.76 Guide](docs/README_clearvoice076_preset.md) | [📖 v0.75 Guide](docs/README_clearvoice075_preset.md) | [🚀 Quick Start](#avvio-rapido)
