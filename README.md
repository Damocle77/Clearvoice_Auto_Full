# 🎙️ ClearVoice Auto – "Zen Mastering Edition" – v3.5.2

Ottimizza la voce nei tuoi video con analisi spettrale avanzata e logica adattiva.
Dialoghi cristallini, bassi controllati, mix professionale.
Funziona su Linux, macOS, WSL e Windows (Git Bash).

![SELECT name AS 'Sandro Sabbioni', handle AS 'D@mocle77' FROM developers](https://img.shields.io/badge/SELECT%20name%20AS%20'Sandro%20Sabbioni'%2C%20handle%20AS%20'D%40mocle77'%20FROM%20developers-blue)

---

## Indice

 - [Cosa fa ClearVoice Auto Full](#cosa-fa-clearvoice-auto-full)
 - [Flusso di lavoro tipico](#flusso-di-lavoro-tipico)
 - [Requisiti](#requisiti)
 - [Installazione](#installazione)
 - [Utilizzo](#utilizzo)
 - [Script ausiliario batch](#script-ausiliario-batch)
 - [Perché scegliere ClearVoice](#perché-scegliere-clearvoice)

---

## Descrizione

ClearVoice Auto è uno script Bash che analizza, normalizza e ottimizza l'audio dei tuoi video (film, serie TV, cartoni) per massimizzare la chiarezza dei dialoghi e la qualità generale. Tutti i parametri audio sono adattivi e modulati in tempo reale in base all'analisi spettrale (LUFS, True Peak, LRA, RMS/Peak multi-banda).

Principali funzionalità:
- Analisi automatica dei livelli audio (LUFS, True Peak, LRA) secondo EBU R128.
- Voice boost chirurgico e compressione adattiva.
- Riduzione/boost dinamico di frontali, surround e LFE.
- Makeup gain automatico per loudness target.
- Diagnostica avanzata e protezione anti-clipping.
- Compatibilità con layout audio "unknown" (5.1).

## Requisiti

- Bash (Linux, macOS, WSL, Windows con Git Bash)
- FFmpeg (>= 7.x, con supporto E-AC3, Filtercomplex)
- ffprobe
- awk

## Flusso di lavoro tipico

### Uso base

```bash
# Script principale (ottimizza la voce in un singolo file)
./clearvoice_auto_full.sh "file.mkv" [bitrate] [originale]
```

---

## Requisiti

- **Bash** (Linux, macOS, WSL, o Windows con Git Bash)
- **FFmpeg** (>= 7.x con supporto E-AC3, Filtercomplex, Audiograph)

---

## Installazione

```bash
# Windows (Git Bash)
winget install ffmpeg -e
winget install Git.Git -e

# Debian/Ubuntu
sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Clona il progetto
git clone https://github.com/Damocle77/ClearVoice_Batch_Auto_Full.git
cd clearvoice_batch_auto_full
chmod +x *.sh
```
Assicurati che ffmpeg sia nel tuo PATH.

---

## Utilizzo

### Script principale

```bash
./clearvoice_auto_full.sh "<file_input>" [bitrate] [originale] [codec]
```

- `<file_input>`: File video di input (obbligatorio, es. `film.mkv`)
- `bitrate`: Bitrate audio di output (opzionale, default: 768k). Valori supportati: 256k, 320k, 384k, 448k, 512k, 640k, 768k
- `originale`: yes/no (includi traccia originale, default: yes)
- `codec`: ac3/eac3

Esempi:
```bash
./clearvoice_auto_full.sh "film.mkv" 
./clearvoice_auto_full.sh "film.mkv" 384k no ac3
```

---

## Output

- Il file ottimizzato avrà il suffisso `_clearvoice_auto.mkv`.
- Se `originale` è `yes`, il file conterrà sia la traccia originale che quella ottimizzata (ClearVoice).
- Diagnostica dettagliata in console: loudness, true peak, gamma dinamica, parametri applicati.

---

## Perché scegliere ClearVoice

- **🔊 Voce sempre in primo piano:** Dialoghi chiari e intelligibili in ogni situazione, anche con effetti e musica.
- **🎵 Qualità audio HD:** Equalizzazione avanzata, processing professionale e compatibilità con home theater, TV, cuffie e streaming.
- **🚀 Elaborazione batch:** Perfetto per stagioni intere, archivi, backup e conversioni massive.
- **🌍 Compatibilità universale:** Output EAC3 robusto, pronto per ogni player e piattaforma.

- **🧠 Zero pensieri:** Logica adattiva e analisi automatica, nessun parametro da settare manualmente.
- **🛡️ Sicurezza:** Protezione anti-clipping e diagnostica dettagliata per risultati sempre affidabili.
- **💡 Esperienza utente migliorata:** Nessun file di log temporaneo, messaggi statici rassicuranti durante le fasi lunghe, output sempre chiaro.

---

---

> "Per riportare equilibrio nella Forza ti servono solo un terminale bash e ClearVoice Batch Auto Full. Questa è la via!"
