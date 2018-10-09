defmodule P1.Parser do
  use Combine
  import Combine.Parsers.Base
  import Combine.Parsers.Text
  @moduledoc """
    Understands the P1 format of Smartmeters and translates them to elixir types
  """

  # credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart

  def parser do
    choice(nil, [
      header_parser(),
      version_parser(),
      timestamp_parser(),
      equipment_identifier_parser(),
      tariff_indicator_parser(),
      total_energy_parser(),
      current_energy_parser(),
      amperage_parser(),
      voltage_parser(),
      gas_parser()
    ])
  end

  # /ISk5MT382-1000
  defp header_parser do
    map(char("/"), fn _ -> :header end)
    |> word_of(~r/\w{3}/)
    |> ignore(char("5"))
    |> word_of(~r/.+/)
  end

  # 1-3:0.2.8(50)
  defp version_parser do
    map(string("1-3:0.2.8"), fn _ -> :version end)
    |> between(char("("), word(), char(")"))
  end

  # 0-0:96.1.1(4B384547303034303436333935353037)
  defp equipment_identifier_parser do
    map(string("0-0:96.1.1"), fn _ -> :equipment_identifier end)
    |> between(char("("), word_of(~r/[0-9a-f]+/i), char(")"))
  end

  # 0-0:1.0.0(101209113020W)
  defp timestamp_parser do
    map(string("0-0:1.0.0"), fn _ -> :timestamp end)
    |> map(between(char("("), word_of(~r/\d+/), char("W")), &(timestamp(&1)))
    |> ignore(char(")"))
  end

  # 1-0:1.8.1(123456.789*kWh)
  # 1-0:1.8.2(123456.789*kWh)
  # 1-0:2.8.1(123456.789*kWh)
  # 1-0:2.8.2(123456.789*kWh)
  defp total_energy_parser do
    map(string("1-0:"), fn _ -> :total_energy end)
    |> map(digit(), &(direction(&1)))
    |> ignore(string(".8."))
    |> map(digit(), &(tariff(&1)))
    |> between(char("("), float(), char("*"))
    |> string("kWh")
    |> ignore(string(")"))
  end

  # 0-0:96.14.0(0002)
  defp tariff_indicator_parser do
    map(string("0-0:96.14.0"), fn _ -> :tariff_indicator end)
    |> between(char("("), map(integer(), &(tariff(&1))) , char(")"))
  end

  # 1-0:1.7.0(01.193*kW)
  # 1-0:2.7.0(00.000*kW)
  defp current_energy_parser do
    map(string("1-0:"), fn _ -> :current_energy end)
    |> map(digit(), &(direction(&1)))
    |> ignore(string(".7."))
    |> ignore(digit())
    |> between(char("("), float(), char("*"))
    |> string("kW")
    |> ignore(string(")"))
  end

  # 1-0:32.7.0(220.1*V)
  # 1-0:52.7.0(220.2*V)
  # 1-0:72.7.0(220.3*V)
  defp voltage_parser do
    map(string("1-0:"), fn _ -> :voltage end)
    |> map(both(digit(), digit(), fn a, b -> Enum.join([a, b]) |> String.to_integer end), &(phase(&1)))
    |> ignore(string(".7.0"))
    |> between(char("("), float(), char("*"))
    |> string("V")
    |> ignore(string(")"))
  end

  # 1-0:31.7.0(001*A)
  # 1-0:51.7.0(002*A)
  # 1-0:71.7.0(003*A)
  defp amperage_parser do
    map(string("1-0:"), fn _ -> :amperage end)
    |> map(both(digit(), digit(), fn a, b -> Enum.join([a, b]) |> String.to_integer end), &(phase(&1)))
    |> ignore(string(".7.0"))
    |> between(char("("), integer(), char("*"))
    |> string("A")
    |> ignore(string(")"))
  end

  # 0-1:24.2.1(101209112500W)(12785.123*m3)
  defp gas_parser do
    map(string("0-1:24.2.1"), fn _ -> :gas end)
    |> map(between(char("("), word_of(~r/\d+/), char("W")), &(timestamp(&1)))
    |> ignore(char(")"))
    |> between(char("("), float(), char("*"))
    |> string("m3")
    |> ignore(string(")"))
  end

  defp timestamp(text) do
    [date | time] = text
      |> String.codepoints
      |> Enum.chunk_every(2)
      |> Enum.map(&Enum.join/1)
      |> Enum.chunk_every(3)
    "20" <> Enum.join(date, "-") <> " " <> Enum.join(hd(time), ":")
  end

  defp phase(x) do
    case x do
      l when l in [31, 32] -> :l1
      l when l in [51, 52] -> :l2
      l when l in [71, 72] -> :l3
       _ -> x
    end
  end

  defp direction(x) do
    case x do
      1 -> :consume
      2 -> :produce
      _ -> x
    end
  end

  defp tariff(x) do
    case x do
      1 -> :low
      2 -> :normal
      _ -> x
    end
  end
end
