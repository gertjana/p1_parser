defmodule P1.Telegram do
  @moduledoc """
    Contains structs for parsed P1 lines
  """

  defmodule Header do
    @moduledoc """
    Manufacturer and model of the SmartMeter

    ## Example
    ```
    iex> P1.parse!("/ISk5\\2MT382-1000") |> P1.to_struct
    %P1.Telegram.Header{manufacturer: "ISk", model: "\\2MT382-1000"}
    ```
    """
    defstruct manufacturer: "", model: ""
  end

  defmodule Version do
    @moduledoc """
    Version of the P1 Telegram

    ## Example
    ```
    iex> P1.parse!("1-3:0.2.8(50)") |> P1.to_struct
    %P1.Telegram.Version{version: "50"}
    ```
    """
    defstruct version: ""
  end

  defmodule EquipmentIdentifier do
    @moduledoc """
    Unique identifier for this Smartmeter,
    channel 0 is the smartmeter itself, higher numbers are mbus connected devices, for instance water or gas meters

    ## Example
    ```
    iex> P1.parse!("0-0:96.1.1(4B384547303034303436333935353037)") |> P1.to_struct
    %P1.Telegram.EquipmentIdentifier{channel: 0, identifier: "4B384547303034303436333935353037"}
    ```
    """
    defstruct channel: 0, identifier: ""
  end

  defmodule Timestamp do
    @moduledoc """
    timestamp when this telegram was sent

    ## Example
    ```
    iex> P1.parse!("0-0:1.0.0(101209113020W)") |> P1.to_struct
    %P1.Telegram.Timestamp{timestamp: "2010-12-09T11:30:20+02:00"}
    ```
    """
    defstruct timestamp: ""
  end

  defmodule TotalEnergy do
    @moduledoc """
    Total electric energy consumed or produced in normal or low tariff

    ## Example
    ```
    iex> P1.parse!("1-0:1.8.1(123456.789*kWh)") |> P1.to_struct
    %P1.Telegram.TotalEnergy{direction: :consume, tariff: :low, unit: "kWh", value: 123456.789}
    ```
    """
    defstruct direction: nil, tariff: nil, value: 0.0, unit: "kWh"
  end

  defmodule TariffIndicator do
    @moduledoc """
    Indicates which tariff is active (normal or low)

    ## Example
    ```
    iex> P1.parse!("0-0:96.14.0(0002)") |> P1.to_struct
    %P1.Telegram.TariffIndicator{indicator: :normal}
    ```
    """
    defstruct indicator: nil
  end

  defmodule ActivePower do
    @moduledoc """
    How much power is consumed or produced right now

    ## Example
    ```
    iex> P1.parse!("1-0:1.7.0(01.193*kW)") |> P1.to_struct
    %P1.Telegram.ActivePower{direction: :consume, phase: :all, unit: "kW", value: 1.193}

    iex> P1.parse!("1-0:41.7.0(01.111*kW)") |> P1.to_struct
    %P1.Telegram.ActivePower{direction: :consume, phase: :l2, unit: "kW", value: 1.111}
    ```
    """
    defstruct direction: nil, phase: nil, value: 0.0, unit: "kW"
  end

  defmodule PowerFailure do
    @moduledoc """
    Power failures count, split into short and long power failures

    ## Example
    ```
    iex> P1.parse!("0-0:96.7.21(00004)") |> P1.to_struct
    %P1.Telegram.PowerFailure{type: :short, count: 4}
    iex> P1.parse!("0-0:96.7.9(00002)") |> P1.to_struct
    %P1.Telegram.PowerFailure{type: :long, count: 2}
    ```
    """
    defstruct type: nil, count: 0
  end

  defmodule LongFailure do
    @moduledoc false
    defstruct timestamp: "", duration: 0, unit: "s"
  end

  defmodule LongFailureLog do
    @moduledoc """
    list of failures, when the failure ended and how long it lasted

    ## Example
    ```
    iex> P1.parse!("1-0:99.97.0(2)(0-0:96.7.19)(101208152415W)(0000000240*s)(101208151004W)(0000000301*s)") |> P1.to_struct
    %P1.Telegram.LongFailureLog{
    count: 2,
    events: [
      %P1.Telegram.LongFailure{
        duration: 240,
        timestamp: "2010-12-08T15:24:15+02:00",
        unit: "s"
      },
      %P1.Telegram.LongFailure{
        duration: 301,
        timestamp: "2010-12-08T15:10:04+02:00",
        unit: "s"
      }
    ]
    }
    ```
    """
    defstruct count: 0, events: []
  end

  defmodule VoltageSwells do
    @moduledoc """
    Number of voltage swells for a phase

    ## Example
    ```
    iex> P1.parse!("1-0:32.36.0(00003)") |> P1.to_struct
    %P1.Telegram.VoltageSwells{phase: :l1, count: 3}
    ```
    """
    defstruct phase: nil, count: 0
  end

  defmodule VoltageSags do
    @moduledoc """
    Number of voltage sags for a phase

    ## Example
    ```
    iex> P1.parse!("1-0:32.32.0(00002)") |> P1.to_struct
    %P1.Telegram.VoltageSags{phase: :l1, count: 2}
    ```
    """
    defstruct phase: nil, count: 0
  end

  defmodule Voltage do
    @moduledoc """
    Current voltage for specified line

    ## Example
    ```
    iex> P1.parse!("1-0:32.7.0(220.1*V)") |> P1.to_struct
    %P1.Telegram.Voltage{phase: :l1, unit: "V", value: 220.1}
    ```
    """
    defstruct phase: nil, value: 0.0, unit: "V"
  end

  defmodule Amperage do
    @moduledoc """
    Current amperage for specified line

    ## Example
    ```
    iex> P1.parse!("1-0:51.7.0(002*A)") |> P1.to_struct
    %P1.Telegram.Amperage{phase: :l2, unit: "A", value: 2}
    ```
    """
    defstruct phase: nil, value: 0.0, unit: "A"
  end

  defmodule TextMessage do
    @moduledoc """
    A textmessage the smartmeter may send

    ## Example
    ```
    iex> P1.parse!("0:96.13.0(416C6C20796F75722062617365206172652062656C6F6E6720746F207573)") |> P1.to_struct
    %P1.Telegram.TextMessage{text: "All your base are belong to us"}
    ```
    """
    defstruct text: ""
  end

  defmodule MessageCode do
    @moduledoc """
    A 8 digit numeric code

    iex> P1.parse!("0:96.13.1(12345678)") |> P1.to_struct
    %P1.Telegram.MessageCode{code: 12345678}
    """
    defstruct code: 0
  end

  defmodule MbusDeviceType do
    @moduledoc """
    Mbus device type

    ## Example
    ```
    iex> P1.parse!("0-1:24.1.0(0003)") |> P1.to_struct
    %P1.Telegram.MbusDeviceType{channel: 1, type: 3}
    ```
    """
    defstruct channel: 0, type: 0
  end

  defmodule MbusDeviceMeasurement do
    @moduledoc """
    Measurement from mbus device measured at the specified timestamp

    ## Example
    ```
    iex> P1.parse!("0-1:24.2.1(101209112500W)(12785.123*m3)") |> P1.to_struct
    %P1.Telegram.MbusDeviceMeasurement{channel: 1, timestamp: "2010-12-09T11:25:00+02:00", unit: "m3", value: 12785.123}
    ```
    """
    defstruct channel: 0, timestamp: "", value: 0.0, unit: "m3"
  end

  @doc false
  def to_struct([:header, manufacturer, model]), do: %Header{manufacturer: manufacturer, model: model}

  def to_struct([:version, version]), do: %Version{version: version}

  def to_struct([:equipment_identifier, channel, identifier]), do: %EquipmentIdentifier{channel: channel, identifier: identifier}

  def to_struct([:timestamp, timestamp]), do: %Timestamp{timestamp: timestamp}

  def to_struct([:total_energy, :consume, :normal, {value, unit}]), do: %TotalEnergy{direction: :consume, tariff: :normal, value: value, unit: unit}
  def to_struct([:total_energy, :consume, :low, {value, unit}]),    do: %TotalEnergy{direction: :consume, tariff: :low, value: value, unit: unit}
  def to_struct([:total_energy, :produce, :normal, {value, unit}]), do: %TotalEnergy{direction: :produce, tariff: :normal, value: value, unit: unit}
  def to_struct([:total_energy, :produce, :low, {value, unit}]),    do: %TotalEnergy{direction: :produce, tariff: :low, value: value, unit: unit}

  def to_struct([:tariff_indicator, indicator]), do: %TariffIndicator{indicator: indicator}

  def to_struct([:active_power, :consume, {value, unit}]), do: %ActivePower{direction: :consume, phase: :all, value: value, unit: unit}
  def to_struct([:active_power, :produce, {value, unit}]), do: %ActivePower{direction: :produce, phase: :all, value: value, unit: unit}
  def to_struct([:active_power, :l1, :consume, {value, unit}]), do: %ActivePower{direction: :consume, phase: :l1, value: value, unit: unit}
  def to_struct([:active_power, :l1, :produce, {value, unit}]), do: %ActivePower{direction: :produce, phase: :l1, value: value, unit: unit}
  def to_struct([:active_power, :l2, :consume, {value, unit}]), do: %ActivePower{direction: :consume, phase: :l2, value: value, unit: unit}
  def to_struct([:active_power, :l2, :produce, {value, unit}]), do: %ActivePower{direction: :produce, phase: :l2, value: value, unit: unit}
  def to_struct([:active_power, :l3, :consume, {value, unit}]), do: %ActivePower{direction: :consume, phase: :l3, value: value, unit: unit}
  def to_struct([:active_power, :l4, :produce, {value, unit}]), do: %ActivePower{direction: :produce, phase: :l3, value: value, unit: unit}

  def to_struct([:power_failures, count]), do: %PowerFailure{type: :short, count: count}
  def to_struct([:long_power_failures, count]), do: %PowerFailure{type: :long, count: count}

  def to_struct([:long_failures_log, count, events]) do
    %LongFailureLog{count: count, events: Enum.map(events,
      fn ev -> %LongFailure{timestamp: Enum.at(ev, 0), duration: elem(Enum.at(ev, 1), 0), unit: elem(Enum.at(ev, 1), 1)} end)}
  end

  def to_struct([:voltage_swells, :l1, count]), do: %VoltageSwells{phase: :l1, count: count}
  def to_struct([:voltage_swells, :l2, count]), do: %VoltageSwells{phase: :l2, count: count}
  def to_struct([:voltage_swells, :l3, count]), do: %VoltageSwells{phase: :l3, count: count}

  def to_struct([:voltage_sags, :l1, count]), do: %VoltageSags{phase: :l1, count: count}
  def to_struct([:voltage_sags, :l2, count]), do: %VoltageSags{phase: :l2, count: count}
  def to_struct([:voltage_sags, :l3, count]), do: %VoltageSags{phase: :l3, count: count}

  def to_struct([:voltage, :l1, {value, unit}]), do: %Voltage{phase: :l1, value: value, unit: unit}
  def to_struct([:voltage, :l2, {value, unit}]), do: %Voltage{phase: :l2, value: value, unit: unit}
  def to_struct([:voltage, :l3, {value, unit}]), do: %Voltage{phase: :l3, value: value, unit: unit}

  def to_struct([:amperage, :l1, {value, unit}]), do: %Amperage{phase: :l1, value: value, unit: unit}
  def to_struct([:amperage, :l2, {value, unit}]), do: %Amperage{phase: :l2, value: value, unit: unit}
  def to_struct([:amperage, :l3, {value, unit}]), do: %Amperage{phase: :l3, value: value, unit: unit}

  def to_struct([:text_message, text]), do: %TextMessage{text: text}

  def to_struct([:message_code, code]), do: %MessageCode{code: code}

  def to_struct([:mbus_device_type, channel, type]), do: %MbusDeviceType{channel: channel, type: type}

  def to_struct([:mbus_equipment_identifier, channel, identifier]), do: %EquipmentIdentifier{channel: channel, identifier: identifier}

  def to_struct([:mbus_device_measurement, channel, timestamp, {value, unit}]), do: %MbusDeviceMeasurement{channel: channel, timestamp: timestamp, value: value, unit: unit}
end
