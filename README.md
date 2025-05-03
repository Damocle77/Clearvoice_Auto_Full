# Clearvoice 5.1 – README

> *"Perché accontentarsi di un film qualunque, quando puoi far cantare la tua soundbar LG Meridian SP7 5.1.2 come un coro angelico?"*

Questo script **`clearvoice0.sh`** elabora tracce audio 5.1 in contenitori MKV e le riconfeziona in un mix piú "\:crystal\_ball:" *futuribile* ottimizzato per sound‑bar LG con tecnologia Meridian. Basterà un comando per trasformare dialoghi sommersi e bassi invadenti in un’esperienza sonora precisa, spaziale e – soprattutto – centrata sulla voce.

---

## Indice

1. [Caratteristiche](#caratteristiche)
2. [Prerequisiti](#prerequisiti)
3. [Installazione](#installazione)
4. [Utilizzo rapido](#utilizzo-rapido)
5. [Parametri & personalizzazioni](#parametri--personalizzazioni)
6. [Workflow interno](#workflow-interno)
7. [Troubleshooting](#troubleshooting)
8. [Roadmap & idee future](#roadmap--idee-future)
9. [Licenza](#licenza)

---

## Caratteristiche

* **Split & Delay** – separa i 6 canali, applica ritardi millimetrici per ampliare lo *stage* frontale e surround.
* **Voice‑Boost intelligente** – filtra, equalizza, normalizza e alza la voce del canale FC; addio dialoghi sussurrati.
* **LFE domato** – low‑pass, equalizzazione mirata, compressione e limitatore per bassi puliti e controllati.
* **Codec on‑demand** – *EAC3* (default) o *DTS* con un semplice flag.
* **Batch mode** – nessun file resta indietro: lanciato senza argomenti, processa tutti i `.mkv` presenti.
* **Keep it or kill it** – conserva (o meno) tracce audio originali, sottotitoli e capitoli.

## Prerequisiti

| Dipendenza            | Versione consigliata | Note                                                                                                                             |
| --------------------- | -------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Bash**              | >= 4.x               | Presente di serie su Linux/macOS; su Windows usa WSL o Git Bash.                                                                 |
| **FFmpeg**            | >= 6.x               | Compilato con i filtri `channelsplit`, `speechnorm`, `acompressor`, `alimiter` e – se vuoi GPU speed – con `--enable-cuda-nvcc`. |
| **GPU NVIDIA** (opz.) | Driver CUDA recenti  | Per l’opzione `-hwaccel cuda`.                                                                                                   |

> 💡 **Tip nerd:** su Ubuntu puoi installare FFmpeg build "jonathonf/ffmpeg-6" per avere l’intero pacchetto di filtri senza sudare.

## Installazione

```bash
# Clona (o copia) lo script dove preferisci
mkdir -p ~/bin && cd ~/bin
curl -O https://example.com/clearvoice0.sh
chmod +x clearvoice0.sh
```

Aggiungi *\~/bin* al `$PATH` se necessario – così potrai evocarlo da qualunque directory.

## Utilizzo rapido

```bash
./clearvoice0.sh <codec> <bitrate> [file.mkv]
```

* **`codec`**: `eac3` *(default)* | `dts`
* **`bitrate`**: es. `768k`, `512k`, `384k`
  (se omesso, usa il preset migliore per il codec scelto)
* **`file.mkv`**: facoltativo.
  ➜ Se non lo specifichi, verranno processati **tutti** i `.mkv` nella cartella.

### Esempi

| Azione                                    | Comando                               |
| ----------------------------------------- | ------------------------------------- |
| Converti un singolo file in EAC3 768 kbps | `./clearvoice0.sh eac3 768k film.mkv` |
| Batch DTS a 756 kbps                      | `./clearvoice0.sh dts 756k`           |
| Batch EAC3 bitrate ridotto                | `./clearvoice0.sh eac3 384k`          |

## Parametri & personalizzazioni

Il cuore dello script è una manciata di variabili… modificabili senza varcare il reame pericoloso di *ffmpeg filtergraph*.

| Variabile                                    | Default          | Cosa fa                              |
| -------------------------------------------- | ---------------- | ------------------------------------ |
| `KEEP_ORIGINAL_AUDIO`                        | `true`           | Mantieni tracce audio originali?     |
| `KEEP_SUBTITLES`                             | `true`           | Mantieni sottotitoli & capitoli?     |
| `FRONT_LEFT_DELAY` `FRONT_RIGHT_DELAY`       | `5`, `7` ms      | Allarga lo stage frontale.           |
| `SURROUND_LEFT_DELAY` `SURROUND_RIGHT_DELAY` | `8`, `10` ms     | Ritarda i rear per maggior realismo. |
| `VOICE_VOL`                                  | `4.0` (\~+12 dB) | Boost centrato sui dialoghi.         |
| `LFE_VOL`                                    | `0.10`           | Mix sub ridotto (0‑1).               |
| `LFE_LIMIT`                                  | `0.7`            | Limite massimo output sub.           |
| `SURROUND_VOL`                               | `4.5`            | Gain surround.                       |

> 🔧 **Come modifico?** Apri lo script in un editor, cambia i valori e salva. Non serve ricompilare nulla.

## Workflow interno

```
[MKV 5.1] → channelsplit →
  • FL/FR → delay + EQ + volume
  • SL/SR → delay + EQ + volume
  • FC    → highpass → speechnorm → EQ → limiter
  • LFE   → lowpass → EQ → compressor → limiter
→ join (5.1) → remux via FFmpeg
```

Il tutto avviene in un’unica passata, ***zero*** ricodifica video. Con una GPU NVIDIA il demux/mux è pura formalità.

## Troubleshooting

| Problema                                  | Soluzione                                                                                            |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **`ffmpeg: Unknown filter 'speechnorm'`** | Aggiorna FFmpeg: la build pre‑6.0 non include il filtro.                                             |
| **`-hwaccel cuda: device not found`**     | Assicurati di avere driver NVIDIA e toolkit CUDA installati. In alternativa rimuovi `-hwaccel cuda`. |
| Output audio distorto                     | Riduci `VOICE_VOL` o `LFE_VOL`; assicurati di non superare 0 dBFS nel mix.                           |

## Roadmap & idee future

* [ ] Output **Atmos** (EC‑3 JOC) sperimentale
* [ ] Auto‑detect lingua e rinomina tracce (IT, EN, etc.)
* [ ] GUI cross‑platform in Electron + FFmpeg WASM 🍿

> ✨ **Pull request** & feedback sono i benvenuti – il futuro suona meglio se lo accordiamo insieme.

## Variabili interne (estratte dallo script)

*(generato automaticamente leggendo `clearvoice0.sh` al 3 maggio 2025)*

| Variabile              | Valore di default      |
| ---------------------- | ---------------------- |
| `KEEP_ORIGINAL_AUDIO`  | `true`                 |
| `KEEP_SUBTITLES`       | `true`                 |
| `FRONT_LEFT_DELAY`     | `5` ms                 |
| `FRONT_RIGHT_DELAY`    | `7` ms                 |
| `SURROUND_LEFT_DELAY`  | `8` ms                 |
| `SURROUND_RIGHT_DELAY` | `10` ms                |
| `VOICE_VOL`            | `4.0` (+12 dB approx.) |
| `LFE_VOL`              | `0.10`                 |
| `LFE_LIMIT`            | `0.7`                  |
| `SURROUND_VOL`         | `4.5`                  |

> **Nota bitrate di default**
> Se non specifichi il secondo argomento, lo script imposta automaticamente:
>
> * **EAC3** → `768k`
> * **DTS**  → `756k`

---

## Licenza

Rilasciato con licenza **MIT**. Usa, modifica, condividi senza timore… ma non dare la colpa allo script se il tuo subwoofer decide di fare un *coup d’état* nel soggiorno.
