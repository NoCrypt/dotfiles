import { Plugin } from "@opencode/plugin/tui"

const CREDITS_URL = "https://openrouter.ai/api/v1/credits"
const REFRESH_MS = 60_000

// Reuse the key OpenCode already stores for the OpenRouter integration.
async function openRouterKey(client: any): Promise<string | undefined> {
  try {
    const res: any = await client.credential.list({})
    const list: any[] = Array.isArray(res) ? res : (res?.data ?? [])
    return list.find((c) => c?.integrationID === "openrouter" && c?.value?.type === "key")?.value?.key
  } catch {
    return undefined
  }
}

export default Plugin.define({
  id: "openrouter.credit",
  setup(context) {
    const [credit, updateCredit] = context.storage.memory("credit", {
      initial: { usd: null as number | null },
    })

    const refresh = async () => {
      const key = await openRouterKey(context.client)
      if (!key) return
      try {
        const res = await fetch(CREDITS_URL, { headers: { Authorization: `Bearer ${key}` } })
        if (!res.ok) return
        const body = await res.json()
        updateCredit((draft) => {
          draft.usd = body.data.total_credits - body.data.total_usage
        })
      } catch {
        // keep the last known value on network errors
      }
    }

    void refresh()
    const timer = setInterval(() => void refresh(), REFRESH_MS)

    const render = () => {
      if (context.ui.model.current()?.providerID !== "openrouter") return null
      const usd = credit.usd
      return <text fg={context.theme.text.muted}>{usd == null ? "OR ..." : `OR $${usd.toFixed(2)}`}</text>
    }

    const sidebar = context.ui.slot({ append: "sidebar.content", render })
    const status = context.ui.slot({ append: "prompt.footer.status", render })

    context.keymap.layer(() => ({
      mode: "global",
      priority: 10,
      commands: [
        {
          id: "openrouter.credit.refresh",
          title: "Refresh OpenRouter credit",
          group: "OpenRouter",
          palette: true,
          slash: { name: "credit", aliases: ["openrouter"] },
          run: async () => {
            await refresh()
            const usd = credit.usd
            context.ui.toast.show({
              message: usd == null ? "OpenRouter credit unavailable" : `OpenRouter credit: $${usd.toFixed(2)}`,
            })
          },
        },
      ],
    }))

    return () => {
      clearInterval(timer)
      sidebar?.()
      status?.()
    }
  },
})
