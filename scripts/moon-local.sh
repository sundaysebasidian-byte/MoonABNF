#!/bin/sh
set -eu
SDK=${MOONABNF_SDK:-${MOON_HOME:-}}
if [ -z "$SDK" ]; then
  echo "Set MOONABNF_SDK to your existing MoonBit SDK; see TOOLCHAIN.lock" >&2
  exit 2
fi
export RUST_LOG=error
export MOON_HOME="$SDK"
export PATH="$SDK/bin:$PATH"
case "$("$SDK/bin/moonc" -v)" in
  "v0.10.18+6c83a7f62 "*) ;;
  *) echo "MoonABNF requires compiler v0.10.18+6c83a7f62; see TOOLCHAIN.lock" >&2; exit 2 ;;
esac
exec moon "$@"
