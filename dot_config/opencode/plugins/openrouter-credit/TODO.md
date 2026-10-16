# openrouter-credit plugin — todo

Goal: show the OpenRouter account credit in the TUI while the selected model uses the
`openrouter` provider — in the sidebar (under token spent) and in the status bar.

- [x] Scaffold discovered-plugin layout: `index.ts` (server entry, required) + `tui.tsx`
- [x] Fetch the OpenRouter key via `context.client.credential.list()` (integration `openrouter`, type `key`)
- [x] Fetch remaining credit from `GET https://openrouter.ai/api/v1/credits`
      (`total_credits - total_usage`)
- [x] Sidebar placement: `append` to `sidebar.content` (renders under the built-in token/cost block)
- [x] Status bar placement: `append` to `prompt.footer.status`
- [x] Only render when `context.ui.model.current()?.providerID === "openrouter"`
- [x] Refresh every 60s + cleanup on unload
- [x] Manual refresh: palette command / slash `/credit` (`openrouter.credit.refresh`)
- [x] Verified: `opencode plugin list` shows `openrouter.credit.server` (local), and
      `features: {server:true, tui:true}` confirms `tui.tsx` resolved.
- [x] Verified live in the TUI: footer shows `OR $3.08`; no slot crash.
