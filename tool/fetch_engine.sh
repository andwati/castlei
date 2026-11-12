#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
revision=edb0d9db6731067ec50ce619ff372b463bc4dd5d
if [ ! -d native/stockfish/.git ]; then
  git clone --depth 1 --branch sf_19 https://github.com/official-stockfish/Stockfish.git native/stockfish
fi
test "$(git -C native/stockfish rev-parse HEAD)" = "$revision"
make -C native/stockfish/src net
if command -v sha256sum >/dev/null; then sha256sum native/stockfish/src/*.nnue; else shasum -a 256 native/stockfish/src/*.nnue; fi
