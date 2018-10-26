defmodule P1ParserTest do
  use ExUnit.Case

  doctest P1
  doctest P1.Telegram.Header
  doctest P1.Telegram.Version
  doctest P1.Telegram.EquipmentIdentifier
  doctest P1.Telegram.TotalEnergy
  doctest P1.Telegram.TariffIndicator
  doctest P1.Telegram.ActivePower
  doctest P1.Telegram.PowerFailure
  doctest P1.Telegram.LongFailureLog
  doctest P1.Telegram.VoltageSwells
  doctest P1.Telegram.VoltageSags
  doctest P1.Telegram.Voltage
  doctest P1.Telegram.Amperage
  doctest P1.Telegram.TextMessage
  doctest P1.Telegram.MessageCode
  doctest P1.Telegram.MbusDeviceType
  doctest P1.Telegram.MbusDeviceMeasurement
  doctest P1.Telegram.Checksum

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

    assert results |> Enum.at(0)  == {:ok, [:header, "ISk", "\\2MT382-1000"]}
    assert results |> Enum.at(1)  == {:ok, [:version, "50"]}
    assert results |> Enum.at(2)  == {:ok, [:timestamp, "2010-12-09T11:30:20+02:00"]}
    assert results |> Enum.at(3)  == {:ok, [:equipment_identifier, 0, "4B384547303034303436333935353037"]}
    assert results |> Enum.at(4)  == {:ok, [:total_energy, :consume, :low, {123_456.789, "kWh"}]}
    assert results |> Enum.at(5)  == {:ok, [:total_energy, :consume, :normal, {123_456.789, "kWh"}]}
    assert results |> Enum.at(6)  == {:ok, [:total_energy, :produce, :low, {123_456.789, "kWh"}]}
    assert results |> Enum.at(7)  == {:ok, [:total_energy, :produce, :normal, {123_456.789, "kWh"}]}
    assert results |> Enum.at(8)  == {:ok, [:tariff_indicator, :normal]}
    assert results |> Enum.at(9)  == {:ok, [:active_power, :consume, {1.193, "kW"}]}
    assert results |> Enum.at(10) == {:ok, [:active_power, :produce, {0.0, "kW"}]}
    assert results |> Enum.at(11) == {:ok, [:power_failures, 4]}
    assert results |> Enum.at(12) == {:ok, [:long_power_failures, 2]}
    assert results |> Enum.at(13) == {:ok, [:long_failures_log, 2, [["2010-12-08T15:24:15+02:00", {240, "s"}], ["2010-12-08T15:10:04+02:00", {301, "s"}]]]}
    assert results |> Enum.at(14) == {:ok, [:voltage_sags, :l1, 2]}
    assert results |> Enum.at(15) == {:ok, [:voltage_sags, :l2, 1]}
    assert results |> Enum.at(16) == {:ok, [:voltage_sags, :l3, 0]}
    assert results |> Enum.at(17) == {:ok, [:voltage_swells, :l1, 0]}
    assert results |> Enum.at(18) == {:ok, [:voltage_swells, :l2, 3]}
    assert results |> Enum.at(19) == {:ok, [:voltage_swells, :l3, 0]}
    assert results |> Enum.at(22) == {:ok, [:voltage, :l1, {220.1, "V"}]}
    assert results |> Enum.at(23) == {:ok, [:voltage, :l2, {220.2, "V"}]}
    assert results |> Enum.at(24) == {:ok, [:voltage, :l3, {220.3, "V"}]}
    assert results |> Enum.at(25) == {:ok, [:amperage, :l1, {1, "A"}]}
    assert results |> Enum.at(26) == {:ok, [:amperage, :l2, {2, "A"}]}
    assert results |> Enum.at(27) == {:ok, [:amperage, :l3, {3, "A"}]}
    assert results |> Enum.at(28) == {:ok, [:active_power, :l1, :consume, {1.111, "kW"}]}
    assert results |> Enum.at(29) == {:ok, [:active_power, :l2, :consume, {2.222, "kW"}]}
    assert results |> Enum.at(30) == {:ok, [:active_power, :l3, :consume, {3.333, "kW"}]}
    assert results |> Enum.at(31) == {:ok, [:active_power, :l1, :produce, {4.444, "kW"}]}
    assert results |> Enum.at(32) == {:ok, [:active_power, :l2, :produce, {5.555, "kW"}]}
    assert results |> Enum.at(33) == {:ok, [:active_power, :l3, :produce, {6.666, "kW"}]}
    assert results |> Enum.at(34) == {:ok, [:mbus_device_type, 1, 3]}
    assert results |> Enum.at(35) == {:ok, [:mbus_equipment_identifier, 1, "3232323241424344313233343536373839"]}
    assert results |> Enum.at(36) == {:ok, [:mbus_device_measurement, 1, "2010-12-09T11:25:00+02:00", {12_785.123, "m3"}]}
  end
end
