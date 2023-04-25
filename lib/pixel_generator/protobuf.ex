defmodule PixelGenerator.Protobuf do
  alias PixelGenerator.Protobuf.{Frame, Packet, Config, ResponsePacket, RemoteLog}

  @default_config %{
    on_r: 150,
    on_g: 50,
    on_b: 0,
    on_w: 255,
    off_r: 0,
    off_g: 0,
    off_b: 0,
    off_w: 0,
    easing_interval_ms: 1000,
    pixel_easing: :EASE_IN_OUT_QUAD,
    brighness_easing: :EASE_IN_QUAD
  }

  def new_frame(maxval, data) when is_list(data) do
    data_binary = IO.iodata_to_binary(data)
    Frame.new!(maxval: maxval, data: data_binary)
  end

  def new_config(attrs \\ %{}) do
    Map.merge(@default_config, attrs)
    |> Config.new!()
  end

  def update_config(%Config{} = config, attrs) do
    Map.merge(config, attrs)
    |> Config.new!()
  end

  def encode(%Frame{} = frame) do
    Packet.new!(content: {:frame, frame})
    |> Packet.encode()
  end

  def encode(%Config{} = config) do
    Packet.new!(content: {:config, config})
    |> Packet.encode()
  end

  def decode_response(protobuf) when is_binary(protobuf) do
    ResponsePacket.decode(protobuf)
  end
end
