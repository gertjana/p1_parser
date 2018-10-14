defmodule P1.Parser do
  use Combine
  import Combine.Parsers.Base
  import Combine.Parsers.Text
  @moduledoc """
    Understands the P1 format of Smartmeters and translates them to elixir types
  """

  # credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart

  @doc false
  def parse(line) do
    case Combine.parse(line, parser()) do
      {:error, reason} -> {:error, reason}
      result           -> {:ok, result}
    end
  end

  @doc false
  def parse!(line) do
    case Combine.parse(line, parser()) do
      {:error, reason} -> raise reason
      result           -> result
    end
  end

  defp parser do
    choice(nil, [
      header_parser(),
      version_parser(),
      timestamp_parser(),
      equipment_identifier_parser(),
      tariff_indicator_parser(),
      total_energy_parser(),
      current_energy_parser(),
      power_failures_parser(),
      long_power_failures_parser(),
      long_failures_log_parser(),
      voltage_swells_parser(),
      voltage_sags_parser(),
      voltage_parser(),
      amperage_parser(),
      active_power_parser(),
      message_parser(),
      mbus_device_type_parser(),
      mbus_equipment_identifier_parser(),
      mbus_device_measurement_parser()
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
    |> parens(word())
  end

  # 0-0:96.1.1(4B384547303034303436333935353037)
  # 0-1:96.1.0(3232323241424344313233343536373839)
  defp equipment_identifier_parser do
    map(string("0-"), fn _ -> :equipment_identifier end)
    |> digit()
    |> ignore(string(":96.1.1"))
    |> parens(word_of(~r/[0-9a-f]+/i))
  end

  # 0-0:1.0.0(101209113020W)
  defp timestamp_parser do
    map(string("0-0:1.0.0"), fn _ -> :timestamp end)
    |> parens(map(word_of(~r/\d+[SW]/), &(timestamp(&1))))
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
    |> parens(unit(float()))
  end

  # 0-0:96.14.0(0002)
  defp tariff_indicator_parser do
    map(string("0-0:96.14.0"), fn _ -> :tariff_indicator end)
    |> parens(map(integer(), &(tariff(&1))))
  end

  # 1-0:1.7.0(01.193*kW)
  # 1-0:2.7.0(00.000*kW)
  defp current_energy_parser do
    map(string("1-0:"), fn _ -> :current_energy end)
    |> map(digit(), &(direction(&1)))
    |> ignore(string(".7."))
    |> ignore(digit())
    |> parens(unit(float()))
  end

  defp event(previous \\ nil) do
    previous
    |> parens(ts())
    |> parens(unit(integer())) 
  end

  # 0-0:96.7.21(00004)
  defp power_failures_parser do
    map(string("0-0:96.7.21"), fn _ -> :power_failures end)
    |> parens(integer())
  end

  # 0-0:96.7.9(00002)
  defp long_power_failures_parser do
    map(string("0-0:96.7.9"), fn _ -> :long_power_failures end)
    |> parens(integer())
  end

  # 1-0:99.97.0(2)(0-0:96.7.19)(101208152415W)(0000000240*s)(101208151004W)(0000000301*s)
  defp long_failures_log_parser do
    map(string("1-0:99.97.0"), fn _ -> :long_failures_log end)
    |> parens(integer())
    |> ignore(string("(0-0:96.7.19)"))
    |> many(sequence([event()]))
  end

  # 1-0:32.32.0(00002)
  # 1-0:52.32.0(00001)
  # 1-0:72.32.0(00000)
  defp voltage_sags_parser do
    map(string("1-0:"), fn _ -> :voltage_sags end)
    |> map(both(digit(), digit(), fn a, b -> Enum.join([a, b]) |> String.to_integer end), &(phase(&1)))
    |> ignore(string(".32.0"))
    |> parens(integer())
  end

  # 1-0:32.36.0(00000)
  # 1-0:52.36.0(00003)
  # 1-0:72.36.0(00000)
  defp voltage_swells_parser do
    map(string("1-0:"), fn _ -> :voltage_swells end)
    |> map(both(digit(), digit(), fn a, b -> Enum.join([a, b]) |> String.to_integer end), &(phase(&1)))
    |> ignore(string(".36.0"))
    |> parens(integer())
  end

  # 1-0:32.7.0(220.1*V)
  # 1-0:52.7.0(220.2*V)
  # 1-0:72.7.0(220.3*V)
  defp voltage_parser do
    map(string("1-0:"), fn _ -> :voltage end)
    |> map(both(digit(), digit(), fn a, b -> Enum.join([a, b]) |> String.to_integer end), &(phase(&1)))
    |> ignore(string(".7.0"))
    |> parens(unit(float(), string("V")))
  end

  # 1-0:31.7.0(001*A)
  # 1-0:51.7.0(002*A)
  # 1-0:71.7.0(003*A)
  defp amperage_parser do
    map(string("1-0:"), fn _ -> :amperage end)
    |> map(both(digit(), digit(), fn a, b -> Enum.join([a, b]) |> String.to_integer end), &(phase(&1)))
    |> ignore(string(".7.0"))
    |> parens(unit(integer(), string("A")))
  end

  # 1-0:21.7.0(01.111*kW)
  # 1-0:41.7.0(02.222*kW)
  # 1-0:61.7.0(03.333*kW)
  # 1-0:22.7.0(04.444*kW)
  # 1-0:42.7.0(05.555*kW)
  # 1-0:62.7.0(06.666*kW)
  defp active_power_parser do
    map(string("1-0:"), fn _ -> :active_power end)
    |> map(digit(), &(active_power_phase(&1)))
    |> map(digit(), &(direction(&1)))
    |> ignore(string(".7.0"))
    |> parens(unit(float(), string("kW")))
  end

  defp message_parser do
    map(string("0:96.13.0"), fn _ -> :text_message end)
    |>parens(map(word_of(~r/[0-9a-f]+/i), &(Hexate.decode(&1))))
  end

  # 0-1:24.1.0(003)
  defp mbus_device_type_parser do
    map(string("0-"), fn _ -> :mbus_device_type end)
    |> digit()
    |> ignore(string(":24.1.0"))
    |> parens(integer())
  end

  # 0-1:96.1.0(3232323241424344313233343536373839)
  defp mbus_equipment_identifier_parser do
    map(string("0-"), fn _ -> :mbus_equipment_identifier end)
    |> digit()
    |> ignore(string(":96.1.0"))
    |> parens(word_of(~r/[0-9a-f]+/i))
  end

  # 0-1:24.2.1(101209112500W)(12785.123*m3)
  defp mbus_device_measurement_parser do
    map(string("0-"), fn _ -> :mbus_device_measurement end)
    |> digit()
    |> ignore(string(":24.2.1"))
    |> parens(ts())
    |> parens(unit(float()))
  end

  # Helper functions

  defp ts(previous \\ nil) do
    previous |> map(word_of(~r/\d+[SW]/), &(timestamp(&1)))
  end

  defp timestamp(text) do
    dst = case String.last(text) do
      "S" -> "+01:00"
      "W" -> "+02:00"
    end
    [date | time] = text
      |> String.slice(0 .. String.length(text) - 1)
      |> String.codepoints
      |> Enum.chunk_every(2)
      |> Enum.map(&Enum.join/1)
      |> Enum.chunk_every(3)
    "20" <> Enum.join(date, "-") <> "T" <> Enum.join(hd(time), ":") <> dst
  end

  defp parens(previous, parser) do 
    previous |> between(ignore(char("(")), parser, ignore(char(")")))
  end

  defp unit(parser) do
    pair_both(parser, pair_right(ignore(char("*")), word()))    
  end

  defp unit(parser, unit) do
    pair_both(parser, pair_right(ignore(char("*")), unit))
  end

  defp phase(x) do
    case x do
      l when l in [2, 31, 32] -> :l1
      l when l in [4, 51, 52] -> :l2
      l when l in [6, 71, 72] -> :l3
       _ -> x
    end
  end

  defp active_power_phase(x) do
    case x do
      2 -> :l1
      4 -> :l2
      6 -> :l3
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
