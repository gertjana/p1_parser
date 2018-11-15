defmodule P1ParserTest do
  use ExUnit.Case

  doctest P1

#  test "Send whole telegram" do
#    Path.expand("./test/examples")
#    |> File.ls!()
#    |> Enum.each(fn f ->
#      to_read = Path.expand("./test/examples/#{f}")
#        case File.read( to_read) do
#          {:ok, txt} ->
#          {:ok, [res, checksum]} = P1.parse_telegram(txt<>"!")
#            IO.puts("#{checksum} <-> #{P1.checksum(res)}")
#          x -> flunk(inspect(x))
#        end
#    end)
#  end

  test "send lines" do
    lines = """
      /ISk5\\2MT382-1000
      1-3:0.2.8(50)
      0-0:1.0.0(101209113020W)
      0-0:96.1.1(4B384547303034303436333935353037)
      1-0:1.8.1(123456.789*kWh)
      1-0:1.8.2(123456.789*kWh)
      1-0:2.8.1(123456.789*kWh)
      1-0:2.8.2(123456.789*kWh)
      0-0:96.14.0(0002)
      1-0:1.7.0(01.193*kW)
      1-0:2.7.0(00.000*kW)
      0-0:96.7.21(00004)
      0-0:96.7.9(00002)
      1-0:99.97.0(2)(0-0:96.7.19)(101208152415W)(0000000240*s)(101208151004W)(0000000301*s)
      1-0:32.32.0(00002)
      1-0:52.32.0(00001)
      1-0:72.32.0(00000)
      1-0:32.36.0(00000)
      1-0:52.36.0(00003)
      1-0:72.36.0(00000)
      0-
      0:96.13.0(416C6C20796F75722062617365206172652062656C6F6E6720746F207573)
      1-0:32.7.0(220.1*V)
      1-0:52.7.0(220.2*V)
      1-0:72.7.0(220.3*V)
      1-0:31.7.0(001*A)
      1-0:51.7.0(002*A)
      1-0:71.7.0(003*A)
      1-0:21.7.0(01.111*kW)
      1-0:41.7.0(02.222*kW)
      1-0:61.7.0(03.333*kW)
      1-0:22.7.0(04.444*kW)
      1-0:42.7.0(05.555*kW)
      1-0:62.7.0(06.666*kW)
      0-1:24.1.0(003)
      0-1:96.1.0(3232323241424344313233343536373839)
      0-1:24.2.1(101209112500W)(12785.123*m3)
      !EF2F
      """ |> String.split("\n")

    results = lines |> Enum.map(fn line -> P1.parse(line) end)

    assert results |> Enum.at(0)  == {:ok, [%P1.Header{manufacturer: "ISk", model: "\\2MT382-1000"}]}

    assert results |> Enum.at(1)  == {:ok, [%P1.Channel{channel: 3, medium: :electricity}, %P1.Tags{tags: [:version]}, ["50"]]}
    assert results |> Enum.at(2)  == {:ok, [%P1.Channel{channel: 0, medium: :abstract},    %P1.Tags{tags: [:timestamp]}, ["2010-12-09T11:30:20+01:00"]]}
    assert results |> Enum.at(3)  == {:ok, [%P1.Channel{channel: 0, medium: :abstract},    %P1.Tags{tags: [:equipment_identifier]}, ["4B384547303034303436333935353037"]]}
    assert results |> Enum.at(4)  == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:total, :energy, :consume, :low]}, [%P1.Value{value: 123_456.789, unit: "kWh"}]]}
    assert results |> Enum.at(5)  == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:total, :energy, :consume, :normal]}, [%P1.Value{value: 123_456.789, unit: "kWh"}]]}
    assert results |> Enum.at(6)  == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:total, :energy, :produce, :low]}, [%P1.Value{value: 123_456.789, unit: "kWh"}]]}
    assert results |> Enum.at(7)  == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:total, :energy, :produce, :normal]}, [%P1.Value{value: 123_456.789, unit: "kWh"}]]}
    assert results |> Enum.at(8)  == {:ok, [%P1.Channel{channel: 0, medium: :abstract},    %P1.Tags{tags: [:tariff_indicator]}, ["0002"]]}
    assert results |> Enum.at(9)  == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :consume]}, [%P1.Value{value: 1.193, unit: "kW"}]]}
    assert results |> Enum.at(10) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :produce]}, [%P1.Value{value: 0.0, unit: "kW"}]]}
    assert results |> Enum.at(11) == {:ok, [%P1.Channel{channel: 0, medium: :abstract},    %P1.Tags{tags: [:power_failures, :short]}, ["00004"]]}
    assert results |> Enum.at(12) == {:ok, [%P1.Channel{channel: 0, medium: :abstract},    %P1.Tags{tags: [:power_failures, :long]}, ["00002"]]}
    assert results |> Enum.at(13) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:power_failures, :event_log]},
            ["2", "0-0:96.7.19", "2010-12-08T15:24:15+01:00", %P1.Value{value: 240, unit: "s"}, "2010-12-08T15:10:04+01:00", %P1.Value{value: 301, unit: "s"}]]}
    assert results |> Enum.at(14) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:voltage_sags, :l1]}, ["00002"]]}
    assert results |> Enum.at(15) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:voltage_sags, :l2]}, ["00001"]]}
    assert results |> Enum.at(16) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:voltage_sags, :l3]}, ["00000"]]}
    assert results |> Enum.at(17) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:voltage_swells, :l1]}, ["00000"]]}
    assert results |> Enum.at(18) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:voltage_swells, :l2]}, ["00003"]]}
    assert results |> Enum.at(19) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:voltage_swells, :l3]}, ["00000"]]}
    assert results |> Enum.at(22) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :voltage, :l1]}, [%P1.Value{value: 220.1, unit: "V"}]]}
    assert results |> Enum.at(23) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :voltage, :l2]}, [%P1.Value{value: 220.2, unit: "V"}]]}
    assert results |> Enum.at(24) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :voltage, :l3]}, [%P1.Value{value: 220.3, unit: "V"}]]}
    assert results |> Enum.at(25) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :amperage, :l1]}, [%P1.Value{value: 1, unit: "A"}]]}
    assert results |> Enum.at(26) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :amperage, :l2]}, [%P1.Value{value: 2, unit: "A"}]]}
    assert results |> Enum.at(27) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :amperage, :l3]}, [%P1.Value{value: 3, unit: "A"}]]}
    assert results |> Enum.at(28) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :l1, :plus_p]}, [%P1.Value{value: 1.111, unit: "kW"}]]}
    assert results |> Enum.at(29) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :l2, :plus_p]}, [%P1.Value{value: 2.222, unit: "kW"}]]}
    assert results |> Enum.at(30) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :l3, :plus_p]}, [%P1.Value{value: 3.333, unit: "kW"}]]}
    assert results |> Enum.at(31) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :l1, :min_p]}, [%P1.Value{value: 4.444, unit: "kW"}]]}
    assert results |> Enum.at(32) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :l2, :min_p]}, [%P1.Value{value: 5.555, unit: "kW"}]]}
    assert results |> Enum.at(33) == {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :l3, :min_p]}, [%P1.Value{value: 6.666, unit: "kW"}]]}
    assert results |> Enum.at(34) == {:ok, [%P1.Channel{channel: 1, medium: :abstract},    %P1.Tags{tags: [:mbus, :device_type]}, ["003"]]}
    assert results |> Enum.at(35) == {:ok, [%P1.Channel{channel: 1, medium: :abstract},    %P1.Tags{tags: [:mbus, :equipment_identifier]}, ["3232323241424344313233343536373839"]]}
    assert results |> Enum.at(36) == {:ok, [%P1.Channel{channel: 1, medium: :abstract},    %P1.Tags{tags: [:mbus, :measurement]},
             ["2010-12-09T11:25:00+01:00", %P1.Value{value: 12_785.123, unit: "m3"}]]}
    assert results |> Enum.at(37) == {:ok, [%P1.Checksum{value: "EF2F"}]}
  end
end
