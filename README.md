[![codebeat badge](https://codebeat.co/badges/bb2e3c59-1bfc-4cac-88e6-1a7064eca124)](https://codebeat.co/projects/github-com-gertjana-p1_parser-master) [![Build Status](https://travis-ci.org/gertjana/p1_parser.svg?branch=master)](https://travis-ci.org/gertjana/p1_parser) [![Hex.pm](https://img.shields.io/hexpm/v/p1_parser.svg)](https://hex.pm/packages/p1_parser) [![Hex.pm](https://img.shields.io/hexpm/dt/p1_parser.svg)](https://hex.pm/packages/p1_parser)


# P1 Parser

Parses telegram's as they are output through the P1 serial port of a smartmeter

## Installation

```elixir
def deps do
  [
    {:p1_parser, "~> 0.1.3"}
  ]
end
```

## Usage 

Get a usb to p1 cable and plug it in, you should see it appear as a serial device
now the smartmeter will ouput a telegram every 10 seconds. split them into lines and Parse them by

```elixir
telegram 
  |> String.split("\n")
  |> Enum.map(fn line -> line 
                         |> P1.parse!     # Parses into elixir types
                         |> P1.to_struct  # Converts to a struct
              end)
```

## Documentation 

The docs can be found at [https://hexdocs.pm/p1_parser](https://hexdocs.pm/p1_parser).

## Contribute

`|> fork |> feature branch |> pull request`

## Todo's

 - ~~Parse units~~
 - ~~Parse Summer/Winter time information in timestamp~~
 - ~~return structs~~
 - Parse entire telegram
 - Validate checksum

