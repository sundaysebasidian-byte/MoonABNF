#!/bin/sh
set -eu
SDK=${MOONABNF_SDK:-/Users/sebasidian/Documents/Codex/2026-09-10/ni-q/work/moonbit-sdk}
export RUST_LOG=error
export MOON_HOME="$SDK"
export PATH="$SDK/bin:$PATH"
case "$("$SDK/bin/moonc" -v)" in
  "v0.10.14+7d59c7ec9 "*) ;;
  *) echo "MoonABNF requires compiler v0.10.14+7d59c7ec9; see TOOLCHAIN.lock" >&2; exit 2 ;;
esac
exec moon "$@"
