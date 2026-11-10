#!/usr/bin/env python3
"""Render the Play feature graphic with bundled brand assets. Requires Pillow and Inkscape."""
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parents[1]
out=root/'play/graphics/en-US'
out.mkdir(parents=True, exist_ok=True)
S=3
im=Image.new('RGB',(1024*S,500*S),'#0F4F49')
d=ImageDraw.Draw(im)
def box(xy,fill,r=0):
    xy=tuple(int(v*S) for v in xy)
    if r:d.rounded_rectangle(xy,r*S,fill=fill)
    else:d.rectangle(xy,fill=fill)
def text(x,y,t,size,color,font='sans'):
    f=ImageFont.truetype(str(root/'assets/fonts/Fraunces.ttf') if font=='serif' else '/usr/share/fonts/liberation-sans-fonts/LiberationSans-Regular.ttf',size*S)
    d.text((x*S,y*S),t,font=f,fill=color)
# Quiet geometric background and a generous safe area.
d.ellipse((550*S,-150*S,1350*S,650*S),fill='#145C54')
text(64,65,'CASTLEI',22,'#A6D5C6')
text(60,116,'Make your',58,'#F6F1E7','serif')
text(60,183,'next move.',58,'#F6F1E7','serif')
box((64,277,116,281),'#E98A70',2)
text(64,308,'A little chess. Every day.',25,'#F6F1E7')
text(64,352,'Play  ·  Analyse  ·  Learn',19,'#A6D5C6')
# A real legal opening position, after 1.e4 e5 2.Nf3 Nc6 3.Bc4.
x0,y0,sz=613,91,39
box((x0-13,y0-13,x0+8*sz+13,y0+8*sz+13),'#0B3D38',16)
rows=['r1bqkbnr','pppp1ppp','2n5','4p3','2B1P3','5N2','PPPP1PPP','RNBQK2R']
for row in range(8):
    for col in range(8):
        fill='#EEE6D2' if (row+col)%2==0 else '#7B9A8B'
        if (row,col) in [(7,5),(4,2)]:fill='#C6B56D' if (row+col)%2==0 else '#ADAA66'
        box((x0+col*sz,y0+row*sz,x0+(col+1)*sz,y0+(row+1)*sz),fill)
for row,rank in enumerate(rows):
    col=0
    for piece in rank:
        if piece.isdigit(): col+=int(piece);continue
        name=('w' if piece.isupper() else 'b')+piece.upper()
        dest=Path('/tmp')/f'castlei-{name}.png'
        if not dest.exists():
            subprocess.run(['inkscape',str(root/f'assets/pieces/{name}.svg'),f'--export-filename={dest}',f'--export-width={sz*S}'],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        p=Image.open(dest).convert('RGBA')
        im.paste(p,((x0+col*sz)*S,(y0+row*sz)*S),p)
        col+=1
im.resize((1024,500),Image.Resampling.LANCZOS).save(out/'feature-graphic.png')
