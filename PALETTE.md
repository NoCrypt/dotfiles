# Palette — GitHub Dark (Primer) as used in this repo

Canonical values only: every colour below appears literally in one of the configs.
Hex is lowercase here to make `grep` easy; several configs write it uppercase.

File keys (repo root):

| Key | Path |
| --- | --- |
| `kitty` | `dot_config/kitty/kitty.conf` |
| `mangobar` | `dot_config/mangobar/style.css` |
| `mako` | `dot_config/mako/config` |
| `fuzzel` | `dot_config/fuzzel/fuzzel.ini` |
| `swaylock` | `dot_config/swaylock/config` |
| `kde` | `dot_config/kdeglobals` |
| `wlogout` | `dot_config/mango/wlogout/style.css` |
| `opencode` | `dot_config/opencode/themes/github-transparent.json` |
| `grub` | `boot/grub/themes/ncpt/theme.txt` |
| `sddm` | `usr/share/sddm/themes/orbital/` (`theme.conf`, `Main.qml`) |

## Background

| Hex | Role | Used in |
| --- | --- | --- |
| `#0d1117` | canvas default / terminal bg / window bg | kitty (background, cursor text, active tab fg), mangobar (#tags.occupied, #layout, #clock, #cpu, #mem, #custom-brightness, #battery, #custom-applist, #custom-text; text on accent chips), fuzzel (background), swaylock (color, inside-color, inside-ver/clear-color), kde (Window/View BackgroundNormal 13,17,23), grub (message-bg-color), opencode (darkBg), wlogout (window rgba(13,17,23,0.78)) |
| `#010409` | deepest canvas / inset | kitty (tab_bar_background), mangobar (#tags.empty), opencode (darkBgAlt → backgroundPanel, diffContextBg) |

## Raised / panels

| Hex | Role | Used in |
| --- | --- | --- |
| `#161b22` | canvas subtle / raised surface | kitty (inactive_tab_background), mangobar (#tray, menu bg), mako (background-color `#161b22ee`), swaylock (inside-wrong-color, inside-caps-lock-color `#161b22e6`), kde (BackgroundAlternate 22,27,34), opencode (darkBgPanel → backgroundElement) |
| `#21262d` | canvas overlay / chips | mangobar (global `*` background), kde (Button BackgroundNormal 33,38,45), opencode (borderSubtle) |

## Text

| Hex | Role | Used in |
| --- | --- | --- |
| `#c9d1d9` | fg default | kitty (foreground, selection_foreground, cursor), mangobar (`*`, #tags.empty, menuitem), mako (text-color), fuzzel (text, message, input), swaylock (text-color), kde (ForegroundNormal 201,209,217), grub (message-color), opencode (darkFg → text/markdownText/syntaxPunctuation), wlogout (window, button) |
| `#f0f6fc` | fg on emphasis (brightest) | kitty (color15) |
| `#ffffff` | pure white | fuzzel (selection-text), kde (Selection ForegroundNormal 255,255,255) |

## Muted text

| Hex | Role | Used in |
| --- | --- | --- |
| `#8b949e` | fg muted | kitty (inactive_tab_foreground), mangobar (#tags.occupied fg, #layout, #clock, #cpu, #mem, #custom-brightness, #battery, #custom-text), fuzzel (prompt), swaylock (ring-color), kde (ForegroundInactive 139,148,158), grub (item_color), opencode (darkFgMuted → textMuted, comments, diffContext) |
| `#6e7681` | fg subtle / disabled | kitty (color8), fuzzel (placeholder, counter) |
| `#484f58` | dimmest fg (ANSI black) | kitty (color0) |
| `#b1bac4` | ANSI white / low-contrast fg | kitty (color7) |

## Accent

| Hex | Role | Used in |
| --- | --- | --- |
| `#58a6ff` | accent blue / links / active | kitty (url_color, color4, active_tab_background, mark1_background), mangobar (#tags.active, #overview, #title, #volume, #network, #custom-power, #custom-caffeine, #hideclients, #custom-applist fg), mako (progress-color `#58a6ff44`), fuzzel (match), swaylock (ring-ver-color, key-hl-color, text-ver-color), kde (ForegroundActive/Link 88,166,255, DecorationFocus/Hover), grub (title, selected_item_color), opencode (darkBlue → primary, borderActive, headings, links), wlogout (button:hover rgba(88,166,255,0.3)) |
| `#79c0ff` | accent blue, lighter | kitty (color12), fuzzel (selection-match) |
| `#388bfd` | accent emphasis (focused border) | kitty (active_border_color) |
| `#39c5cf` | cyan | kitty (color6, mark3_background), mangobar (#keymode), opencode (darkCyan → accent, syntaxString, markdownLinkText) |
| `#56d4dd` | cyan, lighter | kitty (color14) |
| `#bc8cff` | purple | kitty (color5, mark2_background), opencode (darkPurple → secondary, syntaxFunction) |
| `#d2a8ff` | purple, lighter | kitty (color13) |
| `#db61a2` | pink | mangobar (#keyboardlayout) |

## Selection

| Hex | Role | Used in |
| --- | --- | --- |
| `#264f78` | terminal selection bg | kitty (selection_background) |
| `#1f6feb` | selection / focused row bg | fuzzel (selection), kde (Selection BackgroundNormal/Alternate 31,111,235) |

## Status: green / red / yellow

| Hex | Role | Used in |
| --- | --- | --- |
| `#3fb950` | success green | kitty (color2), swaylock (ring-clear-color, text-clear-color), mangobar (menuitem:hover), kde (ForegroundPositive 63,185,80), opencode (darkGreen → success, diffAdded) |
| `#56d364` | green, lighter | kitty (color10) |
| `#f85149` | danger red | mangobar (#tags.urgent, #network.disconnected, #custom-record), swaylock (ring-wrong-color, bs-hl-color, caps-lock-bs-hl-color, text-wrong-color), kde (ForegroundNegative 248,81,73), opencode (darkRed → error, diffRemoved) |
| `#ff7b72` | red, lighter (ANSI red) | kitty (color1), opencode (darkPink → markdownCode, syntaxKeyword, syntaxOperator) |
| `#ffa198` | red, lightest | kitty (color9) |
| `#d29922` | attention yellow | kitty (color3, bell_border_color), swaylock (ring-caps-lock-color, caps-lock-key-hl-color, text-caps-lock-color), kde (ForegroundNeutral 210,153,34), opencode (darkOrange → info, syntaxVariable, syntaxType, markdownStrong) |
| `#e3b341` | yellow, lighter | kitty (color11), opencode (darkYellow → warning, markdownEmph) |

## Borders

| Hex | Role | Used in |
| --- | --- | --- |
| `#30363d` | border default | kitty (inactive_border_color), mangobar (menu border), mako (border-color), fuzzel (border), kde (Button BackgroundAlternate 48,54,61), opencode (border, markdownHorizontalRule) |
| `#1f6feb` | border focus | see Selection (fuzzel/kde) |
| `#388bfd` | border active | see Accent (kitty) |

## Extras found in opencode theme only

| Hex | Role | Used in |
| --- | --- | --- |
| `#033a16` | diff added bg | opencode (diffAddedBg, diffAddedLineNumberBg) |
| `#67060c` | diff removed bg | opencode (diffRemovedBg, diffRemovedLineNumberBg) |
| `#95999e` | diff line number | opencode (diffLineNumber) |
| `#a371f7` | visited link (purple) | kde (ForegroundVisited 163,113,247) |

## Terminal ANSI map

`kitty` defines the 16 ANSI colours; `fastfetch` (`dot_config/fastfetch/config.jsonc`) uses
`{#32}`–`{#36}` placeholders, so its colours come from kitty rather than literal hex.

| Slot | Hex | Slot | Hex |
| --- | --- | --- | --- |
| color0 | `#484f58` | color8 | `#6e7681` |
| color1 | `#ff7b72` | color9 | `#ffa198` |
| color2 | `#3fb950` | color10 | `#56d364` |
| color3 | `#d29922` | color11 | `#e3b341` |
| color4 | `#58a6ff` | color12 | `#79c0ff` |
| color5 | `#bc8cff` | color13 | `#d2a8ff` |
| color6 | `#39c5cf` | color14 | `#56d4dd` |
| color7 | `#b1bac4` | color15 | `#f0f6fc` |

## Alpha suffixes

Transparency is appended to the same hex; the base colour still matches the table.

- `#161b22ee` — mako background
- `#161b22e6` — swaylock wrong / caps-lock interior
- `#0d1117e6` — swaylock inside (ver/clear)
- `#58a6ff44` — mako progress bar
- `rgba(13, 17, 23, 0.78)` = `#0d1117` — wlogout window
- `rgba(88, 166, 255, 0.3)` = `#58a6ff` — wlogout button hover

## Values outside GitHub Dark

These are local, not Primer palette colours:

| Hex | Used in | Why |
| --- | --- | --- |
| `#000000` | sddm (theme.conf color, Main.qml bg/overlay), grub (desktop-color) | SDDM/GRUB boot screens are flat black |
| `#080808`, `#1a1a1a`, `#222222`, `#333333`, `#444`, `#555555`, `#666666`, `#ffffff`, `#ff4444` | sddm Main.qml | orbital theme's own dark/light tokens and error text |
| `#ebdbb2`, `#504945`, `#83a598`, `#1b1a1a` | `scripts/post-install.sh` (inline gruvbox fallback bar CSS) | installer writes a temporary gruvbox bar before the GitHub Dark theme is applied; not this palette |

`kdeglobals` stores colours as decimal RGB, not hex: `13,17,23` = `#0d1117`,
`22,27,34` = `#161b22`, `33,38,45` = `#21262d`, `48,54,61` = `#30363d`,
`201,209,217` = `#c9d1d9`, `139,148,158` = `#8b949e`, `88,166,255` = `#58a6ff`,
`31,111,235` = `#1f6feb`, `63,185,80` = `#3fb950`, `248,81,73` = `#f85149`,
`210,153,34` = `#d29922`, `163,113,247` = `#a371f7`, `255,255,255` = `#ffffff`.
