#!/bin/sh
# Test runner: executes every tests/spec_*.lua in a headless nvim.
# A spec exits 0 (pass) or 1 (fail, details on stderr). Usage:
#   tests/run.sh [spec_name ...]
set -u

dir=$(cd "$(dirname "$0")" && pwd)
export ACAI_TEST_DIR="$dir"

if [ "$#" -gt 0 ]; then
  specs=""
  for name in "$@"; do
    specs="$specs $dir/${name#"$dir"/}"
  done
else
  specs=$(ls "$dir"/spec_*.lua)
fi

fail=0
for spec in $specs; do
  name=$(basename "$spec")
  out=$(perl -e 'alarm 30; exec @ARGV' nvim --headless --noplugin -i NONE \
    -u "$dir/minimal_init.lua" -c "luafile $spec" </dev/null 2>&1)
  if [ "$?" -eq 0 ]; then
    echo "PASS $name"
  else
    fail=1
    echo "FAIL $name"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
done
exit $fail
