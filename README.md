# 🎙️ ClearVoice Simple - Binging ⓦ Edition (Nerd Spectral Extended)

Questa pipeline bash+awk avanzata ottimizza l'audio multicanale di film, serie TV e cartoon, garantendo dialoghi sempre chiari e intelligibili anche in presenza di effetti. Bilanciamento dinamico tra canali frontali, surround e LFE, ottimizzazione della voce italiana con regolazioni adattive che valorizzano la scena sonora e riducono la fatica d'ascolto. Analisi LUFS/LRA intelligente per selezione automatica del profilo ottimale.
Compatibile con Linux, macOS, Windows (WSL/GitBash).

![Version](https://img.shields.io/badge/Versione-2.0-blue) ![Audio](https://img.shields.io/badge/Audio-5.1-green) ![FFmpeg](https://img.shields.io/badge/FFmpeg-Required-orange) ![SELECT name AS 'Sandro Sabbioni', handle AS 'D@mocle77' FROM developers](https://img.shields.io/badge/SELECT%20name%20AS%20'Sandro%20Sabbioni'%2C%20handle%20AS%20'D%40mocle77'%20FROM%20developers-blue)

---

## Indice


- [Descrizione](#descrizione)
- [Requisiti](#requisiti)
- [Profili Audio](#profili-audio)
- [Installazione](#installazione)
- [Utilizzo](#utilizzo)
- [Output](#output)
- [Script-batch](#script-batch)
- [Parametri di Elaborazione](#parametri-di-elaborazione)
- [Perché ClearVoice](#perché-clearvoice)

---


## Descrizione

ClearVoice è uno script Bash avanzato per l'ottimizzazione audio adattiva universale:

	- Ottimizza l'audio multicanale (film, serie TV, cartoon), garantendo dialoghi chiari e intelligibili.
	- Bilanciamento dinamico tra canali centrale, frontali, surround e LFE, con regolazioni adattive.
	- Filtri automatici (highpass, equalizer, volume boost, surround boost) e regolazioni intelligenti per ogni canale.
    - Focus EQ particolare sull'intelligibilità della voce italiana.
	- Analisi loudness (LUFS), True Peak e Loudness Range (LRA) su segmenti rappresentativi, calcolati in modo adattivo.
	- Selezione automatica del profilo audio in base ai valori LUFS/LRA rilevati (Action, Netflix, Cartoon o Alta Dinamica).
	- Segmentazione adattiva ottimizzata:
		- 3 segmenti da 210s per video ≤ 30 min
		- 4 segmenti da 240s per video ≤ 60 min
		- 5 segmenti da 270s per video ≤ 90 min
		- 6 segmenti da 300s per video ≤ 120 min
		- 7 segmenti da 330s per video > 120 min
	- Visualizzazione colorata dei parametri applicati: Voice Boost, LFE Factor, Surround Boost, Front.
	- Output compatto pronto per batch/report e diagnostica audio semplificata.
	- Gestione robusta di errori e report automatico semplificato al termine.
    - Ottimizzato per AVR e Soundbar Premium moderne con DSP digitali multicanale (>= 5.1).


## Requisiti

- **Bash** (Linux, macOS, WSL, o Windows con Git Bash)
- **FFmpeg** (>= 7.x con supporto E-AC3, Filtercomplex)
- **ffprobe**
- **awk**
- **bc** (basic calculator per confronti floating-point)


## Profili Audio

Lo script analizza i valori LUFS (Loudness Units Full Scale) e LRA (Loudness Range) per selezionare automaticamente il profilo audio più adatto:

| Profilo | Condizione LUFS | Condizione LRA | Tipo di Contenuto |
|---------|----------------|---------------|-------------------|
| Action/Horror/Sci-Fi | < -18.5 | > 12 | Film d'azione, horror, fantascienza |
| Amazon/Netflix/Pop/Binge | -18.5 a -15.5 | 8 a 12 | Serie TV streaming, film mainstream |
| Cartoon/Disney/Musical | > -18.5 | < 8 | Cartoni animati, musical, anime |
| Alta Dinamica/Blockbuster/Disaster | Altri casi | Altri casi | Film ad alta dinamica, blockbuster |

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
./clearvoice_simple.sh "<file_input>" [bitrate] [originale] [codec]
```

- `<file_input>`: File video di input (obbligatorio, es. `film.mkv`)
- `bitrate`: Bitrate audio di output (opzionale, default: 768k). Valori supportati: 256k, 320k, 384k, 448k, 512k, 640k, 768k
- `originale`: yes/no (includi traccia originale, default: yes)
- `codec`: eac3/ac3 (default: eac3)

Esempi:
```bash
./clearvoice_simple.sh "film.mkv"
./clearvoice_simple.sh "film.mkv" 384k no ac3
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
./clearvoice_simple_batch.sh [bitrate] [originale] [codec]
```

Esempi:
```bash
./clearvoice_simple_batch.sh 384k no ac3
```

Il batch esclude i file già processati e mostra report finale con tempo totale e file processati.

## Parametri di Elaborazione

Per ogni profilo, lo script applica parametri ottimizzati:

- **Voice Boost**: Potenziamento del canale centrale (2.1-2.15 dB)
- **LFE Factor**: Fattore di riduzione del subwoofer (0.48-0.54)
- **Surround Boost**: Potenziamento dei canali surround (2.05-2.15 dB)
- **Front**: Regolazione dei canali frontali (1.0 dB)

Questi parametri vengono visualizzati a schermo con una formattazione colorata per una facile lettura:

```
[Parametri] Voice Boost: 2.15 dB | LFE Factor: 0.52 | Surround Boost: 2.1 dB | Front: 1.0 dB
```

Note:
- Scegli almeno 386k eac3 o 448k ac3 per serie TV, 640k ac3 o 758k eac3 per film.
- Se il file di origine è 256k puoi selezionare 320k ac3/eac3.

Output:
- Crea un nuovo file "nome_file_clearvoice_simple.mkv" con traccia audio ottimizzata.
- I file di output vengono creati nella stessa directory del file di input.
- Richiede ffmpeg e ffprobe nel PATH.

## Perché ClearVoice

- **🔊 Voce sempre in primo piano:** Dialoghi chiari e intelligibili in ogni situazione, anche con effetti e musica.
- **🎵 Qualità audio HD:** Equalizzazione avanzata, processing professionale e compatibilità con AVR, TV e cuffie.
- **🚀 Elaborazione batch:** Perfetto per stagioni intere, archivi, backup e conversioni massive.
- **🌍 Compatibilità universale:** Output EAC3/AC3 robusto, pronto per ogni player e piattaforma.
- **🧠 Zero pensieri:** Logica adattiva basata su LUFS/LRA, analisi automatica, selezione profilo intelligente.
- **🛡️ Sicurezza:** Protezione anti-clipping, diagnostica dettagliata, visualizzazione parametri colorata.
- **💡 Esperienza utente migliorata:** Visualizzazione chiara dei parametri applicati, output sempre comprensibile.

## Novità della versione "Binging ⓦ Edition"

- **🎭 Profili multipli:** Selezione automatica tra Action/Horror, Netflix/Binge, Cartoon/Disney, Alta Dinamica
- **📊 Range ottimizzati:** Soglie LUFS/LRA ottimizzate per lo "Spider-Verse dell'audio"
- **🎛️ Visualizzazione parametri:** Output colorato dei parametri applicati
- **🧪 Segmentazione efficiente:** Analisi ridotta da 9 a 7 segmenti massimi per ottimizzare i tempi
- **🔧 Calcoli floating-point:** Confronti più affidabili tramite awk per sistemi senza bc

---

> "Per riportare equilibrio nella Forza sonora ti servono solo un terminale bash e ClearVoice...Questa è la via!"
