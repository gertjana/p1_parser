defmodule P1.Parser do
  use Combine
  import Combine.Parsers.Base
  import Combine.Parsers.Text

  @moduledoc """
    Understands the P1 format of Smartmeters and translates them to elixir types

    As the specification says that all lines wih obis codes are optional and the order in which they appear is free, 
    this parser works with the choice parser from the combine library
    this means all parsers that can parse a line with an obis code will be consulted
    and hopefully only one will return a valid result
  """

  # credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart

  @doc false
  def parse(line) do
    if (String.trim(line) == "") do
      {:ok, []}
    else
      case Combine.parse(line, line_parser(nil)) do
        {:error, reason} -> {:error, reason}
        result           -> {:ok, result}
      end
    end
  end

  @doc false
  def parse!(line) do
    case parse(line) do
      {:error, reason} -> raise reason
      {:ok, result}    -> result
    end
  end

  @doc false
  def parse_telegram(telegram) do
    case Combine.parse(telegram, telegram_parser(nil)) do
      {:error, reason} -> {:error, reason}
      result           -> {:ok, result}
    end
  end

  @doc false
  def parse_telegram!(telegram) do
    case parse_telegram(telegram) do
      {:error, reason} -> raise reason
      {:ok, result} -> result
    end
  end


#  CRC is a CRC16 value calculated over the preceding characters in the data message (from
#  “/” to “!” using the polynomial: x16+x15+x2+1). CRC16 uses no XOR in, no XOR out and is
#  computed with least significant bit first. The value is represented as 4 hexadecimal
#  characters (MSB first)

  @doc false
  def calculate_checksum(bytes) do
    IO.puts("#{String.first(bytes)}...#{String.last(bytes)}")
    algo = %{
      width: 16,
      poly: 0xA001,
      init: 0x00,
      refin: false,
      refout: false,
      xorout: 0x00
    }
    CRC.crc(algo, bytes) |> Hexate.encode
  end



  defp telegram_parser(previous \\ nil) do
    previous 
    |> pipe([word_of(~r/[^!]*/), char("!")], &Enum.join(&1))
    |> hex(4)
  end

  defp line_parser(previous \\ nil) do
    previous
    |> choice([header_parser(), obis_parser(), checksum_parser()])
  end

  defp obis_parser(previous \\ nil) do
    previous
    |> medium_channel_parser()
    |> ignore(char(":"))
    |> measurement_type_parser()
    |> values_parser()
    |> ignore(option(newline()))
  end

  defp medium_channel_parser(previous \\ nil) do
    previous
    |> pipe([integer(), char("-"), integer()], fn [t, _, c] -> P1.Channel.construct(t, c) end)
  end

  defp measurement_type_parser(previous \\ nil) do
    previous
    |> pipe([integer(), ignore(char(".")), integer(), ignore(char(".")), integer()], &to_tags(&1))
  end

  defp values_parser(previous \\ nil) do
    previous 
    |> many1(parens(value_parser()))
  end

  defp value_parser(previous \\ nil) do
    previous
    |> choice([
      timestamp_parser(),
      integer_with_unit_parser(),
      float_with_unit_parser(),
#      integer_parser(),
      word_of(~r/[\w\*\:\-\.]*/)
    ])
  end

  defp integer_with_unit_parser(previous \\ nil) do
    previous |> pipe([integer(), char("*"), word_of(~r/s|m3|V|A|kWh|kW/)], fn [v, _, u] -> %P1.Value{value: v, unit: u} end)
  end

  defp float_with_unit_parser(previous \\ nil) do
    previous |> pipe([float(), char("*"), word_of(~r/s|m3|V|A|kWh|kW/)], fn [v, _, u] -> %P1.Value{value: v, unit: u} end)
  end

  defp integer_parser(previous \\ nil) do
    previous |> map(integer() |> followed_by(char(")")), fn i -> %P1.Value{value: i, unit: ""} end)
  end

  defp unit_parser(previous \\ nil) do
    previous |> choice([string("s"), string("V"),string("A"),string("m3"),string("kW"),string("kWh")])
  end

  # /ISk5MT382-1000
  defp header_parser(previous \\ nil) do
    previous |> pipe([ignore(char("/")), word_of(~r/\w{3}/), ignore(char("5")), word_of(~r/.+/)], fn [m,n] -> %P1.Header{manufacturer: m, model: n} end)
  end

  # !DEB0
  defp checksum_parser(previous \\ nil) do
    previous |> pipe([char("!"), hex(4)], fn [_, c] -> %P1.Checksum{value: c} end)
  end

  # Helper functions

  defp timestamp_parser(previous \\ nil) do
    previous |> map(word_of(~r/\d+[SW]/), &(timestamp_to_utc(&1)))
  end

  defp timestamp_to_utc(text) do
    # as this is only valid in the netherlands, i can use this trick
    tz_offset = case String.last(text) do
      "S" -> "+02:00"
      "W" -> "+01:00"
    end
    [date | time] = text |> String.slice(0 .. String.length(text) - 1) |> String.codepoints
    |> Enum.chunk_every(2) |> Enum.map(&Enum.join/1) |> Enum.chunk_every(3)
    "20#{Enum.join(date, "-")}T#{Enum.join(hd(time), ":")}#{tz_offset}"
  end

#  defp hex, do: word_of(~r/[0-9a-f]+/i)
  defp hex(size) when is_integer(size), do: word_of(~r/[0-9a-f]{#{size}}/i)
#  defp hex(previous), do: previous |> word_of(~r/[0-9a-f]+/i)
  defp hex(previous, size), do: previous |> word_of(~r/[0-9a-f]{#{size}}/i)

#  defp parens(previous, parser), do: previous |> between(ignore(char("(")), parser, ignore(char(")")))
  defp parens(parser), do: between(ignore(char("(")), parser, ignore(char(")")))

#  defp unit(parser), do: pair_both(parser, pair_right(ignore(char("*")), word()))
#  defp unit(parser, unit), do: pair_both(parser, pair_right(ignore(char("*")), unit))

  defp to_tags(code) do
    tags = case code do
      [0, 2, 8]   -> [:version]
      [1, 0, 0]   -> [:timestamp]
      [1, 8, 1]   -> [:total, :energy, :consume, :low]
      [1, 8, 2]   -> [:total, :energy, :consume, :normal]
      [2, 8, 1]   -> [:total, :energy, :produce, :low]
      [2, 8, 2]   -> [:total, :energy, :produce, :normal]
      [1, 7, 0]   -> [:active, :power, :consume]
      [2, 7, 0]   -> [:active, :power, :produce]
      [96, 1, 1]  -> [:equipment_identifier]
      [96, 7, 9]  -> [:power_failures, :long]
      [96, 7, 21] -> [:power_failures, :short]
      [96, 14, 0] -> [:tariff_indicator]
      [99, 97, 0] -> [:power_failures, :event_log]
      [32, 32, 0] -> [:voltage_sags, :l1]
      [52, 32, 0] -> [:voltage_sags, :l2]
      [72, 32, 0] -> [:voltage_sags, :l3]
      [32, 36, 0] -> [:voltage_swells, :l1]
      [52, 36, 0] -> [:voltage_swells, :l2]
      [72, 36, 0] -> [:voltage_swells, :l3]
      [31, 7, 0]  -> [:active, :amperage, :l1]
      [51, 7, 0]  -> [:active, :amperage, :l2]
      [71, 7, 0]  -> [:active, :amperage, :l3]
      [32, 7, 0]  -> [:active, :voltage, :l1]
      [52, 7, 0]  -> [:active, :voltage, :l2]
      [72, 7, 0]  -> [:active, :voltage, :l3]
      [96, 13, 0] -> [:message]
      [21, 7, 0]  -> [:active, :power, :l1, :plus_p]
      [41, 7, 0]  -> [:active, :power, :l2, :plus_p]
      [61, 7, 0]  -> [:active, :power, :l3, :plus_p]
      [22, 7, 0]  -> [:active, :power, :l1, :min_p]
      [42, 7, 0]  -> [:active, :power, :l2, :min_p]
      [62, 7, 0]  -> [:active, :power, :l3, :min_p]
      [24, 1, 0]  -> [:mbus, :device_type]
      [96, 1, 0]  -> [:mbus, :equipment_identifier]
      [24, 2, 1]  -> [:mbus, :measurement]
      _ -> [:unknown]
    end
    %P1.Tags{tags: tags}
  end
end
