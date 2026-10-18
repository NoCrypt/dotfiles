# Local changes — Orbital SDDM theme

Base: `Rizmi/ryoku-orbital-clock-sddm` at commit
`c5d7e33bb3eb1aedfc675c54cddbbc38c062e545` (2026-08-30, `main`).
`Main.qml` was last changed upstream in
`851d1ee9abf58c6a2e5e98e56866be960307ef66` and is unchanged since, so the
diff below is against the exact upstream file.

Local change: inside the root `Rectangle`, before `id: root`, an `Image`
fills the screen with `background.png` (`PreserveAspectCrop`) and a black
`Rectangle` at 40% opacity sits on top so the clock and login text stay
readable. No upstream QML was removed or altered.

Apply from the repository root:

```sh
git apply usr/share/sddm/themes/orbital/LOCAL_CHANGES.patch
```

`background.png` is local artwork of unknown provenance (Hatsune Miku fan
art) and is not part of the upstream theme or covered by its GPL-3.0
license. Replace it with an original or clearly-licensed image before
redistributing this repo.
