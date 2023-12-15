defmodule Vtick.MatchSelector do
  use GenServer
  @name __MODULE__
  @topic "match_selector"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def set_match_uuid(uuid), do: GenServer.call(@name, {:set, uuid})

  def get_match_uuid() do
    GenServer.call(@name, :get)
  end

  def init(_opts) do
    {:ok, nil}
  end

  def handle_call({:set, uuid}, _from, _state) do
    state = uuid
    Phoenix.PubSub.broadcast_from(Vtick.PubSub, self(), @topic, {:match_uuid, state})
    {:reply, :ok, state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
