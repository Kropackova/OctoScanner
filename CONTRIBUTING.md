# Contributing

Target the Vanilla 1.12 API and Lua 5.0. Keep original Vanilla content separate from Octo/Turtle additions. Short aliases need recruitment context when they also name a class, profession or ordinary word.

## Report a problem

Include the addon version, content profile and exact message, followed by the expected and actual section, tab, activity, role, class and level. For display problems, include the window scale and a screenshot. Anonymize private names and links; do not commit chat dumps or SavedVariables.

## Run tests

Use a Lua 5.0 interpreter. The suites load the shipping TOC order and model Vanilla's global event arguments.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -LuaPath '<path-to-lua50.exe>'
```

On other platforms, run the nine Lua suites listed in `tools/test.ps1` individually. `tests/wow_mock.lua` is their shared mock. Add a regression for a demonstrated bug and a nearby ambiguous case when a parsing rule changes.

## Build packages

Python 3.9+ is required; there are no additional Python dependencies.

```powershell
python tools/package.py
python tools/build_github.py
```

Packages and SHA-256 sidecars are written to ignored `dist/`. The installer validates TOC files and texture checksums and contains one root folder, `OctoScanner`. The source exporter uses an explicit file allowlist and rejects unexpected files in its output directory.

Before publishing a version, verify rendering, resizing, filters, history restoration and player actions in the target game client. Offline tests cannot verify sound, rendering or server behavior.
