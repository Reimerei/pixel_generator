# genserver that send udp packages to the led controller

defmodule PixelGenerator.LedConnector do
  use GenServer
  require Logger

  alias PixelGenerator.Protobuf

  defstruct [:udp]

  @udp_host "blinkenleds.fritz.box" |> to_charlist()
  # @udp_host "192.168.0.165"
  # @udp_host {192, 168, 0, 165}
  @udp_port 1337

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def send_protobuf(protobuf) when is_struct(protobuf) do
    protobuf
    |> Protobuf.encode()
    |> send_binary()
  end

  def send_binary(binary) when is_binary(binary) do
    GenServer.cast(__MODULE__, {:send, binary})
  end

  def init(:ok) do
    Logger.info("Sending UPD packets to #{inspect(@udp_host)}:#{@udp_port}")

    {:ok, udp} = :gen_udp.open(0, [:binary, active: false])

    :ok = :gen_udp.connect(udp, @udp_host, @udp_port)

    {:ok, %__MODULE__{udp: udp}}
  end

  def handle_cast({:send, binary}, %__MODULE__{} = state) do
    Logger.debug("UDP: sending #{inspect(binary)}")
    res = :gen_udp.send(state.udp, binary)
    Logger.debug("UDP: #{inspect(res)}")
    {:noreply, state}
  end
end
