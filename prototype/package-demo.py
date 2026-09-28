"""把原型及其本地字体、图片打包成可直接打开的单文件演示。"""
from pathlib import Path
import base64
import mimetypes
import re

root = Path(__file__).resolve().parent


def data_uri(path):
    mime = mimetypes.guess_type(path.name)[0] or 'application/octet-stream'
    return 'data:' + mime + ';base64,' + base64.b64encode(path.read_bytes()).decode()


def styles(path):
    value = path.read_text()
    def url(match):
        name = match.group(1).strip('"\'')
        target = path.parent / name
        return 'url("' + data_uri(target) + '")' if target.is_file() else match.group(0)
    return re.sub(r'url\(([^)]+)\)', url, value)


html = (root / 'index.html').read_text()
html = re.sub(r'<link rel="stylesheet" href="([^"]+)">', lambda m: '<style>' + styles(root / m.group(1)) + '</style>', html)
html = re.sub(r'<script src="([^"]+)"></script>', lambda m: '<script>' + (root / m.group(1)).read_text() + '</script>', html)
for path in sorted([*root.glob('assets/*.png'), *root.parent.glob('assets/plates/*.png')]):
    relative = 'assets/' + path.name if path.parent == root / 'assets' else '../assets/plates/' + path.name
    html = html.replace(relative, data_uri(path))
target = root / 'way2we-demo.html'
target.write_text(html)
print(f'{target} ({target.stat().st_size // 1024} KB)')
