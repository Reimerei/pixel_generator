# genserver that send udp packages to the led controller

defmodule PixelGenerator.LedConnector do
  use GenServer
  require Logger

  alias PixelGenerator.Protobuf
  alias PixelGenerator.Protobuf.{RemoteLog, ClientInfo, ResponsePacket}

  defstruct [:udp, :file]

  # @udp_remote_host "blinkenleds.fritz.box" |> to_charlist()
  @udp_remote_host {192, 168, 0, 255}
  @udp_remote_port 1337
  @udp_local_port 4422

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
    Logger.info(
      "Sending UPD packets to #{inspect(@udp_remote_host)}:#{@udp_remote_port}. Listening on #{@udp_local_port}"
    )

    {:ok, file} = File.open("remote.log", [:append])

    {:ok, udp} = :gen_udp.open(@udp_local_port, [:binary, active: true, broadcast: true])
    :ok = :gen_udp.connect(udp, @udp_remote_host, @udp_remote_port)

    {:ok, %__MODULE__{udp: udp, file: file}}
  end

  def handle_info({:udp, _socket, ip, _port, protobuf}, state = %__MODULE__{}) do
    case Protobuf.decode_response(protobuf) do
      %ResponsePacket{content: {:remote_log, %RemoteLog{message: message}}} ->
        IO.binwrite(state.file, "#{message}\n")
        Logger.info("Remote log #{print_ip(ip)}: #{inspect(message)}")

      %ResponsePacket{content: {:client_info, %ClientInfo{} = client_info}} ->
        Logger.info("Client info #{print_ip(ip)}: #{inspect(client_info)}")

      other ->
        Logger.warn("Receive unknown response #{inspect(other)}")
    end

    {:noreply, state}
  end

  def handle_cast({:send, binary}, %__MODULE__{} = state) do
    Logger.debug("UDP: sending #{inspect(binary)}")
    res = :gen_udp.send(state.udp, binary)
    Logger.debug("UDP: #{inspect(res)}")
    {:noreply, state}
  end

  def print_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
end
