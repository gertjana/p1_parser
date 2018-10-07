defmodule P1ParserTest do
  use ExUnit.Case
  doctest P1Parser

  test "send lines" do
    lines = """
      /ISk5MT382-1000
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
      0:96.13.0(303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C
      3D3E3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F)
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

    results = lines |> Enum.map(fn line -> P1Parser.parse(line) end)

    assert results |> Enum.at(0) == {:ok, [:header, "ISk", "MT382-1000"]}
    assert results |> Enum.at(1) == {:ok, [:version, "(50)"]}
    assert results |> Enum.at(2) == {:ok, [:timestamp, "2010-12-09 11:30:20"]}
    assert results |> Enum.at(4) == {:ok, [:total_energy, :consume, :low, 123_456.789]}
    assert results |> Enum.at(5) == {:ok, [:total_energy, :consume, :normal, 123_456.789]}
    assert results |> Enum.at(6) == {:ok, [:total_energy, :produce, :low, 123_456.789]}
    assert results |> Enum.at(7) == {:ok, [:total_energy, :produce, :normal, 123_456.789]}
    assert results |> Enum.at(9) == {:ok, [:current_energy, :consume, 1.193]}
    assert results |> Enum.at(10) == {:ok, [:current_energy, :produce, 0.0]}
    assert results |> Enum.at(23) == {:ok, [:voltage, :l1, 220.1]}
    assert results |> Enum.at(24) == {:ok, [:voltage, :l2, 220.2]}
    assert results |> Enum.at(25) == {:ok, [:voltage, :l3, 220.3]}
    assert results |> Enum.at(26) == {:ok, [:amperage, :l1, 1]}
    assert results |> Enum.at(27) == {:ok, [:amperage, :l2, 2]}
    assert results |> Enum.at(28) == {:ok, [:amperage, :l3, 3]}
    assert results |> Enum.at(37) == {:ok, [:gas, "2010-12-09 11:25:00", 12_785.123]}
  end
end