[![codebeat badge](https://codebeat.co/badges/bb2e3c59-1bfc-4cac-88e6-1a7064eca124)](https://codebeat.co/projects/github-com-gertjana-p1_parser-master) [![Build Status](https://travis-ci.org/gertjana/p1_parser.svg?branch=master)](https://travis-ci.org/gertjana/p1_parser) [![Hex.pm](https://img.shields.io/hexpm/v/p1_parser.svg)](https://hex.pm/packages/p1_parser) [![Hex.pm](https://img.shields.io/hexpm/dt/p1_parser.svg)](https://hex.pm/packages/p1_parser)


# P1 Parser

Parses telegram's as they are output through the P1 serial port of a smartmeter

Note that this only applies to Dutch smartmeters. 

## Installation

```elixir
def deps do
  [
    {:p1_parser, "~> 0.2.2"}
  ]
end
```

## Usage 

Get a usb to p1 cable and plug it in, you should see it appear as a serial device

On an raspberry pi it will show up as `/dev/ttyUSB0`, now the smartmeter will ouput a telegram every x seconds

use a serial libray like for instance `nerves_uart` to connect to it and receive telegrams

each line in the telegram can now be parsed like this
```elixir
iex> P1.parse!("1-0:1.8.1(123456.789*kWh)")
```
Which will result in
```
[
  %P1.Channel{channel: 0, medium: :electricity},
  %P1.Tags{tags: [:total, :energy, :consume, :low]},
  [%P1.Value{unit: "kWh", value: 123456.789}]
]
```

## Documentation 

The docs can be found at [https://hexdocs.pm/p1_parser](https://hexdocs.pm/p1_parser).

## Contribute

`|> fork |> feature branch |> pull request`

## Reference 

I used https://www.netbeheernederland.nl/_upload/Files/Slimme_meter_15_a727fce1f1.pdf as a reference

## Todo's

 - ~~Parse units~~
 - ~~Parse Summer/Winter time information in timestamp~~
 - ~~return structs~~
 - ~~Convert timestamps to proper date/times~~
 - Parse entire telegram
 - Validate checksum

