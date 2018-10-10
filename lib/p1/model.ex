defmodule P1.Model do
  @moduledoc """
    Contains structs for parsed P1 lines
  """

  defmodule Header do
    @moduledoc """
    Manufacturer and model of the SmartMeter

    ## Example
    ```
    iex> P1.parse!("/ISk5MT382-1000") |> P1.to_struct
    %P1.Model.Header{manufacturer: "ISk", model: "MT382-1000"}
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
    %P1.Model.Version{version: "50"}
    ```
    """
    defstruct version: ""
  end

  defmodule EquipmentIdentifier do
    @moduledoc """
    Unique identifier for this Smartmeter

    ## Example
    ```
    iex> P1.parse!("0-0:96.1.1(4B384547303034303436333935353037)") |> P1.to_struct
    %P1.Model.EquipmentIdentifier{identifier: "4B384547303034303436333935353037"}
    ```
    """
    defstruct identifier: ""
  end

  defmodule Timestamp do
    @moduledoc """
    timestamp when this telegram was sent

    ## Example
    ```
    iex> P1.parse!("0-0:1.0.0(101209113020W)") |> P1.to_struct
    %P1.Model.Timestamp{timestamp: "2010-12-09 11:30:20 Wintertime"}
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
    %P1.Model.TotalEnergy{direction: :consume, tariff: :low, unit: "kWh", value: 123456.789}
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
    %P1.Model.TariffIndicator{indicator: :normal}
    ```
    """
    defstruct indicator: nil
  end

  defmodule CurrentEnergy do

    @moduledoc """
    How much energy is consumed or produced right now

    ## Example
    ```
    iex> P1.parse!("1-0:1.7.0(01.193*kW)") |> P1.to_struct
    %P1.Model.CurrentEnergy{direction: :consume, unit: "kW", value: 1.193}
    ```
    """
    defstruct direction: nil, value: 0.0, unit: "kW"
  end

  defmodule Voltage do
    @moduledoc """
    Current voltage for specified line

    ## Example
    ```
    iex> P1.parse!("1-0:32.7.0(220.1*V)") |> P1.to_struct
    %P1.Model.Voltage{phase: :l1, unit: "V", value: 220.1}
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
    %P1.Model.Amperage{phase: :l2, unit: "A", value: 2}
    ```
    """
    defstruct phase: nil, value: 0.0, unit: "A"
  end

  defmodule Gas do
    @moduledoc """
    Gas volume consumed at the specified timestamp

    ## Example
    ```
    iex> P1.parse!("0-1:24.2.1(101209112500W)(12785.123*m3)") |> P1.to_struct
    %P1.Model.Gas{timestamp: "2010-12-09 11:25:00 Wintertime", unit: "m3", value: 12785.123}
    ```
    """
    defstruct timestamp: "", value: 0.0, unit: "m3"
  end

  def to_struct([:header, manufacturer, model]), do: %Header{manufacturer: manufacturer, model: model}

  def to_struct([:version, version]), do: %Version{version: version}

  def to_struct([:equipment_identifier, identifier]), do: %EquipmentIdentifier{identifier: identifier}

  def to_struct([:timestamp, timestamp]), do: %Timestamp{timestamp: timestamp}

  def to_struct([:total_energy, :consume, :normal, value, unit]), do: %TotalEnergy{direction: :consume, tariff: :normal, value: value, unit: unit}
  def to_struct([:total_energy, :consume, :low, value, unit]),    do: %TotalEnergy{direction: :consume, tariff: :low, value: value, unit: unit}
  def to_struct([:total_energy, :produce, :normal, value, unit]), do: %TotalEnergy{direction: :produce, tariff: :normal, value: value, unit: unit}
  def to_struct([:total_energy, :produce, :low, value, unit]),    do: %TotalEnergy{direction: :produce, tariff: :low, value: value, unit: unit}

  def to_struct([:tariff_indicator, indicator]), do: %TariffIndicator{indicator: indicator}

  def to_struct([:current_energy, :consume, value, unit]), do: %CurrentEnergy{direction: :consume, value: value, unit: unit}
  def to_struct([:current_energy, :produce, value, unit]), do: %CurrentEnergy{direction: :produce, value: value, unit: unit}

  def to_struct([:voltage, :l1, value, unit]), do: %Voltage{phase: :l1, value: value, unit: unit}
  def to_struct([:voltage, :l2, value, unit]), do: %Voltage{phase: :l2, value: value, unit: unit}
  def to_struct([:voltage, :l3, value, unit]), do: %Voltage{phase: :l3, value: value, unit: unit}

  def to_struct([:amperage, :l1, value, unit]), do: %Amperage{phase: :l1, value: value, unit: unit}
  def to_struct([:amperage, :l2, value, unit]), do: %Amperage{phase: :l2, value: value, unit: unit}
  def to_struct([:amperage, :l3, value, unit]), do: %Amperage{phase: :l3, value: value, unit: unit}

  def to_struct([:gas, timestamp, value, unit]), do: %Gas{timestamp: timestamp, value: value, unit: unit}
end
