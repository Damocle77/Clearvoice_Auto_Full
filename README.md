# 🎧 ClearVoice Preset Suite – Versione 0.89

Una collezione di preset audio avanzati e script bash costruiti attorno a `ffmpeg`, per **migliorare la chiarezza del parlato**, controllare le dinamiche e ottimizzare l’esperienza multicanale su soundbar 5.1/5.1.2 e home theater moderni.

Testato e ottimizzato per soundbar **LG Meridian SP7** e AVR simili.

---

## 🎯 Obiettivo

ClearVoice nasce per risolvere i seguenti problemi comuni nel consumo di contenuti audio multicanale:

- Voce poco intellegibile, specialmente a basso volume
- Subwoofer eccessivo o invadente in mix DTS
- Surround caotico o poco definito
- Mix sbilanciato per ascolti in ambienti domestici

---

## 🆕 Novità v0.89

Questa versione introduce una serie di migliorie strutturate per ottenere un’esperienza d’ascolto bilanciata, focalizzata e non affaticante.

### 🔊 Controllo Vocale Intelligente
- Il canale **Center (FC)** riceve elaborazione prioritaria: equalizzazione mirata, compressione leggera, e nessun delay.
- I canali **Frontali (FL/FR)** vengono abbassati (es. da 0.86 → 0.78) per dare più spazio percettivo al parlato.

### 🔇 LFE (Subwoofer) Addomesticato
- Compressione dinamica soft + ducking legato al parlato (via sidechaincompress)
- Aggiunta di `alimiter` post-compressore per evitare picchi distruttivi nei mix DTS
- Volume LFE ridotto su tracce DTS per compensare mixaggi aggressivi

### 🧠 Soundstage e Ritardi Temporali (Haas Effect)
- Introduzione di ritardi minimi tra i canali:
  - `FR = 0.4 ms`
  - `BL = 0.8 ms`
  - `BR = 1.2 ms`
- Questi micro-delay amplificano la percezione spaziale senza introdurre eco

### 🔬 Pulizia Fase e Compatibilità
- Rimosso il filtro `stereotools` (causava incoerenze di fase con soundbar DSP)
- Nessuna elaborazione invasiva sul canale `FC` (dialoghi sempre ben ancorati)
- Funziona con contenuti **EAC3**, **AC3**, **DTS**

---

## 🧪 Esempio di Utilizzo

```bash
bash clearvoice088_preset.sh --preset film --codec dts
```

Opzioni:

- `--preset` → `film`, `tv`, `music`
- `--codec` → `eac3`, `ac3`, `dts`

---

## 🛠️ Presets disponibili

| Preset | Voce | LFE | Surround | Note |
|--------|------|-----|----------|------|
| `film` | 🎙️ Alta | 🎚️ Controllato | 🎧 Medio | Bilanciato per contenuti cinematografici |
| `tv`   | 📢 Molto alta | 🔇 Morbido | 🔈 Leggero | Ideale per flussi compressi e parlato TV |
| `music` | 🎵 Neutro | 🎵 Neutro | 🎵 Ampio | Audio stereo o 5.1 musicale |
| `game` | 🕹️ Definito | 💥 Intenso | 🎮 Ampio | Mix reattivo per effetti e immersione |

---

## 📦 Requisiti

Per eseguire ClearVoice:

- Linux o macOS (o WSL/GitBash su Windows)
- `ffmpeg` compilato con i seguenti filtri:
  - `firequalizer`
  - `dynaudnorm`
  - `sidechaincompress`
  - `alimiter`
- Uscita audio 5.1 o superiore (fisica o virtuale)

---

## 🧰 File contenuti

- `clearvoice087_preset.sh` – Preset precedente
- `clearvoice088_preset.sh` – Preset attuale aggiornato
- `README.md` – Questo documento

---

## 🤖 Filosofia Nerd

ClearVoice è scritto per nerd dell’audio e appassionati di home theater che vogliono:

- Massima comprensione vocale anche a basso volume
- Esperienza immersiva senza artifici invasivi
- Controllo totale sui comportamenti dinamici dei mix moderni

Le regolazioni sono modulabili e commentate all'interno dello script, con possibilità di:

- Adattare gain, compressione e ritardo per ciascun canale
- Includere/excludere filtri dinamici come `dynaudnorm`
- Ottimizzare singolarmente preset per codec e contenuto

---

## 📡 Futuri possibili sviluppi

- GUI semplificata per controllo rapido dei preset
- Profilazione automatica codec/input
- Auto-levelling basato su analisi RMS real-time

---

## 👨‍💻 Autore

Scritto con passione e "orecchio" da **Sandro (D@mocle77) Sabbioni**,  
ingegnere informatico, nerd del suono, cultore dell’intelligibilità vocale.

---

## 📜 Licenza

MIT License — Usa, modifica, migliora e condividi liberamente.
