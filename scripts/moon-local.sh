#!/bin/sh
set -eu
SDK=${MOONABNF_SDK:-/Users/sebasidian/Documents/Codex/2026-09-10/ni-q/work/moonbit-sdk}
export MOON_HOME="$SDK"
export PATH="$SDK/bin:$PATH"
exec moon "$@"
