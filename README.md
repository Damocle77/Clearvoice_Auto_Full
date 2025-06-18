# 🚀 ClearVoice la Stele di Rosetta per Audio 5.1 🔊

**2025 by "Sandro (D@mocle77) Sabbioni"**

Benvenuto, audionauta! Sei atterrato nella repository che custodisce il segreto per trasformare il tuo audio 5.1 da "uff..." a "mammamia, che spettacolo!". ClearVoice non è un semplice script, è una pipeline tecnologica forgiata per la massima chiarezza dei dialoghi, un controllo LFE innovativo e un audio così immersivo che ti sembrerà di avere una sala multicanale nel salotto!

---

## 🎯 Mission Statement (Perché ti serve questo script)

Hai presente quando guardi un film o una serie e i dialoghi sono soffocati dagli effetti sonori o dalla musica? O quando il subwoofer impazzisce e ti fa tremare le pareti anche durante le scene di dialogo? E quel suono piatto, come se tutto venisse da un unico punto?

ClearVoice è la tua soluzione definitiva. Un algoritmo (in bash e awk, sì, proprio così!) che prende il tuo audio 5.1 e lo passa attraverso un **processo di ottimizzazione multi-stadio**. Il risultato? Dialoghi cristallini, bassi precisi e un ambiente sonoro che ti avvolge completamente.

---

## ✨ Feature List (Le Gemme di ClearVoice)

Ecco cosa rende ClearVoice un *must-have* nella tua toolbelt audio:

* **🎙️ Voice Boost Intelligente con Architettura Multi-Stadio:** Ordine perfetto: Denoise → HPF/LPF → EQ → Compressor → Volume → Limiter. I dialoghi vengono processati attraverso una catena professionale per rimanere sempre in primo piano, senza distorcere. Addio "cosa ha detto?"!
* **🔊 DUCKING LFE MULTI-CANALE RIVOLUZIONARIO:** La funzione killer 2.0! Sidechain REALE basato su mix completo FL+FR+FC. Il subwoofer reagisce all'intero soundstage dialogico, non solo al centro. Parametri professionali: threshold -24dB, ratio 3:1, attack 5ms, release 1500ms. Filtro passa-banda (200-4000Hz) per focalizzazione estrema sui dialoghi.
* **🎭 Soundstage Spaziale PERFEZIONATO:** Delay temporali calibrati e correzione fase sui frontali (32 campioni). Processing differenziato per canali con compressione surround adattiva per ogni preset. Ti sembrerà di sentire l'eco della Death Star!
* **🛡️ Protezione Anti-Clipping Professionale:** Sistema doppio con alimiter + asoftclip programmabile per preset. Threshold variabili (0.90-0.98) per massima fedeltà senza distorsione.
* **🎛️ Crossover LFE Avanzato:** Filtri configurabili highpass/lowpass con poli variabili (35-110Hz) ed EQ parametrico per modellare la risposta del subwoofer. Bassi puliti, precisi e d'impatto.
* **🎚️ Preset Ottimizzati PROFESSIONALI:** Parametri calibrati scientificamente per ogni scenario:
    * `--film`: +8.2dB voice, HPF 85Hz, 3.2x surround, compressione 3.5:1 dolce
    * `--serie`: +8.1dB voice, HPF 95Hz, 3.2x surround, compressione 3.2:1 bilanciata  
    * `--tv`: +7.6dB voice, HPF 350Hz, 3.0x surround, denoise aggressivo
    * `--cartoni`: +8.1dB voice, HPF 75Hz, 3.2x surround, calore vocale preservato
* **⚙️ Supporto Codec Multipli ADATTIVO:** EAC3, AC3 e DTS con adattamenti automatici per ogni codec. DTS con parametri specifici e correzioni HPF/LPF.
* **🌠 SoXR Resampler ADATTIVO:** Precisione variabile per preset (Film: 28-bit, Serie/TV: 20-bit, Cartoni: 18-bit). Fallback intelligente su SWR se SoXR non disponibile.
* **🧠 Gestione Robusta EVOLUTA:** Validazione multi-formato, statistiche dettagliate, batch processing con ETA e resume capability.

---

## 🛠️ Requisiti di Sistema (La Tua Battlestation)

Per far girare questa meraviglia avrai bisogno di:

* **Bash:** Versione >= 4.0 per array associativi avanzati
* **FFmpeg:** Versione >= 6.0 per feature complete (sidechaincompress, filtri avanzati)
* **`awk`:** Per calcoli matematici sicuri e validazione parametri
* **(Opzionale ma raccomandato) SoXR con FFmpeg:** Per resampling di qualità superiore con precisione variabile

---

## 🚀 Guida Rapida all'Uso (Il Tuo Manuale per l'Innesco)

Naviga nella directory dello script e rendilo eseguibile (se non lo è già):

```bash
chmod +x clearvoice093_preset.sh
```

Poi, lancia il comando con i tuoi parametri. La sintassi è intuitiva:

```bash
./clearvoice093_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRECTORIES...]
```

### Esempi Pratici (Comandi per i N00b e i PRO)

* **Ottimizza tutti i file `.mkv` nella directory corrente per le serie TV (preset di default, ducking aggressivo):**
    ```bash
    ./clearvoice093_preset.sh --serie *.mkv
    ```

* **Elabora un film con preset "Film", codec DTS a 768k bitrate:**
    ```bash
    ./clearvoice093_preset.sh --film dts 768k "Il_mio_film_epico.mkv"
    ```

* **Renditi conto che l'audio di quel vecchio DVD rippato è terribile e salvalo col preset "TV", codec AC3 448k:**
    ```bash
    ./clearvoice093_preset.sh --tv ac3 448k "Vecchia_serie_TV_rovinata.mkv"
    ```

* **Dai vita ai cartoni animati con il preset "Cartoni", lasciando il codec e bitrate di default (EAC3 640k):**
    ```bash
    ./clearvoice093_preset.sh --cartoni "Cartone_animato_fantastico.mkv"
    ```

* **Vuoi solo sapere le opzioni disponibili?**
    ```bash
    ./clearvoice093_preset.sh --help
    ```

### Output File (Il Tuo Tesoro Finale)

Lo script genererà un nuovo file nella stessa directory, con un nome simile a:
`nome_del_file_originale_[preset]_clearvoice093.mkv`

La traccia audio ClearVoice sarà impostata come default per una riproduzione automatica senza sbattimenti!

---

## 🧠 Dettagli Tecnici (Per i Veri Ingegneri del Suono)

* **Ducking Multi-Canale:** Mix FL+FR+FC con pesi 0.3|0.3|0.4 per sidechain accurato. Filtro passa-banda focalizzato su dialoghi (200-4000Hz).
* **Architettura Processing:** Ordine rigoroso per ogni canale: Denoise → Filtri → EQ → Compressor → Volume → Limiter.
* **Compressione Surround Adattiva:** Parametri specifici per preset (Film: 2.5:1, Serie: 2.2:1, TV: 2.0:1).
* **Crossover LFE Configurabile:** Poli variabili (2) con EQ parametrico multi-banda per ogni preset.
* **Correzione Fase:** Delay campioni sui frontali (32) per allineamento temporale perfetto.

---


---

## 🗺️ Schema Grafico del Flusso Audio

Per i visual thinkers, ecco un diagramma che rappresenta in modo chiaro e sintetico il flusso di elaborazione audio realizzato da `clearvoice089_preset.sh`.

![Schema Flusso ClearVoice](schema_clearvoice.png)

1. **Input Audio Stream:** file audio 5.1 in formato `.mkv`
2. **Preset Selection:** selezione di uno tra `film`, `serie`, `tv`, `cartoni`
3. **Multi-Stage Voice Processing:** denoise → HPF/LPF → EQ → compressione → volume → limiting
4. **LFE Ducking Multi-Canale:** sidechain FL+FR+FC con filtro passa-banda sui dialoghi
5. **Adaptive Soundstage:** delay differenziati e compressione surround specifica per preset
6. **SOXR Resampling:** precisione adattiva per preset (28/20/18-bit)
7. **Output Audio Stream:** traccia 5.1 ottimizzata con metadata automatico

## 🤝 Contribuisci (Unisciti alla Resistenza Audio!)

Se hai idee, bug da segnalare o vuoi contribuire con miglioramenti al codice, sentiti libero di aprire una Issue o una Pull Request! L'audio di qualità è un diritto, non un privilegio!

---

**Licenza:** Questo script è distribuito sotto licenza MIT.

---

Adesso non ti resta che clonare la repo e far cantare i tuoi altoparlanti! 🎶

---

## 🎯 CARATTERISTICHE PRINCIPALI

- 🎙️ **Voice boost multi-stadio**: Architettura professionale con ordine ottimizzato
- 🔊 **LFE Ducking Multi-Canale**: Sidechain FL+FR+FC con filtro passa-banda dialoghi
- 🌌 **Soundstage adattivo**: Delay calibrati e compressione surround specifica per preset
- 🚫 **Protezione doppia anti-clipping**: alimiter + asoftclip programmabile
- 🎚️ **Crossover LFE configurabile**: Filtri variabili con EQ parametrico multi-banda
- 🎞️ **Preset calibrati scientificamente**: Parametri ottimizzati per ogni contenuto
- 📦 **Codec adattivi**: EAC3, AC3, DTS con correzioni automatiche
- 🧠 **Gestione evoluta**: Validazione multi-formato, statistiche, batch processing
- 🎧 **SoXR adattivo**: Precisione variabile per preset (28/20/18-bit)

---

## 🔬 ANALISI TECNICA DETTAGLIATA

### 1. 🎙️ Processing voce multi-stadio
**FILM**: +8.2dB, HPF 85Hz, EQ 2500Hz (+2.8dB) / 3200Hz (+2.0dB) / 300Hz (-1.5dB)  
**SERIE**: +8.1dB, HPF 95Hz, EQ 2200Hz (+2.5dB) / 2800Hz (+1.8dB) / 300Hz (-1.5dB)  
**TV**: +7.6dB, HPF 350Hz, EQ 2000Hz (+2.2dB) / 3000Hz (+1.8dB) + denoise aggressivo  
**CARTONI**: +8.1dB, HPF 75Hz, EQ 2500Hz (+2.2dB) / 3500Hz (+1.8dB)  
→ Ottimizzato per intelligibilità e naturalezza del parlato

### 2. 🔊 LFE ducking multi-canale intelligente
- Sidechain FL+FR+FC con pesi 0.3|0.3|0.4
- Filtro passa-banda 200-4000Hz per focalizzazione dialoghi
- Parametri professionali: -24dB threshold, 3:1 ratio, 5ms attack, 1500ms release
- Crossover 35-110Hz con EQ parametrico per ogni preset
→ Sub reattivo ma mai invasivo

### 3. 🌌 Soundstaging adattivo per preset
- Delay frontali: 32 campioni (0.67ms) per correzione fase
- Compressione surround differenziata: Film 2.5:1, Serie 2.2:1, TV 2.0:1
- Volume surround calibrato: 3.0-3.2x per ogni preset
→ Immersione ottimale per ogni tipo di contenuto

### 4. 💬 Voce sempre protagonista
- Architettura: Denoise → HPF/LPF → EQ → Compressor → Volume → Limiter
- Compressione 3.0-3.5:1 con attack/release ottimizzati per preset
- Protezione anti-clipping con asoftclip adattivo (0.90-0.98 threshold)
→ Dialoghi cristallini senza affaticamento

### 5. 🧨 Ducking intelligente multi-canale
- Mix completo soundstage dialogico (non solo canale centrale)
- Filtro passa-banda per eliminare rumori e focus su voce
- Fallback automatico se sidechaincompress non disponibile
→ Tecnologia professionale con compatibilità universale

### 6. 🎧 SOXR Resampling Adattivo
- Film: 28-bit (massima qualità cinematografica)
- Serie/TV: 20-bit (bilanciamento qualità/performance)
- Cartoni: 18-bit (ottimizzato per contenuti animati)
→ Qualità variabile intelligente con fallback SWR automatico

---
