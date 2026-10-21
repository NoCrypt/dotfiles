.pragma library

// Subsequence matcher. Returns null, or { score, idx } where idx are the matched positions.
function match(query, text) {
    const q = query.toLowerCase()
    const t = text.toLowerCase()
    let ti = 0, score = 0, last = -2
    const idx = []
    for (let qi = 0; qi < q.length; qi++) {
        let found = -1
        for (let j = ti; j < t.length; j++) { if (t[j] === q[qi]) { found = j; break } }
        if (found < 0) return null
        idx.push(found)
        score += 1
        if (found === last + 1) score += 3
        if (found === 0 || " -_./".indexOf(t[found - 1]) >= 0) score += 2
        last = found
        ti = found + 1
    }
    return { score: score - t.length * 0.01, idx: idx }
}

function esc(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;") }

// HTML with matched characters coloured
function highlight(text, idx, color) {
    if (!idx || idx.length === 0) return esc(text)
    let out = "", i = 0
    const set = {}
    for (const k of idx) set[k] = true
    while (i < text.length) {
        const on = !!set[i]
        let j = i
        while (j < text.length && !!set[j] === on) j++
        const part = esc(text.substring(i, j))
        out += on ? '<font color="' + color + '">' + part + "</font>" : part
        i = j
    }
    return out
}
