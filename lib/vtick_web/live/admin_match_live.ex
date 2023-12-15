defmodule VtickWeb.AdminMatchLive do
  alias Vtick.MatchSelector
  alias Vtick.TickerState
  alias Vtick.Ticker
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    VtickWeb.Endpoint.subscribe("ticker")
    VtickWeb.Endpoint.subscribe("match_selector")

    socket =
      socket
      |> assign(:ticker, TickerState.get_state())
      |> assign(:match, MatchSelector.get_match_uuid())
      |> assign(:page_title, "Select Match")
      |> assign(:team_filter, nil)
      |> assign(:active_page, :matches)

    {:ok, socket}
  end

  def render(assigns) do
    matches =
      assigns.ticker
      |> Ticker.matches()

    assigns =
      assigns
      |> assign(:matches, matches)

    ~H"""
    <ul role="list" class="divide-y divide-gray-100 bg-white shadow card">
      <%= for match <- @matches do %>
        <li
          class="flex justify-between gap-x-6 py-5 hover:bg-gray-50 p-4 cursor-pointer"
          phx-click="set_match"
          phx-value-uuid={match["id"]}
        >
          <div class="flex min-w-0 gap-x-4">
            <div class={"w-12 h-12 rounded-full border-gray-300 border #{ if match["id"] == @match, do: "bg-teal-500", else: ""}"}>
            </div>
            <div class="min-w-0 flex-auto">
              <p class="text-sm">
                <%= DateTime.from_unix!(match["date"], :millisecond)
                |> Calendar.strftime("%d.%m.%Y %H:%M") %>
              </p>
              <p><%= match["teamDescription1"] %> - <%= match["teamDescription2"] %></p>
            </div>
          </div>
        </li>
      <% end %>
    </ul>
    """
  end

  def handle_event("set_match", %{"uuid" => uuid}, socket) do
    MatchSelector.set_match_uuid(uuid)
    {:noreply, socket}
  end

  def handle_info({:ticker, ticker}, socket) do
    {:noreply, assign(socket, :ticker, ticker)}
  end

  def handle_info({:match_uuid, match_uuid}, socket) do
    {:noreply, assign(socket, :match, match_uuid)}
  end
end
