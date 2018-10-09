defmodule P1.Model do
  @moduledoc """
    Contains structs for parsed P1 lines
  """
  # credo:disable-for-this-file Credo.Check.Readability.ModuleDoc

  defmodule Header, do: defstruct manufacturer: "", model: ""

  defmodule Version, do: defstruct version: ""

  defmodule EquipmentIdentifier, do: defstruct identifier: ""

  defmodule TotalEnergy, do: defstruct direction: nil, tariff: nil, value: 0.0, unit: "kWh"

  defmodule TariffIndicator, do: defstruct indicator: ""

  defmodule CurrentEnergy, do: defstruct direction: nil, value: 0.0, unit: "kW"

  defmodule Voltage, do: defstruct phase: nil, value: 0.0, unit: "V"

  defmodule Amperage, do: defstruct phase: nil, value: 0.0, unit: "A"

  defmodule Gas, do: defstruct timestamp: "", value: 0.0, unit: "m3"

  @doc """
    Converts a parsed line into a struct

        iex> P1.Parser.parse!("1-0:32.7.0(220.1*V)") |> P1.Model.to_struct
        %P1.Model.Voltage{phase: :l1, unit: "V", value: 220.1} 
  """
  def to_struct([:header, manufacturer, model]), do: %Header{manufacturer: manufacturer, model: model}

  def to_struct([:version, version]), do: %Version{version: version}

  def to_struct([:equipment_identifier, identifier]), do: %EquipmentIdentifier{identifier: identifier}

  def to_struct([:total_energy, :consume, :normal, value, unit]), do: %TotalEnergy{direction: :consume, tariff: :normal, value: value, unit: unit}
  def to_struct([:total_energy, :consume, :low, value, unit]), do: %TotalEnergy{direction: :consume, tariff: :low, value: value, unit: unit}
  def to_struct([:total_energy, :produce, :normal, value, unit]), do: %TotalEnergy{direction: :produce, tariff: :normal, value: value, unit: unit}
  def to_struct([:total_energy, :produce, :low, value, unit]), do: %TotalEnergy{direction: :produce, tariff: :low, value: value, unit: unit}

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
