defmodule P1.Parser do
  use Combine
  import Combine.Parsers.Base
  import Combine.Parsers.Text
  alias P1.Channel, as: Channel
  alias P1.Tags, as: Tags
  @moduledoc """
    Understands the P1 format of Smartmeters and translates them to elixir types

    As the specification says that all lines wih obis codes are optional and the order in which they appear is free, 
    this parser works with the choice parser from the combine library
    this means all parsers that can parse a line with an obis code will be consulted
    and hopefully only one will return a valid result
  """

  # credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart
  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
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

  # Parsers

  defp telegram_parser(previous) do
    previous
    |> pipe([word_of(~r/[^!]*/), char("!")], &Enum.join(&1))
    |> hex(4)
  end

  defp line_parser(previous) do
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

  defp medium_channel_parser(previous) do
    previous
    |> pipe([integer(), char("-"), integer()], fn [t, _, c] -> Channel.construct(t, c) end)
  end

  defp measurement_type_parser(previous) do
    previous
    |> pipe([integer(), ignore(char(".")), integer(), ignore(char(".")), integer()], &to_tags(&1))
  end

  defp values_parser(previous) do
    previous
    |> many1(parens(value_parser()))
  end

  defp value_parser(previous \\ nil) do
    previous
    |> choice([
      timestamp_parser(),
      integer_with_unit_parser(),
      float_with_unit_parser(),
      word_of(~r/[\w\*\:\-\.]*/)
    ])
  end

  defp float_with_unit_parser(previous \\ nil) do
    previous |> pipe([float(), ignore(char("*")), unit_parser()], &to_value(&1))
  end

  defp integer_with_unit_parser(previous \\ nil) do
    previous |> pipe([integer(), ignore(char("*")), unit_parser()], &to_value(&1))
  end

  defp unit_parser(previous \\ nil) do
    previous |> word_of(~r/s|m3|V|A|kWh|kW/)
  end

  defp hexadecimal_parser(previous \\ nil) do
      previous |> map(word_of(~r/[0-9a-f]/i), fn txt -> Hexate.decode(txt) end)
  end

  defp header_parser(previous \\ nil) do
    previous |> pipe([ignore(char("/")), word_of(~r/\w{3}/), ignore(char("5")), word_of(~r/.+/)],
                  fn [m, n] -> %P1.Header{manufacturer: m, model: n} end)
  end

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

  defp hex(size) when is_integer(size), do: word_of(~r/[0-9a-f]{#{size}}/i)
  defp hex(previous, size), do: previous |> word_of(~r/[0-9a-f]{#{size}}/i)

  defp parens(parser), do: between(char("("), parser, char(")"))

  defp to_value([value, unit]), do: %P1.Value{value: value, unit: unit}

  defp to_tags([0, 2, 8]),   do: %Tags{tags: [general: :version]}
  defp to_tags([1, 0, 0]),   do: %Tags{tags: [general: :timestamp]}
  defp to_tags([96, 1, 1]),  do: %Tags{tags: [general: :equipment_identifier]}
  defp to_tags([96, 14, 0]), do: %Tags{tags: [general: :tariff_indicator]}
  defp to_tags([1, 8, 1]),   do: %Tags{tags: [energy: :total, direction: :consume, tariff: :low]}
  defp to_tags([1, 8, 2]),   do: %Tags{tags: [energy: :total, direction: :consume, tariff: :normal]}
  defp to_tags([2, 8, 1]),   do: %Tags{tags: [energy: :total, direction: :produce, tariff: :low]}
  defp to_tags([2, 8, 2]),   do: %Tags{tags: [energy: :total, direction: :produce, tariff: :normal]}
  defp to_tags([1, 7, 0]),   do: %Tags{tags: [power: :active, phase: :all, direction: :consume]}
  defp to_tags([2, 7, 0]),   do: %Tags{tags: [power: :active, phase: :all, direction: :produce]}
  defp to_tags([21, 7, 0]),  do: %Tags{tags: [power: :active, phase: :l1, direction: :consume]}
  defp to_tags([41, 7, 0]),  do: %Tags{tags: [power: :active, phase: :l2, direction: :consume]}
  defp to_tags([61, 7, 0]),  do: %Tags{tags: [power: :active, phase: :l3, direction: :consume]}
  defp to_tags([22, 7, 0]),  do: %Tags{tags: [power: :active, phase: :l1, direction: :produce]}
  defp to_tags([42, 7, 0]),  do: %Tags{tags: [power: :active, phase: :l2, direction: :produce]}
  defp to_tags([62, 7, 0]),  do: %Tags{tags: [power: :active, phase: :l3, direction: :produce]}
  defp to_tags([31, 7, 0]),  do: %Tags{tags: [amperage: :active, phase: :l1]}
  defp to_tags([51, 7, 0]),  do: %Tags{tags: [amperage: :active, phase: :l2]}
  defp to_tags([71, 7, 0]),  do: %Tags{tags: [amperage: :active, phase: :l3]}
  defp to_tags([32, 7, 0]),  do: %Tags{tags: [voltage: :active, phase: :l1]}
  defp to_tags([52, 7, 0]),  do: %Tags{tags: [voltage: :active, phase: :l2]}
  defp to_tags([72, 7, 0]),  do: %Tags{tags: [voltage: :active, phase: :l3]}
  defp to_tags([96, 7, 9]),  do: %Tags{tags: [power_failures: :long]}
  defp to_tags([96, 7, 21]), do: %Tags{tags: [power_failures: :short]}
  defp to_tags([99, 97, 0]), do: %Tags{tags: [power_failures: :event_log]}
  defp to_tags([32, 32, 0]), do: %Tags{tags: [voltage: :sags, phase: :l1]}
  defp to_tags([52, 32, 0]), do: %Tags{tags: [voltage: :sags, phase: :l2]}
  defp to_tags([72, 32, 0]), do: %Tags{tags: [voltage: :sags, phase: :l3]}
  defp to_tags([32, 36, 0]), do: %Tags{tags: [voltage: :swells, phase: :l1]}
  defp to_tags([52, 36, 0]), do: %Tags{tags: [voltage: :swells, phase: :l2]}
  defp to_tags([72, 36, 0]), do: %Tags{tags: [voltage: :swells, phase: :l3]}
  defp to_tags([96, 13, 0]), do: %Tags{tags: [message: :text]}
  defp to_tags([96, 13, 1]), do: %Tags{tags: [message: :code]}
  defp to_tags([24, 1, 0]),  do: %Tags{tags: [mbus: :device_type]}
  defp to_tags([96, 1, 0]),  do: %Tags{tags: [mbus: :equipment_identifier]}
  defp to_tags([24, 2, 1]),  do: %Tags{tags: [mbus: :measurement]}
end
