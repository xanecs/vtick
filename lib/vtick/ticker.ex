defmodule Vtick.Ticker do
  def matches(ticker) do
    if ticker != nil and Map.has_key?(ticker, "matchDays") do
      ticker["matchDays"]
      |> Enum.map(fn day -> day["matches"] end)
      |> List.flatten()
    else
      []
    end
  end

  def match(ticker, match_uuid) do
    ticker
    |> matches()
    |> Enum.find(fn match -> match["id"] == match_uuid end)
  end

  def teams(ticker) do
    if ticker != nil and Map.has_key?(ticker, "matchSeries") do
      ticker["matchSeries"]
      |> Map.values()
      |> Enum.map(fn series -> series["teams"] end)
      |> List.flatten()
    else
      []
    end
  end

  def teams_map(ticker) do
    ticker
    |> teams()
    |> Enum.map(fn team -> {team["id"], team} end)
    |> Map.new()
  end

  def series(ticker, series_uuid) do
    if ticker != nil and Map.has_key?(ticker, "matchSeries") do
      ticker["matchSeries"][series_uuid]
    else
      nil
    end
  end

  def all_series(ticker) do
    if ticker != nil and Map.has_key?(ticker, "matchSeries") do
      ticker["matchSeries"]
    else
      []
    end
  end

  def state(ticker, match_uuid) do
    if ticker != nil and Map.has_key?(ticker, "matchStates") do
      ticker["matchStates"][match_uuid]
    else
      nil
    end
  end

  def squad(ticker, match_uuid, side) do
    state = state(ticker, match_uuid)

    if(state != nil) do
      event =
        state["eventHistory"]
        |> Enum.find(fn event ->
          event["teamCode"] == side and event["type"] == "CONFIRM_TEAMSQUAD"
        end)

      if event != nil do
        event["teamSquad"]["players"]
        |> Enum.sort_by(fn player -> Integer.parse(player["jerseyNumber"]) end)
      else
        []
      end
    else
      []
    end
  end

  def arbitration(ticker, match_uuid) do
    state = state(ticker, match_uuid)

    if(state != nil) do
      event =
        state["eventHistory"] |> Enum.find(fn event -> event["type"] == "CONFIRM_ARBITRATION" end)

      if event != nil do
        event["arbitration"]
      else
        nil
      end
    else
      nil
    end
  end

  def player(ticker, match_uuid, player_uuid) do
    match = ticker |> match(match_uuid)
    teams = ticker |> teams_map()

    ticker
    |> squads(match_uuid)
    |> Map.to_list()
    |> Enum.map(fn {side, players} ->
      Enum.map(players, fn player -> player |> Map.put("team", teams[match[side]]) end)
    end)
    |> List.flatten()
    |> Enum.find(fn player -> player["uuid"] == player_uuid end)
  end

  def mvps(ticker, match_uuid) do
    state = state(ticker, match_uuid)

    if(state != nil) do
      state["eventHistory"]
      |> Enum.filter(fn event -> event["type"] == "SELECT_MVP" end)
      |> Enum.map(fn event -> event["playerUuid"] end)
    else
      []
    end
  end

  def squads(ticker, match_uuid) do
    ["team1", "team2"]
    |> Enum.map(fn side -> {side, squad(ticker, match_uuid, side)} end)
    |> Map.new()
  end
end
