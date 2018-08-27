# Used by "mix format"
[
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120,
  locals_without_parens: [
    send: 2,
    inspect: 1
    info: 1,
    debug: 1,
    error: 1,
    warn: 1
  ]
]
