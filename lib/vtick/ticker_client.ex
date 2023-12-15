defmodule Vtick.TickerClient do
  use WebSockex

  def start_link(_opts) do
    url = Application.get_env(:vtick, __MODULE__)[:url]
    WebSockex.start_link(url, __MODULE__, {})
  end

  def handle_frame({:text, payload}, state) do
    data = Jason.decode!(payload)

    IO.puts("received #{data["type"]}")
    {result, new_state} = handle_msg(data, state)
    Phoenix.PubSub.broadcast_from(Vtick.PubSub, self(), "ticker", {:ticker, new_state})
    {result, new_state}
  end

  def handle_frame(:ping, state) do
    IO.puts("received ping")
    {:reply, :pong, state}
  end

  def handle_frame(:pong, state) do
    IO.puts("received pong")
    {:ok, state}
  end

  def handle_frame(frame, state) do
    IO.puts("unhandled frame: #{inspect(frame)}")
    {:ok, state}
  end

  def handle_info(:ping, state) do
    Process.send_after(self(), :ping, 30_000)
    {:reply, :ping, state}
  end

  def handle_msg(%{"type" => "FETCH_ASSOCIATION_TICKER_RESPONSE", "payload" => payload}, _state) do
    IO.puts("ticker updated")
    {:ok, payload}
  end

  def handle_msg(%{"type" => "MATCH_UPDATE", "payload" => payload}, state) do
    match_id = payload["matchUuid"]
    new_state = put_in(state, ["matchStates", match_id], payload)
    {:ok, new_state}
  end

  def handle_msg(msg, state) do
    IO.puts("unhandled msg: #{msg["type"]}")
    {:ok, state}
  end

  def handle_connect(_conn, state) do
    IO.puts("ticker connected")
    Process.send_after(self(), :ping, 30_000)
    {:ok, state}
  end

  def handle_disconnect(connection_status_map, state) do
    IO.puts("ticker disconnected")
    IO.inspect(connection_status_map)
    {:reconnect, state}
  end

  def terminate(close_reason, _state) do
    IO.puts("ticker terminating with reason: #{inspect(close_reason)}")
  end
end
