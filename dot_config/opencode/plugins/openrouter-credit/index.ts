import { Plugin } from "@opencode/plugin"

// Required server entrypoint: the plugin loader rejects a directory with no
// server entry even when only the TUI side is used.
export default Plugin.define({
  id: "openrouter.credit.server",
  setup() {},
})
