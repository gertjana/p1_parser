defmodule P1Parser do
  use Combine
  import Combine.Parsers.Base
  import Combine.Parsers.Text
  @moduledoc """
    Understands the P1 format of Smartmeters and translates them to elixir types
  """

  # credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart

  @doc """
    Parses a line of text according to the P1 protocol

  ## Examples

      iex> P1Parser.parse("1-0:1.7.0(01.193*kW)")
      {:ok, [:current_energy, :consume, 1.193]}

  """
  def parse(line) do
    case Combine.parse(line, parser()) do
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  end

  defp parser do
    choice(nil, [
      header_parser(),
      version_parser(),
      timestamp_parser(),
      total_energy_parser(),
      current_energy_parser(),
      amperage_parser(),
      voltage_parser(),
      gas_parser(),
     # catchall_parser()
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
    |> word_of(~r/.+/)
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
    |> ignore(string("kWh)"))
  end

  # 1-0:1.7.0(01.193*kW)
  # 1-0:2.7.0(00.000*kW)
  defp current_energy_parser do
    map(string("1-0:"), fn _ -> :current_energy end)
    |> map(digit(), &(direction(&1)))
    |> ignore(string(".7."))
    |> ignore(digit())
    |> between(char("("), float(), char("*"))
    |> ignore(string("kW)"))
  end

  # 1-0:32.7.0(220.1*V)
  # 1-0:52.7.0(220.2*V)
  # 1-0:72.7.0(220.3*V)
  defp voltage_parser do
    map(string("1-0:"), fn _ -> :voltage end)
    |> map(both(digit(), digit(), fn a, b -> Enum.join([a, b]) |> String.to_integer end), &(phase(&1)))
    |> ignore(string(".7.0"))
    |> between(char("("), float(), char("*"))
    |> ignore(string("V)"))
  end

  # 1-0:31.7.0(001*A)
  # 1-0:51.7.0(002*A)
  # 1-0:71.7.0(003*A)
  defp amperage_parser do
    map(string("1-0:"), fn _ -> :amperage end)
    |> map(both(digit(), digit(), fn a, b -> Enum.join([a, b]) |> String.to_integer end), &(phase(&1)))
    |> ignore(string(".7.0"))
    |> between(char("("), integer(), char("*"))
    |> ignore(string("A)"))
  end

  # 0-1:24.2.1(101209112500W)(12785.123*m3)
  defp gas_parser do
    map(string("0-1:24.2.1"), fn _ -> :gas end)
    |> map(between(char("("), word_of(~r/\d+/), char("W")), &(timestamp(&1)))
    |> ignore(char(")"))
    |> between(char("("), float(), char("*"))
    |> ignore(string("m3)"))
  end

  defp timestamp(text) do
    [date | time] = text
      |> String.codepoints
      |> Enum.chunk(2)
      |> Enum.map(&Enum.join/1)
      |> Enum.chunk(3)
    "20" <> Enum.join(date, "-") <> " " <> Enum.join(hd(time), ":") 
  end

  defp phase(x) do
    case x do
      31 -> :l1
      32 -> :l1
      51 -> :l2
      52 -> :l2
      71 -> :l3
      72 -> :l3
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
