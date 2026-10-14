# Original control artwork

These are the original Blizzard UI textures referenced by AscensionChatScanner
v1.2.1: SmallerButton, BiggerButton and ChatIM SizeGrabber. They are bundled
because the corresponding texture paths do not exist in the Vanilla client.
The popout retains the original 180-degree texture orientation.

Source: [Gethe/wow-ui-textures, classic](https://github.com/Gethe/wow-ui-textures/tree/312a6e61bab69370c65ccc0a08f1075d62196294),
commit `312a6e61bab69370c65ccc0a08f1075d62196294`.
`sources.json` records individual source paths and SHA-256 checksums.

The source PNG files were converted without resizing, recoloring or redrawing
to uncompressed 32-bit RGBA TGA files supported by WoW 1.12. The decoded pixel
values, transparency and image dimensions were compared and are identical.

World of Warcraft UI artwork is copyright Blizzard Entertainment. The addon
code's MIT license does not change ownership of these game textures.

`OctoScannerTitle.tga` is a white-alpha rendering of the word **OctoScanner**
from the client's original `Fonts/FRIZQT__.TTF`, read from `fonts.MPQ`.
The 394×50 content within a 512×64 uncompressed TGA is displayed at 118.2×15
logical units and tinted by the addon skin. A black copy behind it adds the
stock font shadow at an offset of (1, -1) logical units. Both layers inherit
the main window's scale. The higher source resolution keeps the letters
clear at different UI scales.
The manifest records the source font and output checksums; the font itself
is not distributed. This lettering retains the game font's ownership.
