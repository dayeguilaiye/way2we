"""Build a full-glyph Regular face from the pinned Google Fonts source.

Install tools/font-requirements.txt, then pass the downloaded NotoSerifSC[wght].ttf.
Source URL and checksum are recorded in apps/mobile/assets/README.md.
"""
import hashlib
import sys
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
source=Path(sys.argv[1])
assert hashlib.sha256(source.read_bytes()).hexdigest()=='050080d9255a86808f2945bffac582b31ef32bc36411ce29563b4961670c66f9', 'Unexpected font source'
font=TTFont(source)
print(font['name'].getDebugName(1),font['name'].getDebugName(5))
coverage=set(font.getBestCmap())
instantiateVariableFont(font,{'wght':400},inplace=True,updateFontNames=True)
assert set(font.getBestCmap())==coverage
output=Path(__file__).resolve().parents[1]/'apps/mobile/assets/fonts/brand-serif.ttf'
font.save(output)
print(f'Regular face: {len(coverage)} code points; {output.stat().st_size} bytes')
