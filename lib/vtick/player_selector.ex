defmodule Vtick.PlayerSelector do
  use GenServer
  @name __MODULE__
  @topic "player_selector"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def set_player_uuid(uuid), do: GenServer.call(@name, {:set, uuid})

  def clear_player_uuid, do: GenServer.call(@name, :clear)

  def set_gender(position, gender) do
    GenServer.call(@name, {:set_gender, position, gender})
  end

  def get() do
    GenServer.call(@name, :get)
  end

  def init(_opts) do
    {:ok, {nil, %{}}}
  end

  def handle_call({:set_gender, position, gender}, _from, state) do
    gender = Map.put(state |> elem(1), position, gender)
    state = :erlang.setelement(2, state, gender)
    Phoenix.PubSub.broadcast_from(Vtick.PubSub, self(), @topic, {:player_selector, state})
    {:reply, :ok, state}
  end

  def handle_call({:set, uuid}, _from, state) do
    state = :erlang.setelement(1, state, uuid)
    Phoenix.PubSub.broadcast_from(Vtick.PubSub, self(), @topic, {:player_selector, state})
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    state = :erlang.setelement(1, state, nil)
    Phoenix.PubSub.broadcast_from(Vtick.PubSub, self(), @topic, {:player_selector, state})
    {:reply, :ok, state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
