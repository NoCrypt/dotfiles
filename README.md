# dotfiles

Managed with chezmoi source naming.

- `dot_config/` — maps to `~/.config/` (`dot_` = leading dot). `private_` = private file mode, `executable_` = executable bit.
- `etc/` — system files that live outside `$HOME`; copy them with `sudo`, e.g.
  `sudo cp etc/sddm.conf.d/*.conf /etc/sddm.conf.d/` and `sudo cp etc/xdg/reflector/reflector.conf /etc/xdg/reflector/`.
  These are recorded here for reference/restore, not applied by chezmoi.

## Contents

| Path | What |
| --- | --- |
| `dot_config/kitty/` | kitty terminal (GitHub Dark colors, padding, right-click copy) |
| `dot_config/mango/` | mangowm (dwindle default, Super-based binds, blur, borders) + `keybinds.sh` (Super+/ cheatsheet) |
| `dot_config/mangobar/` | status bar (GitHub Dark style) |
| `dot_config/fuzzel/` | launcher (GitHub Dark) |
| `dot_config/private_fish/` | fish shell (ctrl-arrow / ctrl-backspace word binds) |
| `dot_config/opencode/` | OpenCode CLI: github-transparent theme, openrouter-credit plugin |
| `etc/sddm.conf.d/` | SDDM: orbital theme, Wayland (weston) greeter |
| `etc/xdg/reflector/` | reflector mirrorlist config (freedif excluded) |
| `etc/pacman.conf` | repos incl. chaotic-aur |

Not included: wallpapers and images (size/licensing), and anything with credentials (`~/.config/gh`, `~/.ssh`, the OpenCode credential store).
