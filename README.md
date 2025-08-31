# 🎙️ ClearVoice Simple "Adaptive Universal"

Questa pipeline bash+awk avanzata ottimizza l'audio multicanale di film, serie TV e cartoon, garantendo dialoghi sempre chiari e intelligibili anche in presenza di effetti. Bilanciamento dinamico tra canali frontali, surround e LFE, ottimizzazione della voce italiana con regolazioni adattive che valorizzano la scena sonora e riducono la fatica d'ascolto. Filtri automatici e analisi loudness segmentata per una resa professionale.
Compatibile con Linux, macOS, WSL-Win/GitBash.

![SELECT name AS 'Sandro Sabbioni', handle AS 'D@mocle77' FROM developers](https://img.shields.io/badge/SELECT%20name%20AS%20'Sandro%20Sabbioni'%2C%20handle%20AS%20'D%40mocle77'%20FROM%20developers-blue)

---

## Indice


- [Descrizione](#descrizione)
- [Requisiti](#requisiti)
- [Flusso di lavoro tipico](#flusso-di-lavoro-tipico)
- [Installazione](#installazione)
- [Utilizzo](#utilizzo)
- [Output](#output)
- [Script-batch](#script-batch)
- [Perché ClearVoice](#perché-clearvoice)

---


## Descrizione


ClearVoice è uno script Bash avanzato per l'ottimizzazione audio adattiva universale:

	- Ottimizza l'audio multicanale (film, serie TV, cartoon), garantendo dialoghi chiari e intelligibili.
	- Bilanciamento dinamico tra canali frontali, surround e LFE, con regolazioni adattive.
	- Filtri automatici (highpass, equalizer, volume boost) e regolazioni intelligenti per ogni canale.
	- Analisi loudness (LUFS), True Peak e Loudness Range (LRA) su segmenti rappresentativi, calcolati in modo adattivo in base alla durata e tipologia del video.
	- Segmentazione adattiva per analisi loudnorm (Modalità ULTRA):
		- 3 segmenti da 300s (5 min) per video ≤ 30 min
		- 4 segmenti da 350s (5.83 min) per video ≤ 1 ora
		- 6 segmenti da 400s (6.66 min) per video ≤ 2 ore
		- 7 segmenti da 420s (7 min) per video ≤ 2.5 ore
		- 8 segmenti da 480s (8 min) per video ≤ 3 ore
		- 9 segmenti da 500s (8.33 min) per video > 3 ore
	- L'analisi loudnorm richiede solo pochi minuti totali, mantenendo qualità statistica.
	- Regola d'oro: "L'analisi loudnorm non dovrebbe mai richiedere più del 10% del tempo totale di processing".
	- Output compatto pronto per batch/report, diagnostica audio dettagliata e parametri di normalizzazione ottimizzati.
	- Gestione robusta di errori e report automatico al termine.


## Requisiti

- Bash (Linux, macOS, WSL, Windows con Git Bash)
- FFmpeg (>= 7.x, con supporto E-AC3, Filtercomplex)
- ffprobe
- awk


## Flusso di lavoro tipico

### Uso base

```bash
# Script principale (ottimizza la voce in un singolo file)
./clearvoice_simple.sh "file.mkv" [bitrate] [originale] [codec]
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
git clone https://github.com/Damocle77/ClearVoice_Auto_Full.git
cd ClearVoice_Auto_Full
chmod +x *.sh
```
Assicurati che ffmpeg sia nel tuo PATH.

---


## Utilizzo

### Script principale

```bash
./clearvoice_auto_full_4.0.sh "<file_input>" [bitrate] [originale] [codec]
```

- `<file_input>`: File video di input (obbligatorio, es. `film.mkv`)
- `bitrate`: Bitrate audio di output (opzionale, default: 768k). Valori supportati: 256k, 320k, 384k, 448k, 512k, 640k, 768k
- `originale`: yes/no (includi traccia originale, default: yes)
- `codec`: eac3/ac3 (default: eac3)

Esempi:
```bash
./clearvoice_auto_full_4.0.sh "film.mkv"
./clearvoice_auto_full_4.0.sh "film.mkv" 384k no ac3
```

---


## Output

- Il file ottimizzato avrà il suffisso `_clearvoice.mkv`.
- Se `originale` è `yes`, il file conterrà sia la traccia originale che quella ottimizzata (ClearVoice).
- Diagnostica dettagliata in console: loudness, true peak, gamma dinamica, parametri applicati, report finale con integrità e dimensione file.

---


## Script batch

Per processare più file MKV in una cartella:

```bash
./clearvoice_batch_auto_full_4,0.sh [bitrate] [originale] [codec]
```

Esempi:
```bash
./clearvoice_batch_auto_full_4,0.sh
./clearvoice_batch_auto_full_4,0.sh 384k no ac3
```

Il batch esclude i file già processati e mostra report finale con tempo totale e file processati.

## Script semplice

Per migliorare la chiarezza delle voci in un singolo file MKV 5.1:

```bash
./clearvoice_simple.sh "video.mkv" [bitrate] [originale] [codec]
```

- `<video.mkv>`: File video di input (MKV con audio 5.1)
- `bitrate`: Bitrate audio desiderato (default: 768k)
- `originale`: "si"/"no" (includi traccia originale, default: si)
- `codec`: Codec audio di output (default: eac3)

Esempio:
```bash
./clearvoice_simple.sh "film.mkv" 768k si eac3
```

Output:
- Crea un nuovo file "nome_file_clearvoice_simple.mkv" con traccia audio ottimizzata.
- I file di output vengono creati nella stessa directory del file di input.
- Richiede ffmpeg e ffprobe nel PATH.

Note:
- Scegli almeno 386k eac3 o 448k ac3 per serie TV, 640k ac3 o 758k eac3 per film.
- Se il file di origine è 256k puoi selezionare 320k ac3/eac3.

## Perché ClearVoice

- **🔊 Voce sempre in primo piano:** Dialoghi chiari e intelligibili in ogni situazione, anche con effetti e musica.
- **🎵 Qualità audio HD:** Equalizzazione avanzata, processing professionale e compatibilità con AVR, TV e cuffie.
- **🚀 Elaborazione batch:** Perfetto per stagioni intere, archivi, backup e conversioni massive.
- **🌍 Compatibilità universale:** Output EAC3/AC3 robusto, pronto per ogni player e piattaforma.
- **🧠 Zero pensieri:** Logica adattiva, analisi automatica, segmentazione loudnorm intelligente.
- **🛡️ Sicurezza:** Protezione anti-clipping, diagnostica dettagliata, report finale con integrità e dimensione file.
- **💡 Esperienza utente migliorata:** Messaggi statici rassicuranti durante le fasi lunghe, output sempre chiaro.

---

> "Per riportare equilibrio nella Forza sonora ti servono solo un terminale bash e ClearVoice...Questa è la via!"
