# Genserver that generates pixels
defmodule PixelGenerator.Generator do
  use GenServer
  alias PixelGenerator.LedConnector
  alias PixelGenerator.Protobuf
  alias PixelGenerator.Protobuf.Config

  @maxval 8
  @led_count 60
  # @tick_interval 2000

  defstruct brightness: 0, index: 0, color_r: 0, config: nil

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    # :timer.send_interval(500, :next_led)
    # :timer.send_interval(100, :next_color)
    :timer.send_interval(1200, :next_brightness)
    # :timer.send_interval(500, :tick)

    all_on()

    {:ok, %__MODULE__{config: Protobuf.new_config()}}
  end

  def handle_info(:next_led, %__MODULE__{} = state) do
    i =
      case state.index do
        c when c >= @led_count -> 0
        c -> c + 1
      end

    data = 0..@led_count |> Enum.map(fn _ -> 0 end) |> List.update_at(i, fn _ -> @maxval end)

    Protobuf.new_frame(@maxval, data)
    |> PixelGenerator.LedConnector.send_protobuf()

    {:noreply, %__MODULE__{state | index: i}}
  end

  def handle_info(:next_brightness, %__MODULE__{} = state) do
    b =
      case state.brightness do
        # c when c >= @maxval -> 0
        c when c >= 3 -> 0
        c -> c + 1
      end

    data = 0..@led_count |> Enum.map(fn _ -> b end)

    Protobuf.new_frame(@maxval, data)
    |> PixelGenerator.LedConnector.send_protobuf()

    {:noreply, %__MODULE__{state | brightness: b}}
  end

  def handle_info(:next_color, %__MODULE__{config: %Config{} = config} = state) do
    new_r =
      case config.on_r do
        r when r >= 255 -> 0
        r -> r + 10
      end

    config = Protobuf.update_config(config, %{on_r: new_r, on_w: 0, on_g: 0})

    PixelGenerator.LedConnector.send_protobuf(config)

    {:noreply, %__MODULE__{state | config: config}}
  end

  def handle_info(:tick, state) do
    # all_on()

    Protobuf.new_config(%{test_frame: false, on_g: 255, on_b: 255})
    |> LedConnector.send_protobuf()

    {:noreply, state}
  end

  def all_on() do
    data = 1..@led_count |> Enum.map(fn _ -> 2 end)
    # data = 1..@led_count |> Enum.map(fn _ -> @maxval end)

    Protobuf.new_frame(@maxval, data)
    |> PixelGenerator.LedConnector.send_protobuf()
  end
end
