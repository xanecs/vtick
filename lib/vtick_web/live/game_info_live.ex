defmodule VtickWeb.GameInfoLive do
  use VtickWeb, :live_view
  alias Vtick.Ticker
  alias Vtick.TickerState
  alias Vtick.MatchSelector

  def mount(_params, _session, socket) do
    VtickWeb.Endpoint.subscribe("ticker")
    VtickWeb.Endpoint.subscribe("match_selector")

    socket =
      socket
      |> assign(:ticker, TickerState.get_state())
      |> assign(:match_uuid, MatchSelector.get_match_uuid())

    {:ok, socket}
  end

  def render(assigns) do
    match =
      assigns.ticker
      |> Ticker.match(assigns.match_uuid)

    series =
      assigns.ticker
      |> Ticker.series(match["matchSeries"])

    teams =
      assigns.ticker
      |> Ticker.teams_map()

    assigns =
      assigns
      |> assign(:match, match)
      |> assign(:series, series)
      |> assign(:teams, teams)

    ~H"""
    <%= if @match != nil do %>
      <div class="h-full w-full flex flex-col items-center">
        <div class="pt-24 p-16 bg-vbldarkblue w-4/6 relative">
          <img class="absolute w-32 h-32 top-12 left-12" src="/images/vbl_logo.png" />
          <div class="text-center text-5xl text-white font-display uppercase">
            <%= @series["name"] %>
          </div>
          <div class="my-24 flex items-center justify-center gap-16">
            <div class="flex flex-col items-center gap-4">
              <img src={@teams[@match["team1"]]["logoImage200"]} />
              <div class="text-3xl text-white font-display">
                <%= @teams[@match["team1"]]["name"] %>
              </div>
            </div>
            <div class="text-white font-display font-bold text-5xl">VS</div>
            <div class="flex flex-col items-center gap-4">
              <img src={@teams[@match["team2"]]["logoImage200"]} />
              <div class="text-3xl text-white font-display">
                <%= @teams[@match["team2"]]["name"] %>
              </div>
            </div>
          </div>
        </div>
        <div class="bg-vblgray p-4 w-4/6 text-center text-vbldarkblue text-2xl">
          <%= DateTime.from_unix!(@match["date"], :millisecond)
          |> DateTime.shift_zone!("Europe/Berlin")
          |> Calendar.strftime("%d.%m.%Y / %H:%M Uhr") %>
        </div>
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
end
