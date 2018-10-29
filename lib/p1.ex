defmodule P1 do
  alias P1.Parser, as: Parser
  alias P1.Telegram, as: Telegram
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

  @doc """
  Parses a line of text according to the P1 protocol

  ## Example

      iex> P1.parse("1-0:1.7.0(01.193*kW)")
      {:ok, [:active_power, :consume, {1.193, "kW"}]}

  """
  @spec parse(String.t()) :: {:ok, list} | {:error, String.t()}
  defdelegate parse(line), to: Parser, as: :parse

  @doc """
  Parses a line of text according to the P1 protocol

  ## Example

      iex> P1.parse!("1-0:1.8.1(123456.789*kWh)")
      [:total_energy, :consume, :low, {123_456.789, "kWh"}]

  """
  @spec parse!(String.t()) :: list
  defdelegate parse!(line), to: Parser, as: :parse!

  @doc """
  Converts parsed line to a struct

  ## Example

        iex>P1.to_struct([:version, "50"])
        {:ok, %P1.Telegram.Version{version: "50"}}

  """
  @spec to_struct(list) :: {:ok, struct} | {:error, String.t()}
  defdelegate to_struct(obj), to: Telegram, as: :to_struct

  @doc """
  Converts parsed line to a struct

  ## Example

        iex>P1.to_struct!([:version, "50"])
        %P1.Telegram.Version{version: "50"}

  """
  @spec to_struct!(list) :: struct
  defdelegate to_struct!(obj), to: Telegram, as: :to_struct!

end
