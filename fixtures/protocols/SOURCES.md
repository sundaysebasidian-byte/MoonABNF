# Protocol corpus provenance

URI: RFC3986 Appendix A, T. Berners-Lee, R. Fielding, L. Masinter, January 2005. The collected grammar is retained, including IPv6 and relative references. Only `path-empty = 0<pchar>` is replaced by the equivalent empty literal because this compiler rejects prose values. See licenses/rfc3986-notice for the original copyright/license; this grammar is not relicensed as MIT. URI syntax does not implement scheme semantics, DNS lookup, port-range policy, normalization, percent decoding or the RFC host first-match-wins disambiguation rule.

Cookie: RFC6265 §§4.1.1 and 4.2.1, A. Barth, April 2011; copyright IETF Trust. `cookie-string`, `cookie-pair`, `cookie-name`, `cookie-value`, `cookie-octet` are collected together. `token`/`tchar` use the explicit RFC9110 §5.6.2 equivalent HTTP token character class. See licenses/rfc6265-BSD and licenses/rfc9110-BSD. No cookie state/domain/security policy is implemented.

Original RFC URLs and grammar SHA256 are in sources.json. Inputs/tests and surrounding MoonBit adapter code are self-authored MIT examples. No third-party test suite is copied. Embedded grammar and CRLF fixture bytes are checked by scripts/verify_protocol_fixtures.py during acceptance.
