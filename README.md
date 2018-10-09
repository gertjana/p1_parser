[![codebeat badge](https://codebeat.co/badges/bb2e3c59-1bfc-4cac-88e6-1a7064eca124)](https://codebeat.co/projects/github-com-gertjana-p1_parser-master) [![Build Status](https://travis-ci.org/gertjana/p1_parser.svg?branch=master)](https://travis-ci.org/gertjana/p1_parser)

# P1Parser

Parses telegram's as they are output through the P1 serial port of a smartmeter

## Installation

```elixir
def deps do
  [
    {:p1_parser, "~> 0.1.2"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/p1_parser](https://hexdocs.pm/p1_parser).

#todo

 - ~~Parse units~~
 - Parse Summer/Winter time information in timestamp
 - ~~return structs~~
 - Parse entire telegram
 - split out tests
