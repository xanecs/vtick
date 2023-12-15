defmodule Vtick.TickerState do
  use GenServer
  @name __MODULE__

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def init(_arg) do
    Phoenix.PubSub.subscribe(Vtick.PubSub, "ticker")
    {:ok, %{}}
  end

  def get_state() do
    GenServer.call(@name, :get)
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:ticker, payload}, _state) do
    {:noreply, payload}
  end
end
