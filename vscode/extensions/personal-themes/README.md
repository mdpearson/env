# Tokyo Night Light (Stripped)

A verbatim fork of [Tokyo Night Light](https://github.com/tokyo-night/tokyo-night-vscode-theme)
by Enkia, with all syntax token rules removed.

## Modifications from upstream

- `tokenColors` reduced to `[]`
- `semanticTokenColors` reduced to `{}`
- A stray top-level `tokenColorCustomizations` block (3 semantic-token rules)
  removed
- `uiTheme` in `package.json` set to `vs` to match the actual light nature of
  the theme (upstream's theme JSON has `"type": "dark"` for the Light variant,
  which appears to be an upstream bug; the theme JSON value is preserved
  verbatim, but `uiTheme` in this wrapper disagrees deliberately)

## Attribution

Based on Tokyo Night by Enkia, MIT licensed. See `LICENSE.txt` for the
preserved upstream copyright notice. Upstream repository:
<https://github.com/tokyo-night/tokyo-night-vscode-theme>.
