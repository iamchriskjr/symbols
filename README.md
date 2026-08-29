# Symbols for Omarchy

A fast, comprehensive Unicode and symbol picker plugin for the Omarchy status bar.

![Symbols Preview](https://raw.githubusercontent.com/iamchriskjr/symbols/main/preview.png)

## Features

- **2,600+ Curated Symbols**: Mathematical operators, calculus symbols, arrows, currency, Greek letters, punctuation, box drawing, fractions, and dingbats.
- **Smart Multi-Token Search**: Search by symbol character, English name, category, or hex/Unicode codepoint (e.g. `pipe`, `vertical`, `007c`, `arrow`, `alpha`).
- **Live Hover Preview**: Real-time footer bar showing the symbol name, codepoint (`U+...`), and category on hover.
- **Favorites & Recents**:
  - One-click heart toggle on each tile.
  - **Frequently Used** (top 10 ranked by usage).
  - **Recently Used** (last 10 used).
  - Automatic deduplication against your favorited symbols.
- **Auto-Paste**: Toggleable direct pasting into your currently active window via `wtype` or standard clipboard copy (`wl-copy`).
- **High Performance**: Native virtualized `GridView` rendering with instant launch.

## Installation

Clone this repository directly into your Omarchy plugins directory:

```bash
git clone https://github.com/iamchriskjr/symbols.git ~/.config/omarchy/plugins/iamchriskjr.symbols
```

Then add `"iamchriskjr.symbols"` to your `bar.layout.right` inside `~/.config/omarchy/shell.json`:

```json
{
  "bar": {
    "layout": {
      "right": [
        { "id": "iamchriskjr.symbols" }
      ]
    }
  }
}
```

Reload the shell:

```bash
omarchy restart shell
```

## License

[MIT](LICENSE) © iamchriskjr
