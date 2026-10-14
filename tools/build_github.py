"""Export a standalone scanner repository from either source layout.

Uses an explicit public file allowlist; raw logs, local Git history, upstream
archives, runtimes and the separate logger/helper are never copied.
"""
from pathlib import Path
import hashlib
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parent.parent
FLAT = (ROOT / 'OctoScanner.toc').is_file()
ADDON = ROOT if FLAT else ROOT / 'OctoScanner'
toc = ADDON / 'OctoScanner.toc'
toc_text = toc.read_text(encoding='utf-8')
version = re.search(r'^## Version:\s*(\S+)', toc_text, re.M).group(1)
assert re.fullmatch(r'[0-9A-Za-z.-]+', version)
assert f'OCS.VERSION = "{version}"' in (ADDON / 'Parser.lua').read_text(encoding='utf-8')
assert (ROOT / 'LICENSE').read_bytes() == (ADDON / 'LICENSE').read_bytes()

entries = {}


def add(name, path, rewrite_test=False):
    assert name not in entries, name
    source = path.read_bytes()
    if rewrite_test and not FLAT:
        # Adapt test loader paths when exporting the nested source layout.
        source = source.replace(b'OctoScanner/', b'')
    entries[name] = source


add(toc.name, toc)
for line in toc_text.splitlines():
    name = line.strip()
    if name and not name.startswith('#'):
        path = ADDON / name
        assert path.resolve().is_relative_to(ADDON.resolve()), name
        add(name, path)
textures = ADDON / 'Textures'
for name in ('README.md', 'sources.json'):
    add(f'Textures/{name}', textures / name)
for item in json.loads((textures / 'sources.json').read_text(encoding='utf-8'))['textures']:
    path = textures / item['local']
    assert path.resolve().is_relative_to(textures.resolve())
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256']
    add('Textures/' + item['local'], path)
for name in ('README.md', 'CHANGELOG.md', 'CONTRIBUTING.md', 'LICENSE', '.gitattributes',
             'docs/CONTENT.md', 'docs/RELEASE-NOTES.md',
             '.github/ISSUE_TEMPLATE/bug_report.md', '.github/ISSUE_TEMPLATE/feature_request.md',
             'tools/package.py', 'tools/build_github.py', 'tools/test.ps1'):
    add(name, ROOT / name)
for path in sorted((ROOT / 'docs' / 'screenshots').glob('*')):
    if path.is_file() and path.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp'):
        add('docs/screenshots/' + path.name, path)
for name in ('run.lua', 'reload.lua', 'history.lua', 'feedback.lua', 'scale.lua', 'ui-scale.lua', 'corpus.lua',
             'corpus-third.lua', 'corpus-fourth.lua', 'wow_mock.lua'):
    add('tests/' + name, ROOT / 'tests' / name, rewrite_test=True)
entries['.gitignore'] = b'''dist/
.tooling/
.research/
.upstream/
__pycache__/
*.pyc
*.zip
WTF/
Imports/
Logs/
OctoChatLogger-*.txt
OctoChatLogger-*.lua
'''

stage = ROOT / 'dist' / 'github' / 'OctoScanner'
assert stage.resolve().is_relative_to((ROOT / 'dist').resolve())
assert not (stage / '.git').exists(), 'Do not overwrite an initialized repository'
for name in ('OctoChatScanner.toc', 'README.md'):
    stale = stage / 'compat' / 'OctoChatScanner' / name
    assert stale.resolve().is_relative_to(stage.resolve())
    if stale.is_file(): stale.unlink()
for stale_dir in (stage / 'compat' / 'OctoChatScanner', stage / 'compat'):
    if stale_dir.is_dir() and not any(stale_dir.iterdir()): stale_dir.rmdir()
existing = {path.relative_to(stage).as_posix() for path in stage.rglob('*') if path.is_file()}
assert not (existing - set(entries)), 'Unexpected files in prepared source folder: ' + ', '.join(sorted(existing - set(entries)))
for name, source in entries.items():
    target = stage / name
    assert target.resolve().is_relative_to(stage.resolve()), name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(source)
    assert target.read_bytes() == source
assert {path.relative_to(stage).as_posix() for path in stage.rglob('*') if path.is_file()} == set(entries)

out = ROOT / 'dist' / f'OctoScanner-{version}-GitHub-source.zip'
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as archive:
    for name, source in sorted(entries.items()):
        archive.writestr(zipfile.ZipInfo('OctoScanner/' + name, (1980, 1, 1, 0, 0, 0)),
                         source, compress_type=zipfile.ZIP_DEFLATED)
with zipfile.ZipFile(out) as archive:
    assert archive.testzip() is None
    assert set(archive.namelist()) == {'OctoScanner/' + name for name in entries}
    for name, source in entries.items():
        assert archive.read('OctoScanner/' + name) == source
    assert not any(part in {'.git', '.research', '.tooling', '.upstream', 'OctoChatLogger'}
                   for name in archive.namelist() for part in name.split('/'))
digest = hashlib.sha256(out.read_bytes()).hexdigest()
out.with_suffix('.sha256').write_text(f'{digest}  {out.name}\n', encoding='ascii')
print(f'PASS public scanner source: {len(entries)} allowlisted files; code and texture checksums verified')
print(stage)
print(out)
print('SHA256 ' + digest)
