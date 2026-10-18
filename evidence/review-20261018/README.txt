Local evidence, 2026-10-18, by moonf. NOT remote CI, NOT registry.
Toolchain: moon 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, Node v24.18.0, macOS arm64.
Start commit: 646f32c53333ba011ac29cc7bfd80c46fb0f45ce (review/moonbit-20261015-sync).
test-{js,wasm-gc,native,wasm}.log: moon test -> 41/41 each (baseline before the new example: 36/36).
example-request-line-*.log: moon run examples/request_line/cmd (identical output on all three).
acceptance-summary.{log,json}: scripts/acceptance.py, 16 phases passed (local run, output dir outside the repo).
