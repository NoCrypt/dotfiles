# Third-party notices

This repository is a personal, single-machine dotfiles collection. The MIT
license at the repository root covers **original work only**. Vendored
third-party files keep their upstream licenses, listed below. Some vendored
pieces have no declared license; those are called out explicitly.

| Component | Upstream | Version / commit | License | Vendored path |
|---|---|---|---|---|
| mangobar config + style | https://github.com/mangowm/mangobar | `f543ddd3af0073a6cfaf17cda1b4926b8a27806c` (r77, 2026-10-16; matches installed `mangobar-git r77.f543ddd-1`) | GPL-3.0 | `dot_config/mangobar/` |
| wlogout power menu (layout, style, icons) | https://github.com/DreamMaoMao/dotfile (`hypr/wlogout/`) | files last changed `3fd04f114c25bdd18ece8c98d89add8269763bdd` (2025-11-21); repo HEAD `faf1f92857e8bb0961612b4e70c2a864e8d5c591` | **none declared** (see below) | `dot_config/mango/wlogout/` |
| Orbital SDDM theme | https://github.com/Rizmi/ryoku-orbital-clock-sddm | base commit `c5d7e33bb3eb1aedfc675c54cddbbc38c062e545` (2026-08-30); `Main.qml` last changed in `851d1ee9abf58c6a2e5e98e56866be960307ef66` (2026-08-20) | GPL-3.0 | `usr/share/sddm/themes/orbital/` |
| ncpt-tray icon theme | Original work (inherits Adwaita, not vendored) | — | MIT | `dot_local/share/icons/ncpt-tray/` |
| ncpt GRUB theme | Original work | — | MIT | `boot/grub/themes/ncpt/` |

## License files included

- `dot_config/mangobar/LICENSE` — GPL-3.0, copied verbatim from upstream `mangowm/mangobar`.
- `usr/share/sddm/themes/orbital/LICENSE` — GPL-3.0, copied verbatim from upstream `Rizmi/ryoku-orbital-clock-sddm`.
- `boot/grub/themes/ncpt/LICENSE-DEJAVU` — DejaVu/Bitstream Vera license for the `dejavu_16.pf2` and `dejavu_bold_14.pf2` fonts converted for the GRUB theme.

## Notes and unknowns

### mangobar (`dot_config/mangobar/`)

`config.jsonc` and `style.css` are local configuration derived from
mangobar's example files and heavily restyled for this machine (GitHub Dark
palette, local module set). Upstream is GPL-3.0. The style header says
"athos-gruv layout"; no public repository by that name could be found, so
that label is unverified — it may just describe the upstream gruvbox-style
default. The bar binary itself is a package (`mangobar-git`), not vendored.

### wlogout (`dot_config/mango/wlogout/`)

The layout, stylesheet, and six PNG icons are byte-identical (icons) or
derived (layout/style) from `DreamMaoMao/dotfile`. **That repository declares
no license** (GitHub license API returns none, no LICENSE file), so these
files are technically "all rights reserved". No license file was added
because none exists to copy; do not assume the MIT license of the `wlogout`
program (ArtsyMacaw) covers this third-party artwork/configuration. Local
changes: logout action switched to `mmsg dispatch quit`, hibernate entry
removed, colors changed to GitHub Dark. If this repository is ever published
or redistributed, replace these icons/configs or obtain permission.

### Orbital SDDM theme (`usr/share/sddm/themes/orbital/`)

Upstream GPL-3.0. This copy is a subset (`Main.qml`, `metadata.desktop`,
`theme.conf`; no upstream `font/` or `preview.gif`). `metadata.desktop` and
`theme.conf` are identical to upstream at the base commit. `Main.qml` adds an
image background and a dim overlay — see `LOCAL_CHANGES.md` and
`LOCAL_CHANGES.patch`.

`background.png` (3840x2160 Hatsune Miku fan artwork) was added locally. Its
artist/source is unknown and it is **not** covered by the GPL-3.0 license of
the theme or by this repository's MIT license. It should be replaced with an
original or clearly-licensed image before redistribution.

### Artwork elsewhere

`dot_config/mango/wallpaper/*` and `dot_config/fastfetch/miku.png` are
third-party anime artwork of unknown provenance/ license. They are personal
wallpaper assets, not covered by the MIT license.

### Not vendored

- Fonts (JetBrainsMono Nerd Font) and all other applications are installed
  from Arch/AUR packages and carry their own package licenses.
- The `ncpt-tray` theme lists `Inherits=Adwaita,hicolor`; no Adwaita files
  are copied into this repository.
