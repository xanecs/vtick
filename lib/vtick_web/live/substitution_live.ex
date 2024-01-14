defmodule VtickWeb.SubstitutionLive do
  use VtickWeb, :live_view
  alias Vtick.TickerState
  alias Vtick.Ticker
  alias Vtick.MatchSelector

  def mount(params, _session, socket) do
    VtickWeb.Endpoint.subscribe("ticker")
    VtickWeb.Endpoint.subscribe("match_selector")

    if params["debug"] do
      Process.send(self(), {:ticker, TickerState.get_state()}, [])
    end

    ticker = TickerState.get_state()
    match_uuid = MatchSelector.get_match_uuid()
    state = ticker |> Ticker.state(match_uuid)

    latest_event_uuid =
      if params["debug"] do
        nil
      else
        if state != nil do
          state["eventHistory"] |> List.first(%{"uuid" => nil}) |> Map.get("uuid")
        else
          nil
        end
      end

    socket =
      socket
      |> assign(:ticker, ticker)
      |> assign(:match_uuid, match_uuid)
      |> assign(:substitutions_queue, :queue.new())
      |> stream_configure(:substitutions, dom_id: &"sub-#{Map.get(&1, "uuid")}")
      |> stream(:substitutions, [])
      |> assign(:latest_event_uuid, latest_event_uuid)

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

    assigns =
      assigns
      |> assign(:position_names, position_names)

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
          transform: translateX(-105%);
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
          transform: translateX(-105%);
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

      .remove .logocontainer {
        animation: logoout 0.8s;
        animation-fill-mode: both;

      }

      .remove .namecontainer {
        animation: nameout 0.8s;
        animation-fill-mode: both;
      }
    </style>
    <div id="cards" phx-update="stream">
      <VtickWeb.Components.Substitution.lower_third
        :for={{id, sub} <- @streams.substitutions}
        id={id}
        player_in={@ticker |> Ticker.player(assigns.match_uuid, sub["playerInUuid"])}
        player_out={@ticker |> Ticker.player(assigns.match_uuid, sub["playerOutUuid"])}
        position_names={@position_names}
      />
    </div>
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

    substitutions_queue =
      socket.assigns.substitutions_queue |> :queue.join(:queue.from_list(new_events))

    socket =
      socket
      |> assign(:ticker, ticker)
      |> assign(:substitutions_queue, substitutions_queue)
      |> assign(
        :latest_event_uuid,
        new_events |> List.first(%{"uuid" => socket.assigns.latest_event_uuid}) |> Map.get("uuid")
      )

    # Restart the timer if there are new substitutions
    if :queue.len(substitutions_queue) == Enum.count(new_events) and Enum.count(new_events) > 0 do
      Process.send(self(), :next, [])
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
    {next, substitutions_queue} =
      case :queue.out(socket.assigns.substitutions_queue) do
        {{:value, sub}, substitutions_queue} -> {sub, substitutions_queue}
        {:empty, substitutions_queue} -> {nil, substitutions_queue}
      end

    if :queue.len(substitutions_queue) > 0 do
      Process.send_after(self(), :next, 10000)
    end

    socket =
      if next != nil do
        socket |> stream_insert(:substitutions, next)
      else
        socket
      end

    socket = socket |> assign(:substitutions_queue, substitutions_queue)

    {:noreply, socket}
  end
end
