# DustCollector

![WoW 3.3.5a (WotLK)](https://img.shields.io/badge/WoW-3.3.5a%20WotLK-a335ee?style=flat-square)
![Version](https://img.shields.io/badge/version-1.2-6f42c1?style=flat-square)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [How it works](#how-it-works) • [FAQ](#faq)

Turn unwanted group loot into enchanting dust, automatically.

**DustCollector** is a tiny World of Warcraft (WotLK 3.3.5) addon that rolls **disenchant** — or **greed** when disenchanting isn't available — on group loot rolls up to a rarity you choose, while leaving anything more valuable for you to decide. Handy for dungeon clears and farm runs where the loot rolls pile up.

## Features

- 🪄 **Auto disenchant or greed** – handles eligible loot rolls without you lifting a finger
- 🎚️ **Configurable rarity ceiling** – from Poor (gray) up to Epic (purple); anything above stays in your hands
- 🛡️ **Safe by design** – never rolls *need*, and only auto-confirms bind-on-pickup prompts for rolls it made itself
- 👤 **Per-character settings** – each character remembers its own state
- 🪶 **Featherweight** – a single Lua file, no dependencies, no setup screen

## Installation

DustCollector targets the WoW 3.3.5a client (interface `30300`).

1. In your WoW installation, make sure the `Interface/AddOns` folder exists.
2. Put the addon files inside a `DustCollector` folder there, for example by cloning this repository directly:
   ```bash
   git clone <your-repo-url> DustCollector
   ```
3. Start the client and enable **DustCollector** in the AddOns list on the character selection screen (use `/reload` if you're already logged in).

The result should look like this:

```text
WoW/
└── Interface/
    └── AddOns/
        └── DustCollector/
            ├── DustCollector.toc
            └── DustCollector.lua
```

> [!TIP]
> The addon ships disabled. Run `/dc on` once, on each character you want it active on — settings are per character.

## Usage

Everything is done from the chat console; there's no configuration screen.

### Commands

| Command | Description |
| --- | --- |
| `/dc on`, `/dc off`, `/dc toggle` | Enable, disable or toggle auto-rolling |
| `/dc rarity <quality>` | Set the highest item quality to roll on (see below) |
| `/dc status` | Show the current settings |
| `/dc` | Same as `/dc status`, plus the command list |

`/dustcollector` is the long-form alias of `/dc`.

### Rarity threshold

| Value | Quality | Color |
| --- | --- | --- |
| 0 | Poor | gray |
| 1 | Common | white |
| 2 | Uncommon | green |
| 3 | Rare | blue |
| 4 | Epic | purple |

The addon rolls on items **at or below** the configured quality and never touches anything above it. The default threshold is `uncommon`, so white and green items are rolled while blues and purples are left to you:

```text
/dc rarity uncommon   – grays, whites and greens are handled (default)
/dc rarity rare       – blues and below are handled
/dc rarity epic       – every eligible roll is handled
```

Quality names and their color aliases (`gray`, `white`, `green`, `blue`, `purple`) and the numeric values (`0`–`4`) are all accepted.

## How it works

DustCollector reacts to the standard group loot roll window:

1. When a roll starts, it checks the item quality against your threshold and ignores anything above it.
2. It rolls **disenchant** when that option is available, otherwise it falls back to **greed**.
3. Bind-on-pickup items ask for confirmation before such a roll; the addon auto-confirms only the prompts for rolls it initiated — your manual rolls are never touched.

> [!NOTE]
> The disenchant roll option is only offered by the client when a player with sufficient enchanting skill is in the group. When it isn't, DustCollector simply greeds instead.

## FAQ

**DustCollector isn't rolling anything — why?**
It ships disabled. Run `/dc on` and check `/dc status` to confirm it's `ON`.

**Why is it greeding instead of disenchanting?**
The disenchant option only appears when an enchanter is in the group. When it isn't, the addon falls back to greed.

**Does it ever roll *need*?**
No. It only rolls disenchant or greed, and leaves items above your rarity threshold untouched.

**Are settings shared between characters?**
No — settings are saved per character (in the `WTF` folder), so each character can have its own state and threshold.