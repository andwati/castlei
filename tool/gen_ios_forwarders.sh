#!/usr/bin/env bash
# Regenerates the iOS pod's forwarder sources from the pinned Stockfish checkout.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import glob, os
root = 'native/stockfish/src'
files = []
for pat in ['*.cpp', 'nnue/*.cpp', 'nnue/features/*.cpp', 'syzygy/*.cpp']:
    files += sorted(glob.glob(f'{root}/{pat}'))
files = [f for f in files if not f.endswith('/main.cpp')]
out = 'packages/castlei_native/ios/Classes'
os.makedirs(out, exist_ok=True)
for f in os.listdir(out):
    os.remove(f'{out}/{f}')
for f in files:
    rel = f[len(root) + 1:]
    open(f'{out}/sf_' + rel.replace('/', '_'), 'w').write(
        '// Forwarder: compiles the pinned Stockfish source in place (see tool/fetch_engine.sh).\n'
        f'#include "../../../../native/stockfish/src/{rel}"\n')
open(f'{out}/castlei_adapter.cpp', 'w').write(
    '// Forwarder for the app-owned C ABI adapter.\n#include "../../../../native/adapter.cpp"\n')
print(len(files), 'stockfish forwarders + adapter')
PY
