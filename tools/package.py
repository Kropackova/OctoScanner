"""Build only the files needed by the addon, and verify the install layout."""
from pathlib import Path
import hashlib
import json
import re
import struct
import zipfile

ROOT = Path(__file__).resolve().parent.parent


def package(addon_name, readme, suffix=''):
    addon = ROOT if (ROOT / f'{addon_name}.toc').is_file() else ROOT / addon_name
    toc = addon / f'{addon_name}.toc'
    text = toc.read_text(encoding='utf-8')
    version = re.search(r'^## Version:\s*(\S+)', text, re.M).group(1)
    assert re.search(r'^## Interface:\s*11200\s*$', text, re.M)
    files = [toc, addon / 'LICENSE']
    for line in text.splitlines():
        name = line.strip()
        if not name or name.startswith('#'):
            continue
        path = addon / name
        assert path.is_file() and path.resolve().is_relative_to(addon.resolve()), name
        files.append(path)
    if addon_name == 'OctoScanner':
        textures = addon / 'Textures'
        manifest = textures / 'sources.json'
        files.extend([manifest, textures / 'README.md'])
        for texture in json.loads(manifest.read_text(encoding='utf-8'))['textures']:
            path = textures / texture['local']
            assert path.suffix == '.tga' and path.resolve().is_relative_to(textures.resolve())
            data = path.read_bytes()
            width, height = struct.unpack_from('<HH', data, 12)
            assert data[1:3] == bytes([0, 2]) and data[16] == 32, 'Vanilla-compatible TGA required'
            assert (width, height) == (texture['width'], texture['height'])
            assert width > 0 and width & (width - 1) == 0 and height > 0 and height & (height - 1) == 0
            assert len(data) >= 18 + width * height * 4
            assert hashlib.sha256(data).hexdigest() == texture['sha256'], path.name
            files.append(path)
    entries = {f'{addon_name}/{p.relative_to(addon).as_posix()}': p for p in files}
    assert len(entries) == len(files), 'Duplicate TOC files'
    entries[f'{addon_name}/README.md'] = readme
    if addon_name == 'OctoScanner':
        for name in ('CHANGELOG.md', 'docs/CONTENT.md', 'docs/RELEASE-NOTES.md'):
            entries[f'{addon_name}/{name}'] = ROOT / name
        for path in sorted((ROOT / 'docs' / 'screenshots').glob('*')):
            if path.is_file() and path.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp'):
                entries[f'{addon_name}/docs/screenshots/{path.name}'] = path
    if addon_name == 'OctoChatLogger':
        for name in ('Start-Overnight.ps1', 'Start-Overnight.cmd', 'Test-W.cmd'):
            entries[f'{addon_name}/{name}'] = addon / name
    out = ROOT / 'dist' / f'{addon_name}-{version}{suffix}.zip'
    out.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, path in entries.items():
            archive.writestr(zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0)),
                             path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED)
    with zipfile.ZipFile(out) as archive:
        assert set(archive.namelist()) == set(entries)
        assert {name.split('/')[0] for name in archive.namelist()} == {addon_name}, 'Only one addon folder is allowed'
        assert archive.testzip() is None
        for name, path in entries.items():
            assert archive.read(name) == path.read_bytes()
    digest = hashlib.sha256(out.read_bytes()).hexdigest()
    out.with_suffix('.sha256').write_text(f'{digest}  {out.name}\n', encoding='ascii')
    print(f'PASS {addon_name} package layout: {len(entries)} files')
    print(out)
    print(f'SHA256 {digest}')


package('OctoScanner', ROOT / 'README.md', '-OctoWoW')
if (ROOT / 'OctoChatLogger' / 'OctoChatLogger.toc').is_file():
    package('OctoChatLogger', ROOT / 'OctoChatLogger' / 'README.md')

# The timer also works on its own, without updating or running the addon.
helper = ROOT / 'OctoChatLogger'
if (helper / 'OctoChatLogger.toc').is_file():
    version = re.search(r'^## Version:\s*(\S+)', (helper / 'OctoChatLogger.toc').read_text(), re.M).group(1)
    entries = {f'Octo-W-simple/{name}': helper / name for name in
               ('Start-Overnight.ps1', 'Start-Overnight.cmd', 'Test-W.cmd', 'Overnight-README.md')}
    out = ROOT / 'dist' / f'Octo-W-simple-{version}.zip'
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, path in entries.items():
            archive.writestr(zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0)),
                             path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED)
    with zipfile.ZipFile(out) as archive:
        assert archive.testzip() is None and set(archive.namelist()) == set(entries)
        for name, path in entries.items():
            assert archive.read(name) == path.read_bytes()
    digest = hashlib.sha256(out.read_bytes()).hexdigest()
    out.with_suffix('.sha256').write_text(f'{digest}  {out.name}\n', encoding='ascii')
    print(f'PASS standalone helper package: {len(entries)} files')
    print(out)
