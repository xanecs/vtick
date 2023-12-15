defmodule VtickWeb.SubstitutionLive do
  use VtickWeb, :live_view
  alias Vtick.TickerState
  alias Vtick.Ticker
  alias Vtick.MatchSelector
  alias Vtick.PlayerSelector

  def mount(_params, _session, socket) do
    VtickWeb.Endpoint.subscribe("ticker")
    VtickWeb.Endpoint.subscribe("match_selector")
    # Process.send(self(), {:ticker, TickerState.get_state()}, [])
    ticker = TickerState.get_state()
    match_uuid = MatchSelector.get_match_uuid()
    state = ticker |> Ticker.state(match_uuid)

    latest_event_uuid =
      if state != nil do
        state["eventHistory"] |> List.first(%{"uuid" => nil}) |> Map.get("uuid")
      else
        nil
      end

    socket =
      socket
      |> assign(:ticker, ticker)
      |> assign(:match_uuid, match_uuid)
      |> assign(:substitutions, :queue.new())
      |> assign(:last_sub, nil)
      |> assign(:latest_event_uuid, latest_event_uuid)

    {:ok, socket}
  end

  def render(assigns) do
    last_player_in =
      assigns.ticker |> Ticker.player(assigns.match_uuid, assigns.last_sub["playerInUuid"])

    last_player_out =
      assigns.ticker |> Ticker.player(assigns.match_uuid, assigns.last_sub["playerOutUuid"])

    current_sub =
      case assigns.substitutions |> :queue.peek() do
        :empty -> nil
        {:value, sub} -> sub
      end

    player_in = assigns.ticker |> Ticker.player(assigns.match_uuid, current_sub["playerInUuid"])
    player_out = assigns.ticker |> Ticker.player(assigns.match_uuid, current_sub["playerOutUuid"])

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

    assigns =
      assigns
      |> assign(:player_in, player_in)
      |> assign(:player_out, player_out)
      |> assign(:last_player_in, last_player_in)
      |> assign(:last_player_out, last_player_out)
      |> assign(:position_names, position_names)
      |> assign(:current_sub_uuid, current_sub["uuid"])

    ~H"""
    <style>
      @keyframes icon {

        0%, 28% {
          transform: translateY(0);
        }
        33%, 100% {
          transform: translateY(-150%);
        }
      }

      @keyframes logo {
        0%, 28% {
          transform: translateY(150%);
        }

        33%, 100% {
          transform: translateY(0);
        }
      }

      @keyframes logocontainer {
        0% {
          transform: translateY(200px);
        }
        5%, 100% {
          transform: translateY(0);
        }
      }

      @keyframes namecontainer {
        0%, 5% {
          transform: translateX(-100%);
        }
        10%, 100% {
          transform: translateY(0);
        }
      }

      @keyframes playerout-name {
        0%, 28% {
          background-color: rgba(27, 54, 93, 0.9);
        }

        33%, 61% {
          background-color: rgba(136, 56, 56, 0.9);
          transform: none;
        }

        66%, 100% {
          transform: translateY(-100%);
          background-color: rgba(136, 56, 56, 0.9);
        }
      }

      @keyframes playerout-position {
        0%, 28% {
          opacity: 1;
        }

        33%, 100% {
          opacity: 0;
        }
      }

      @keyframes playerin {
        0%, 28% {
          transform: translateY(0%);
        }
        33%, 61% {
          transform: translateY(-50%);
        }
        66%, 100% {
          transform: translateY(-100%);
        }
      }

      @keyframes logoout {
        0%, 50% {
          transform: translateY(0%);
        }
        100% {
          transform: translateY(200px);
        }
      }

      @keyframes nameout {
        0% {
          transform: translateX(0%);
        }
        50%, 100% {
          transform: translateX(-100%);
        }
      }

      .mask, .logocontainer {
        overflow: hidden;
      }

      .current .icon {
        animation: icon 8s;
        animation-delay: 0.8s;
        animation-fill-mode: both;
      }

      .current .logo {
        animation: logo 8s;
        animation-delay: 0.8s;
        animation-fill-mode: both;
      }

      .current .playerout .name {
        animation: playerout-name 8s;
        animation-delay: 0.8s;
        animation-fill-mode: both;
      }

      .current .playerout .position {
        animation: playerout-position 8s;
        animation-delay: 0.8s;
        animation-fill-mode: both;
      }

      .current .playerin{
        animation: playerin 8s;
        animation-delay: 0.8s;
        animation-fill-mode: both;
      }

      .current .logocontainer {
        animation: logocontainer 8s;
        animation-delay: 0.8s;
        animation-fill-mode: both;
      }

      .current .namecontainer {
        animation: namecontainer 8s;
        animation-delay: 0.8s;
        animation-fill-mode: both;
      }

      .last .logocontainer {
        animation: logoout 0.8s;
        animation-fill-mode: both;

      }

      .last .namecontainer {
        animation: nameout 0.8s;
        animation-fill-mode: both;
      }
    </style>
    <%= if @current_sub_uuid do %>
      <div
        id={@current_sub_uuid}
        class={"current absolute bottom-16 w-full flex justify-center font-display #{@current_sub_uuid}"}
        phx-hook="Anim"
      >
        <div class="flex">
          <div class="anim logocontainer w-32 h-32 bg-vbldarkblue relative">
            <img class="anim icon absolute inset-4 w-24 h-24" src="/images/substitution.svg" />
            <img
              class="anim logo absolute inset-4 w-24 h-24"
              src={@player_out["team"]["logoImage200"]}
            />
          </div>
          <div class="mask h-32">
            <div class="anim namecontainer">
              <div class="anim playerout">
                <div class="anim name h-16 bg-vbldarkblue text-white flex items-center text-xl">
                  <strong class="mx-6"><%= @player_out["jerseyNumber"] %></strong>
                  <span class="mr-8">
                    <%= @player_out["firstName"] %> <%= @player_out["lastName"] %>
                  </span>
                </div>
                <div class="anim position h-16 bg-vblgray text-vbldarkblue flex items-center text-xl">
                  <span class="ml-6 mr-8">
                    <%= if Map.has_key?(@position_names, @player_out["position"]),
                      do: @position_names[@player_out["position"]],
                      else: @player_out["team"]["name"] %>
                  </span>
                </div>
              </div>
              <div class="anim playerin">
                <div class="h-16 bg-vblgreen text-white flex items-center text-xl">
                  <strong class="mx-6"><%= @player_in["jerseyNumber"] %></strong>
                  <span class="mr-8">
                    <%= @player_in["firstName"] %> <%= @player_in["lastName"] %>
                  </span>
                </div>
                <div class="h-16 bg-vblgray text-vbldarkblue flex items-center text-xl">
                  <span class="ml-6 mr-8">
                    <%= if Map.has_key?(@position_names, @player_in["position"]),
                      do: @position_names[@player_in["position"]],
                      else: @player_in["team"]["name"] %>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    <%= if @last_sub != nil do %>
      <div class="last absolute bottom-16 w-full flex justify-center font-display ">
        <div class="flex">
          <div class="anim logocontainer w-32 h-32 p-4 bg-vbldarkblue relative">
            <img
              class="logo inset-4 w-24 h-24 absolute"
              src={@last_player_out["team"]["logoImage200"]}
            />
          </div>
          <div class="mask h-32">
            <div class="anim namecontainer">
              <div class="playerin">
                <div class="h-16 bg-vblgreen text-white flex items-center text-xl">
                  <strong class="mx-6"><%= @last_player_in["jerseyNumber"] %></strong>
                  <span class="mr-8">
                    <%= @last_player_in["firstName"] %> <%= @last_player_in["lastName"] %>
                  </span>
                </div>
                <div class="h-16 bg-vblgray text-vbldarkblue flex items-center text-xl">
                  <span class="ml-6 mr-8">
                    <%= if Map.has_key?(@position_names, @last_player_in["position"]),
                      do: @position_names[@last_player_in["position"]],
                      else: @last_player_in["team"]["name"] %>
                  </span>
                </div>
              </div>
              <div class="namecontainer">
                <div class="playerout">
                  <div class="name h-16 bg-vbldarkblue text-white flex items-center text-xl">
                    <strong class="mx-6"><%= @last_player_out["jerseyNumber"] %></strong>
                    <span class="mr-8">
                      <%= @last_player_out["firstName"] %> <%= @last_player_out["lastName"] %>
                    </span>
                  </div>
                  <div class="position h-16 bg-vblgray text-vbldarkblue flex items-center text-xl">
                    <span class="ml-6 mr-8">
                      <%= if Map.has_key?(@position_names, @last_player_out["position"]),
                        do: @position_names[@last_player_out["position"]],
                        else: @last_player_out["team"]["name"] %>
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  def handle_info({:ticker, ticker}, socket) do
    state = ticker |> Ticker.state(socket.assigns.match_uuid)

    new_events =
      if state != nil do
        state["eventHistory"]
        |> Enum.take_while(fn event -> event["uuid"] != socket.assigns.latest_event_uuid end)
        |> Enum.filter(fn event -> event["type"] == "SUBSTITUTION" end)
      else
        []
      end

    substitutions = socket.assigns.substitutions |> :queue.join(:queue.from_list(new_events))

    socket =
      socket
      |> assign(:ticker, ticker)
      |> assign(:substitutions, substitutions)
      |> assign(
        :latest_event_uuid,
        new_events |> List.first(%{"uuid" => socket.assigns.latest_event_uuid}) |> Map.get("uuid")
      )

    # Restart the timer if there are new substitutions
    if :queue.len(substitutions) == Enum.count(new_events) and Enum.count(new_events) > 0 do
      Process.send_after(self(), :next, 8000)
    end

    {:noreply, socket}
  end

  def handle_info({:match_uuid, match_uuid}, socket) do
    state = socket.assigns.ticker |> Ticker.state(match_uuid)

    latest_event_uuid =
      if state != nil do
        state["eventHistory"] |> List.first(%{"uuid" => nil}) |> Map.get("uuid")
      else
        nil
      end

    {:noreply,
     socket |> assign(:latest_event_uuid, latest_event_uuid) |> assign(:match_uuid, match_uuid)}
  end

  def handle_info(:next, socket) do
    {last, substitutions} =
      case :queue.out(socket.assigns.substitutions) do
        {{:value, sub}, substitutions} -> {sub, substitutions}
        {:empty, substitutions} -> {nil, substitutions}
      end

    if :queue.len(substitutions) > 0 do
      Process.send_after(self(), :next, 8000)
    end

    socket = socket |> assign(:last_sub, last) |> assign(:substitutions, substitutions)

    {:noreply, socket}
  end
end
