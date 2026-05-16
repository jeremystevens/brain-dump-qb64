# ▓▓ BRAIN DUMP QB64 ▓▓
### `// RETRO KNOWLEDGE MANAGEMENT SYSTEM // v2.0`

> *"The net is vast and infinite."*
> A second-brain terminal for the cyberdeck age — built in QB64.

---

```
╔══════════════════════════════════════════════════════════════╗
║  BRAIN DUMP QB64 — RETRO KNOWLEDGE MANAGEMENT SYSTEM        ║
║  INITIALIZING RETRO MEMORY CORE...                          ║
║  LOADING KNOWLEDGE DATABASE........................ [READY]  ║
║  SYSTEM READY.                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## `> OVERVIEW`

**Brain Dump QB64** is a fully modular, retro terminal-style idea and knowledge management system written in [QB64-PE](https://www.qb64phoenix.com/). It captures, organises, searches, and exports your ideas inside an immersive ASCII UI with themed visuals, CRT effects, and retro sound design.

Built across two development phases — a core feature foundation and a full retro UX layer — every system is modular, expandable, and built to last.

---

## `> FEATURES`

### `// PHASE 1 — CORE SYSTEMS`

| System | Description |
|---|---|
| **Idea Capture** | Write, tag, and save ideas to `ideas.txt` |
| **Priority System** | Assign `NONE / LOW / MED / HIGH / CRITICAL` to every idea |
| **Favorites System** | Star ideas with `[*]` — searchable and filterable |
| **Search Everything** | Full-text search with operators: `tag:` `priority:` `fav:true` `starred:true` |
| **Search by Tag** | Fast hashtag search with priority and favorite badges |
| **Export Modes** | Export to `.txt` `.md` `.json` `.html` — all ideas, favorites, or search results |
| **Delete Idea** | Placeholder — manual edit via `ideas.txt` |

### `// PHASE 2 — RETRO UX LAYER`

| System | Description |
|---|---|
| **ASCII UI Panels** | Bordered windows, titled boxes, dividers, text alignment helpers |
| **Window Renderer** | Named screen regions — title bar, content area, status bar, popups |
| **Retro UI Mode** | Typed-out boot sequence, animated cursor, fullscreen terminal feel |
| **Theme Engine** | 3 built-in themes — persistent across sessions via `theme.cfg` |
| **CRT Effects** | Scanlines, flicker, glow — all optional, theme-controlled |
| **Sound Design** | Theme-aware retro audio — keypress ticks, boot beeps, confirm chimes |

---

## `> THEMES`

Change theme from the main menu — selection is saved automatically and reloads on next launch.

```
┌─────────────────────────────────────────────────────────┐
│  1.  FALLOUT TERMINAL   — Green on black                │
│       Warm phosphor glow. Vault-tec analog terminal.    │
│                                                         │
│  2.  DOS HACKER SYSTEM  — White on blue                 │
│       Sharp. Fast. Classic PC command-line authority.   │
│                                                         │
│  3.  CYBERDECK NOTEBOOK — Cyan/magenta on black         │
│       Neon aesthetic. Synth pulses. Field terminal.     │
└─────────────────────────────────────────────────────────┘
```

Theme persistence is handled by `theme.cfg` — a single-line config file written on every theme change.

---

## `> SEARCH OPERATORS`

```
build app                   → keyword search
tag:game                    → filter by hashtag
priority:high               → filter by priority level (none/low/med/high/critical)
fav:true                    → favorites only
starred:true                → same as fav:true
tag:work priority:critical  → combine operators
```

Search results display priority badges `[HIGH]` and favorite badges `[*]` inline. Results can be exported directly after any search.

---

## `> DATA FORMAT`

Ideas are stored in plain text — one idea per line:

```
[MM-DD-YYYY HH:MM:SS] idea text | #tag1 #tag2 priority:3 fav:1
```

- `priority:N` is omitted for `NONE` — old ideas are backward-compatible
- `fav:1` is omitted when not starred — old ideas default to unfavorited
- The file is human-readable and editable in any text editor

---

## `> EXPORT FORMATS`

| Format | Extension | Best for |
|---|---|---|
| Plain Text | `.txt` | Any text editor, notes apps |
| Markdown | `.md` | GitHub, wikis, documentation |
| JSON | `.json` | Backups, APIs, machine processing |
| HTML | `.html` | Browser viewing, sharing — retro dark theme included |

Export sources: **All ideas**, **Favorites only**, or **current Search results**.

Filenames are auto-generated with timestamps: `ideas_export_05-15-2026_21-37.txt`

---

## `> PROJECT STRUCTURE`

```
brain-dump-new/
│
├── main.bas                    ← Entry point, all CONST/TYPE/DIM SHARED
│
├── audio/
│   ├── sound_manager.bas       ← ONLY file with SOUND/BEEP/PLAY statements
│   └── retro_audio.bas         ← Named audio event wrappers
│
├── effects/
│   └── crt_effects.bas         ← Scanlines, flicker, glow effects
│
├── export/
│   ├── export_manager.bas      ← Routing, filename generation, line parsing
│   ├── export_txt.bas          ← Plain text formatter
│   ├── export_markdown.bas     ← Markdown formatter
│   ├── export_json.bas         ← JSON formatter
│   ├── export_html.bas         ← HTML formatter (retro dark theme)
│   └── export_ui.bas           ← Export screen rendering
│
├── favorites/
│   ├── favorites_manager.bas   ← Favorite state logic (fav:1 token)
│   └── favorites_ui.bas        ← [*] / [ ] badge rendering
│
├── priority/
│   ├── priority_manager.bas    ← Priority levels, weights, parsing
│   └── priority_ui.bas         ← [HIGH] badge rendering, selection menu
│
├── search/
│   ├── search_parser.bas       ← Tokenizer, operator stripping
│   ├── search_engine.bas       ← Match, score, weighted ranking
│   ├── search_filters.bas      ← Tag / priority / favorites filtering
│   └── search_ui.bas           ← Search screen rendering
│
├── themes/
│   └── theme_manager.bas       ← Theme data, COLOR application, save/load
│
├── ui/
│   ├── ascii_panels.bas        ← Box/border/divider drawing primitives
│   ├── window_renderer.bas     ← Screen layout coordinator
│   └── retro_ui.bas            ← Boot sequence, cursor, theme screen
│
├── file_manager.bas            ← ideas.txt I/O
├── idea_manager.bas            ← Write/Review/Search/Delete screens
├── menu_utils.bas              ← ShowHeader, GetConfirmation, ShowHelp
│
├── ideas.txt                   ← Your ideas database
└── theme.cfg                   ← Saved theme preference (auto-generated)
```

---

## `> MODULE RULES`

The architecture enforces strict separation of concerns. Every module has exactly one responsibility.

**QB64 global declarations** — all in `main.bas` before any `$Include`:

```basic
' All CONST, TYPE, and DIM SHARED must appear here
' QB64 requires these before any SUB/FUNCTION in the compiled unit
CONST THEME_FALLOUT   = 1
CONST SOUND_ENABLED   = -1   ' change to 0 to disable all audio
CONST CRT_EFFECTS_ENABLED = -1   ' change to 0 to disable CRT effects
DIM SHARED g_ActiveTheme AS INTEGER
' ... etc
```

**Hard rules across all modules:**

| Rule | Detail |
|---|---|
| No `CONST` / `TYPE` / `DIM SHARED` in modules | All in `main.bas` only |
| No `SOUND` / `BEEP` / `PLAY` outside `sound_manager.bas` | Use `RetroAudio_*` wrappers |
| No `CLS` in screen modules | Use `Window_DrawScreen%` or `Window_Clear` |
| No `PRINT` in logic modules | Only UI modules render |
| No circular dependencies | Include order is load-order in QB64 |

---

## `> INCLUDE ORDER`

```basic
'$Include: 'audio/sound_manager.bas'      ← audio gateway, DIM SHARED state
'$Include: 'audio/retro_audio.bas'        ← named event wrappers
'$Include: 'themes/theme_manager.bas'     ← theme data and COLOR application
'$Include: 'ui/retro_ui.bas'              ← boot screen, cursor, theme picker
'$Include: 'effects/crt_effects.bas'      ← CRT visual effects
'$Include: 'ui/ascii_panels.bas'          ← box/border primitives
'$Include: 'ui/window_renderer.bas'       ← layout coordinator
'$Include: 'priority/priority_manager.bas'
'$Include: 'priority/priority_ui.bas'
'$Include: 'favorites/favorites_manager.bas'
'$Include: 'favorites/favorites_ui.bas'
'$Include: 'search/search_parser.bas'
'$Include: 'search/search_engine.bas'
'$Include: 'search/search_filters.bas'
'$Include: 'search/search_ui.bas'
'$Include: 'file_manager.bas'
'$Include: 'idea_manager.bas'
'$Include: 'export/export_manager.bas'
'$Include: 'export/export_txt.bas'
'$Include: 'export/export_markdown.bas'
'$Include: 'export/export_json.bas'
'$Include: 'export/export_html.bas'
'$Include: 'export/export_ui.bas'
'$Include: 'menu_utils.bas'
```

---

## `> CONFIGURATION`

All toggles live in `main.bas` — change and recompile:

```basic
CONST SOUND_ENABLED       = -1   ' -1 = on  |  0 = silent
CONST CRT_EFFECTS_ENABLED = -1   ' -1 = on  |  0 = off
CONST UI_COLS             = 80   ' terminal width
CONST UI_ROWS             = 25   ' terminal height
```

Theme preference is saved automatically to `theme.cfg` — no recompile needed to switch themes.

---

## `> SEARCH SCORING`

Results are ranked by a weighted score — higher scores surface first:

| Match type | Points |
|---|---|
| Keyword found in idea body | +3 per token |
| Keyword found in tags | +2 per token |
| Full phrase match in body | +1 bonus |
| Priority: LOW | +2 |
| Priority: MEDIUM | +5 |
| Priority: HIGH | +10 |
| Priority: CRITICAL | +15 |
| Favorited idea | +20 |

---

## `> SOUND EVENTS`

All audio is theme-aware — the same event plays different tones depending on active theme:

| Event | Trigger | Fallout | DOS | Cyberdeck |
|---|---|---|---|---|
| `SND_KEYPRESS` | Each typed char in boot | 440 Hz warm | 1200 Hz sharp | 900 Hz digital |
| `SND_MENU_MOVE` | Valid menu selection | 330 Hz | 800 Hz | 1100 Hz |
| `SND_CONFIRM` | Idea saved, theme applied, exit | Soft ascending | Mid double-beep | Synth triple |
| `SND_ERROR` | Invalid input, no results | Low buzz | Sharp drop | Digital drop |
| `SND_NOTIFY` | Search results found | Warm double | Clean double | Synth triple |
| `SND_BOOT_BEEP` | Per boot sequence line | 370 Hz | 1000 Hz | 1500 Hz |
| `SND_READY` | System ready chime | `A B >C` | `C E G >C` fast | `>C E G >C` high |
| `SND_EXPORT` | Export completed | Warm rising | Clean double | Neon pulse |
| `SND_THEME_CHANGE` | Theme switched | Multi-note chime | Multi-note chime | Multi-note chime |

---

## `> FUTURE ROADMAP`

```
[ ] Delete idea — full implementation
[ ] Idea editing — edit existing entries
[ ] Categories system
[ ] Linked ideas / knowledge graph
[ ] Priority analytics dashboard
[ ] AI tagging / smart categorisation
[ ] Favorites quick-access menu
[ ] Ambient audio loops — CRT hum, keyboard noise
[ ] WAV/OGG streaming via _SNDOPEN
[ ] Theme editor
[ ] Custom downloadable theme packs
[ ] Journal entries system
[ ] Project / task system
[ ] CSV export format
[ ] PDF export format
[ ] Scheduled backups / auto-export
[ ] Split-screen terminal panels
```

---

## `> REQUIREMENTS`

- [QB64-PE v4.2.0+](https://www.qb64phoenix.com/)
- Windows (tested), Linux/macOS via QB64-PE
- Terminal with 80×25 minimum resolution recommended
- PC speaker or system audio for sound effects

---

## `> GETTING STARTED`

```
1. Open main.bas in QB64-PE
2. Press F5 to compile and run
3. Select a theme from the main menu (option 7)
4. Start capturing ideas (option 1)
5. Use Search Everything (option 5) with operators to find them
6. Export your knowledge base (option 6)
```

> **Note:** `ideas.txt` and `theme.cfg` are created automatically on first run in the same directory as the compiled executable.

---

## `> AUTHOR`

**Jeremy Stevens** — *Brain Dump QB64*
Built with QB64-PE · Phase 1 & Phase 2 complete

---

```
╔══════════════════════════════════════════════════════════════╗
║  END OF LINE.                                               ║
╚══════════════════════════════════════════════════════════════╝
```
