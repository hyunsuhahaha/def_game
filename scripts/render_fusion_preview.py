"""Replay the real fusion UI's Lua draw calls offscreen; never boot LÖVE.

Pillow supplies font rasterization and rounded UI rectangles. This is a layout
preview, not a live engine capture. Gameplay/keyboard/mouse are tested in Lua.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont
from headless_lua import run

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/previews'


def render(path):
    size=(960,540) if '-small-' in path.name else (1280,720)
    canvas = Image.new('RGBA', size, (23, 34, 30, 255))
    text_bounds = []
    for op in json.loads(path.read_text(encoding='utf-8')):
        layer = Image.new('RGBA', canvas.size)
        draw = ImageDraw.Draw(layer)
        color = tuple(round(c * 255) for c in op['color'])
        if op['op'] == 'rectangle':
            x, y, w, h = op['args']
            options = {'fill': color} if op['mode'] == 'fill' else {'outline': color, 'width': max(1, round(op['lineWidth']))}
            draw.rounded_rectangle((x, y, x+w, y+h), radius=op.get('radius', 0), **options)
        elif op['op'] == 'text':
            font = ImageFont.truetype(str(ROOT / op['file']), round(op['size']))
            x, y, width = op['args']
            lines = []
            for paragraph in op['text'].split('\n'):
                line = ''
                for word in paragraph.split(' '):
                    candidate = (line + ' ' + word).strip()
                    if width and line and font.getlength(candidate) > width:
                        lines.append(line); line = word
                    else:
                        line = candidate
                lines.append(line)
            for line in lines:
                length = font.getlength(line)
                assert not width or length <= width, (path.name, line, length, width)
                xx = x + (width - length) / 2 if op['align'] == 'center' else x
                box = (xx, y, xx+length, y+op['size']*1.3)
                assert box[0] >= 0 and box[2] <= size[0] and box[3] <= size[1], (path.name, line, box)
                text_bounds.append({'text': line, 'bounds': box})
                draw.text((xx, y), line, font=font, fill=color, anchor='lt')
                y += op['size'] * 1.3
        else:
            raise AssertionError('unsupported UI operation: ' + op['op'])
        canvas = Image.alpha_composite(canvas, layer)
    dest = path.with_name(path.name.replace('-draws.json', '.png'))
    canvas.convert('RGB').save(dest)
    return {'image': dest.name, 'text': text_bounds}


def main():
    run(ROOT / 'scripts/verify_clearcut_fusions.lua', 'FUSION_CAPTURE=true')
    report = [render(path) for path in sorted(OUT.glob('fusion-*-draws.json'))]
    (OUT / 'fusion-ui-layout.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print('FUSION_UI_PREVIEW_OK screens=' + str(len(report)) + ' size=1280x720 window=none')


if __name__ == '__main__':
    main()
