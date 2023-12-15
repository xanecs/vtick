defmodule VtickWeb.LowerThirdLive do
  use VtickWeb, :live_view
  alias Vtick.TickerState
  alias Vtick.Ticker
  alias Vtick.MatchSelector
  alias Vtick.PlayerSelector

  def mount(_params, _session, socket) do
    VtickWeb.Endpoint.subscribe("ticker")
    VtickWeb.Endpoint.subscribe("match_selector")
    VtickWeb.Endpoint.subscribe("player_selector")
    {player_uuid, genders} = PlayerSelector.get()

    socket =
      socket
      |> assign(:ticker, TickerState.get_state())
      |> assign(:match_uuid, MatchSelector.get_match_uuid())
      |> assign(:player_uuid, player_uuid)
      |> assign(:genders, genders)
      |> assign(:removed, false)

    {:ok, socket}
  end

  def render(assigns) do
    match =
      assigns.ticker
      |> Ticker.match(assigns.match_uuid)

    series =
      assigns.ticker
      |> Ticker.series(match["matchSeries"])

    position_names = %{
      "LIBERO" => if(series["gender"] == "FEMALE", do: "Libera", else: "Libero"),
      "WING_SPIKER" => "Außenangriff",
      "OPPOSITE" => "Diagonal",
      "SETTER" => "Zuspiel",
      "MIDDLE_BLOCKER" => "Mittelblock",
      "UNIVERSAL" => "Universal"
    }

    player =
      assigns.ticker
      |> Ticker.player(assigns.match_uuid, assigns.player_uuid)

    arbitration = assigns.ticker |> Ticker.arbitration(assigns.match_uuid)

    assigns =
      assigns
      |> assign(:player, player)
      |> assign(:position_names, position_names)
      |> assign(:arbitration, arbitration)

    ~H"""
    <style>
      @keyframes popup {
        0% {
          transform: translateY(200px);
        }
        100% {
          transform: translateY(0);
        }
      }

      @keyframes popdown {
        0% {
          transform: translateY(0);
        }
        100% {
          transform: translateY(200px);
        }
      }

      @keyframes slideout {
        0% {
          transform: translateX(-100%);
        }
        100% {
          transform: translateX(0);
        }
      }

      @keyframes slidein {
        0% {
          transform: translateX(0);
        }
        100% {
          transform: translateX(-100%);
        }
      }

      #logo {
        animation-name: popup;
        animation-duration: 0.4s;
      }

      #mask {
        overflow: hidden;
      }

      #text {
        animation-name: slideout;
        animation-duration: 0.4s;
        animation-delay: 0.4s;
        animation-fill-mode: both;
      }

      #lower-third.remove #text {
        animation-name: slidein;
        animation-delay: 0s;
      }

      #lower-third.remove #logo {
        animation-name: popdown;
        animation-delay: 0.4s;
        animation-fill-mode: both;
      }
    </style>
    <%= if @player_uuid != nil do %>
      <div
        id="lower-third"
        class={"absolute bottom-16 w-full flex justify-center font-display #{if @removed, do: "remove"}"}
      >
        <%= if String.ends_with?(@player_uuid, "Referee") do %>
          <div class="flex">
            <div id="logo" class="w-32 h-32 bg-vbldarkblue p-4">
              <img src="/images/referee.svg" />
            </div>
            <div id="mask">
              <div id="text">
                <div class="h-16 bg-vbldarkblue text-white flex items-center text-xl">
                  <span class="ml-6 mr-8">
                    <%= @arbitration[@player_uuid]["firstName"] %> <%= @arbitration[@player_uuid][
                      "lastName"
                    ] %>
                  </span>
                </div>
                <div class="h-16 bg-vblgray text-vbldarkblue flex items-center text-xl">
                  <span class="ml-6 mr-8">
                    <%= if @player_uuid == "firstReferee",
                      do: "1.",
                      else: "2." %> Schiedrichter<%= if Map.has_key?(@genders, @player_uuid),
                      do: if(@genders[@player_uuid] == "F", do: "in"),
                      else: "/in" %>
                  </span>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <div class="flex">
            <div id="logo" class="w-32 h-32 bg-vbldarkblue p-4">
              <img src={@player["team"]["logoImage200"]} />
            </div>
            <div id="mask">
              <div id="text">
                <div class="h-16 bg-vbldarkblue text-white flex items-center text-xl">
                  <strong class="mx-6"><%= @player["jerseyNumber"] %></strong>
                  <span class="mr-8"><%= @player["firstName"] %> <%= @player["lastName"] %></span>
                </div>
                <div class="h-16 bg-vblgray text-vbldarkblue flex items-center text-xl">
                  <span class="ml-6 mr-8">
                    <%= if Map.has_key?(@position_names, @player["position"]),
                      do: @position_names[@player["position"]],
                      else: @player["team"]["name"] %>
                  </span>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  def handle_info({:ticker, ticker}, socket) do
    {:noreply, assign(socket, :ticker, ticker)}
  end

  def handle_info({:match_uuid, match_uuid}, socket) do
    {:noreply, assign(socket, :match_uuid, match_uuid)}
  end

  def handle_info({:player_selector, {player_uuid, genders}}, socket) do
    socket = socket |> assign(:genders, genders)

    if player_uuid == nil do
      {:noreply, assign(socket, :removed, true)}
    else
      {:noreply, socket |> assign(:removed, false) |> assign(:player_uuid, player_uuid)}
    end
  end
end
