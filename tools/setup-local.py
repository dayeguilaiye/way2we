"""Create a stable local-only encryption key once; keep it outside version control."""
from pathlib import Path
import os
import secrets
root = Path(__file__).resolve().parents[1]
directory = root / '.secrets'
directory.mkdir(mode=0o700, exist_ok=True)
path = directory / 'auth.key'
try:
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
except FileExistsError:
    pass
else:
    with os.fdopen(fd, 'w') as stream:
        stream.write(secrets.token_hex(32) + '\n')
print('Local authentication key ready.')
