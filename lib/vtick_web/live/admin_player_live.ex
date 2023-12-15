defmodule VtickWeb.AdminPlayerLive do
  alias Vtick.PlayerSelector
  alias Vtick.Ticker
  alias Vtick.MatchSelector
  alias Vtick.TickerState
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    VtickWeb.Endpoint.subscribe("ticker")
    VtickWeb.Endpoint.subscribe("match_selector")
    VtickWeb.Endpoint.subscribe("player_selector")

    {player_uuid, genders} = PlayerSelector.get()

    socket =
      socket
      |> assign(:ticker, TickerState.get_state())
      |> assign(:match_uuid, MatchSelector.get_match_uuid())
      |> assign(:page_title, "Players")
      |> assign(:team_filter, nil)
      |> assign(:active_page, :players)
      |> assign(:player_uuid, player_uuid)
      |> assign(:genders, genders)

    {:ok, socket}
  end

  def render(assigns) do
    match =
      assigns.ticker
      |> Ticker.match(assigns.match_uuid)

    teams =
      assigns.ticker
      |> Ticker.teams_map()

    state =
      assigns.ticker
      |> Ticker.state(assigns.match_uuid)

    squads =
      assigns.ticker
      |> Ticker.squads(assigns.match_uuid)

    mvps =
      assigns.ticker
      |> Ticker.mvps(assigns.match_uuid)

    arbitration =
      assigns.ticker |> Ticker.arbitration(assigns.match_uuid)

    assigns =
      assigns
      |> assign(:state, state)
      |> assign(:match, match)
      |> assign(:teams, teams)
      |> assign(:mvps, mvps)
      |> assign(:squads, squads)
      |> assign(:arbitration, arbitration)

    ~H"""
    <%= if @match != nil do %>
      <h2 class="mb-8 text-bold text-xl">Officials</h2>
      <div class="grid grid-cols-2 gap-8 mb-8">
        <%= if @arbitration != nil do %>
          <div>
            <div
              class={"card bg-white hover:bg-gray-100 shadow mb-2 flex items-center  cursor-pointer outline-indigo-700 #{if @player_uuid == "firstReferee", do: "outline"}"}
              phx-click={if @player_uuid == "firstReferee", do: "clear_player", else: "set_player"}
              phx-value-uuid="firstReferee"
            >
              <div class="bg-gray-600 text-white p-3 w-12 mr-4 text-center">1.</div>
              <div class="py-2">
                <%= @arbitration["firstReferee"]["firstName"] %> <%= @arbitration["firstReferee"][
                  "lastName"
                ] %>
              </div>
            </div>
            <div class="flex">
              <button
                phx-value-gender="F"
                phx-value-position="firstReferee"
                phx-click="set_gender"
                class={"flex-grow p-2 #{if @genders["firstReferee"] == "F", do: "bg-pink-500 text-white", else: "bg-white"} text-bold rounded-l border"}
              >
                F
              </button>
              <button
                phx-value-gender="M"
                phx-value-position="firstReferee"
                phx-click="set_gender"
                class={"flex-grow p-2 #{if @genders["firstReferee"] == "M", do: "bg-blue-500 text-white", else: "bg-white"} text-bold rounded-r border"}
              >
                M
              </button>
            </div>
          </div>
          <div>
            <div
              class={"card bg-white hover:bg-gray-100 shadow mb-2 flex items-center  cursor-pointer outline-indigo-700 #{if @player_uuid == "secondReferee", do: "outline"}"}
              phx-click={if @player_uuid == "secondReferee", do: "clear_player", else: "set_player"}
              phx-value-uuid="secondReferee"
            >
              <div class="bg-gray-600 text-white p-3 w-12 mr-4 text-center">2.</div>
              <div class="py-2">
                <%= @arbitration["secondReferee"]["firstName"] %> <%= @arbitration["secondReferee"][
                  "lastName"
                ] %>
              </div>
            </div>
            <div class="flex">
              <button
                phx-value-gender="F"
                phx-value-position="secondReferee"
                phx-click="set_gender"
                class={"flex-grow p-2 #{if @genders["secondReferee"] == "F", do: "bg-pink-500 text-white", else: "bg-white"} text-bold rounded-l border"}
              >
                F
              </button>
              <button
                phx-value-gender="M"
                phx-value-position="secondReferee"
                phx-click="set_gender"
                class={"flex-grow p-2 #{if @genders["secondReferee"] == "M", do: "bg-blue-500 text-white", else: "bg-white"} text-bold rounded-r border"}
              >
                M
              </button>
            </div>
          </div>
        <% end %>
      </div>
      <div class="grid grid-cols-2 gap-8">
        <%= for side <- ["team1", "team2"] do %>
          <div>
            <div class="mb-8 text-bold text-xl">
              <%= @teams[@match[side]]["name"] %>
            </div>
            <%= for player <- @squads[side] do %>
              <div
                class={"card #{if Enum.member?(@mvps, player["uuid"]), do: "bg-amber-500 hover:bg-amber-600", else: "bg-white hover:bg-gray-100"} shadow mb-2 flex items-center  cursor-pointer outline-indigo-700 #{if player["uuid"] == @player_uuid, do: "outline"}"}
                phx-click={if player["uuid"] == @player_uuid, do: "clear_player", else: "set_player"}
                phx-value-uuid={player["uuid"]}
              >
                <div class="bg-gray-600 text-white p-3 w-12 mr-4 text-center">
                  <%= player["jerseyNumber"] %>
                </div>
                <div class="py-2">
                  <%= player["firstName"] %> <%= player["lastName"] %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  def handle_event("set_player", %{"uuid" => uuid}, socket) do
    PlayerSelector.set_player_uuid(uuid)
    {:noreply, socket}
  end

  def handle_event("set_gender", %{"position" => position, "gender" => gender}, socket) do
    PlayerSelector.set_gender(position, gender)
    {:noreply, socket}
  end

  def handle_event("clear_player", _params, socket) do
    PlayerSelector.clear_player_uuid()
    {:noreply, socket}
  end

  def handle_info({:ticker, ticker}, socket) do
    {:noreply, assign(socket, :ticker, ticker)}
  end

  def handle_info({:match_uuid, match_uuid}, socket) do
    {:noreply, assign(socket, :match_uuid, match_uuid)}
  end

  def handle_info({:player_selector, {player_uuid, genders}}, socket) do
    {:noreply, socket |> assign(:genders, genders) |> assign(:player_uuid, player_uuid)}
  end
end
