defmodule P1 do
  alias P1.Parser, as: Parser
  @moduledoc """
    P1 is a communication standard for Dutch Smartmeters

    Whenever a serial connection is made with the P1 port, the Smartmeter is sending out a telegram every 10 seconds.

    This library is able to parse this telegram and produces elixir types and structs to reason about and further process this data.

    ## Example telegram
    ```
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
    ```
  """

  defmodule Channel do
    @moduledoc """
      Contains the medium and channel of the data

      The medium cam be `:abstract`, `:electricity`, `:heat`, `:gas`, `:water`, the channel always 0 for the meter itself and higher numbers for modbus connected devices

      to transform the medium from an integer to the atom, one can use the construct method on the struct

      ```
      iex> P1.Channel.construct(1,0)
      %P1.Channel{channel: 0, medium: :electricity}
      ```
    """
    defstruct medium: nil, channel: 0

    def construct(medium, channel) do
      m = case medium do
            0 -> :abstract
            1 -> :electricity
            6 -> :heat
            7 -> :gas
            8 -> :water
          end
      %Channel{medium: m, channel: channel}
    end
  end

  defmodule Value do
    @moduledoc """
      A Value with an Unit

      ```
      iex> P1.parse!("1-0:32.7.0(220.1*V)")
        [
        %P1.Channel{channel: 0, medium: :electricity},
        %P1.Tags{tags: [:active, :voltage, :l1]},
        [%P1.Value{unit: "V", value: 220.1}]
        ]
      ```
    """
    defstruct value: 0, unit: ""
  end

  defmodule Tags do
    @moduledoc """
      Contains a list of tags, describing the measurement
    """
    defstruct tags: []
  end

    defmodule ObisCode do
      @moduledoc """

      Struct that represents a data (OBIS) line in the telegram

      OBiS Codes have the following structure `A-B:C.D.E and one our more values in parentheses (v1) where

      Code|Description
      ---|---
      A | specifies the medium 0=abstract, 1=electricity, 6=heat, 7=gas, 8=water
      B | specifies the channel, 0 is the meter itself, higher numbers are modbus connected devices
      C | specifies the physical value (current, voltage, energy, level, temperature, ...)
      D |	specifies the quantity computation result of specific algorythm
      E | specifies the measurement type defined by groups A to D into individual measurements (e.g. switching ranges)​

      The values consists of parentheses around for instance timestamps, integers, hexadecimal encoded texts and measurements with units (where a * separates value and unit)
      ```
      iex> P1.parse!("1-0:2.7.0(01.869*kW)") |> P1.ObisCode.construct
      %P1.ObisCode{
      channel: %P1.Channel{channel: 0, medium: :electricity},
      tags: %P1.Tags{tags: [:active, :power, :produce]},
      values: [%P1.Value{unit: "kW", value: 1.869}]
      }
      ```
      """
      defstruct channel: %Channel{}, tags: %Tags{}, values: []

      def construct([channel, tags, values]), do: %ObisCode{channel: channel, tags: tags, values: values}
    end

  defmodule Header do
    @moduledoc """
      contains the header of the telegram

      ```
      iex(1)> P1.parse("/ISk5MT382-1000")
      {:ok, [%P1.Header{manufacturer: "ISk", model: "MT382-1000"}]}
      ```
    """
    defstruct manufacturer: "", model: ""
  end

  defmodule Checksum do
    @moduledoc """
    contains the CRC16 Checksum

    It is a CRC16 value calculated over the preceding characters in the data message (from
    “/” to “!” using the polynomial: x16+x15+x2+1). CRC16 uses no XOR in, no XOR out and is
    computed with least significant bit first. The value is represented as 4 hexadecimal
    characters (MSB first)

    ```
    iex> P1.parse("!B0B0")
    {:ok, [%P1.Checksum{value: "B0B0"}]}
    ```
    """
    defstruct value: 0x00
  end

  @doc false
  @spec checksum(String.t()) :: String.t()
  defdelegate checksum(bytes), to: Parser, as: :calculate_checksum

  @doc false
  @spec parse_telegram(String.t()) :: {:ok, list} | {:error, String.t()}
  defdelegate parse_telegram(telegram), to: Parser, as: :parse_telegram

  @doc false
  @spec parse_telegram!(String.t()) :: list
  defdelegate parse_telegram!(telegram), to: Parser, as: :parse_telegram!

  @doc """
  Parses a line of text according to the P1 protocol

  ## Example

      iex> P1.parse("1-0:1.7.0(01.193*kW)")
      {:ok, [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:active, :power, :consume]}, [%P1.Value{value: 1.193, unit: "kW"}]]}

  """
  @spec parse(String.t()) :: {:ok, list} | {:error, String.t()}
  defdelegate parse(line), to: Parser, as: :parse

  @doc """
  Parses a line of text according to the P1 protocol

  ## Example

      iex> P1.parse!("1-0:1.8.1(123456.789*kWh)")
      [%P1.Channel{channel: 0, medium: :electricity}, %P1.Tags{tags: [:total, :energy, :consume, :low]}, [%P1.Value{value: 123_456.789, unit: "kWh"}]]

  """
  @spec parse!(String.t()) :: list
  defdelegate parse!(line), to: Parser, as: :parse!

end
