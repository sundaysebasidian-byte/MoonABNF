# Explicit composed prose languages

This composed-prose extension is available on the public `review/moonbit-20261030` branch (verified snapshot: `64bf3996e06f7b082ac8d793e586ad3983494268`). It is not included in the existing package-registry release. Explicit prose bindings define application-specific languages; natural-language prose does not have a canonical executable meaning.

`ProsePredicate` retains `Words` and `SymbolRange`, and adds:

- `Concat(parts)`: sequence of languages; empty list matches epsilon.
- `Alternative(parts)`: union; empty list is the empty language.
- `Repetition(min, max, part)`: min/max copies, `None` means unbounded; finite bounds must be ordered and within 0..1,000,000, the same representation limit as parsed ABNF repetitions.

For example an application can explicitly bind `<name>` to a Han-range initial symbol followed by any number of that range or ASCII digits:

```moonbit
let name = @moonabnf.Concat([
  @moonabnf.SymbolRange(0x4E00, 0x4E02),
  @moonabnf.Repetition(0, None, @moonabnf.Alternative([
    @moonabnf.SymbolRange(48, 57),
    @moonabnf.SymbolRange(0x4E00, 0x4E02),
  ])),
])
let program = @moonabnf.compile_scalar(
  b"s = <name>\r\n",
  bindings=[{ name: "name", predicate: name }],
).unwrap()
```

This intentionally small example range does not claim to implement all Unicode identifiers. The compiled program owns a lowered expression snapshot; modifying the caller's arrays afterwards does not modify its language. Byte compilation retains the byte domain; scalar compilation selects Unicode scalar values, not arbitrary external encodings.

Compositions can express infinite regular languages, unlike a finite word list. They remain declarations, not executable callbacks. They cannot reference grammar rules from inside the predicate; the enclosing ABNF can reference named grammar rules and use the bound language within left recursion. Unknown prose is still rejected, never guessed.

Compilation charges work and grammar nodes for traversal and expansion. Composition traversal is limited to 64 levels, including leaf levels, so caller-created cyclic arrays terminate with compile-budget instead of recursive crashes. Shared subexpressions are permitted but charged per occurrence. No derived equality/debug display is used while handling invalid input; callers should not attempt to print or structurally compare cyclic expressions themselves. Matching retains existing work/state/input budgets; epsilon repetition is not an instruction to loop indefinitely. Compilation depth is an explicit API resource bound, not ABNF syntax invalidity.

Tree witnesses retain the grammar occurrence's source offset after lowering, including repetition children. One finite witness is returned, not all ambiguous derivations. Local failure explanations for generalized left recursion remain unavailable.

Implementation-owner checks: four backends each90/90 before independent added tests; direct mutable cycle, snapshot mutation, empty/epsilon languages, left recursion, min/max errors, scalar errors and example spans. Independent review results are recorded separately and are not inferred from these checks.
