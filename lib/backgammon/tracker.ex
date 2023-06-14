defmodule Backgammon.Tracker do
  @moduledoc false

  use Phoenix.Tracker

  alias Backgammon.Server

  @name __MODULE__

  @games_topic "games"

  def start_link(opts \\ []) do
    opts = Keyword.merge([name: @name], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  @doc """
  Starts tracking the given game, making it visible globally.
  """
  @spec track_game(Server.t()) :: :ok | {:error, any()}
  def track_game(game) do
    case Phoenix.Tracker.track(@name, game.pid, @games_topic, game.id, %{
           game: game
         }) do
      {:ok, _ref} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Updates the tracked game object matching the given id.
  """
  @spec update_game(Server.t()) :: :ok | {:error, any()}
  def update_game(game) do
    case Phoenix.Tracker.update(@name, game.pid, @games_topic, game.id, %{
           game: game
         }) do
      {:ok, _ref} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns all tracked games.
  """
  @spec list_games() :: list(Server.t())
  def list_games() do
    presences = Phoenix.Tracker.list(@name, @games_topic)
    for {_id, %{game: game}} <- presences, do: game
  end

  @doc """
  Returns tracked game with the given id.
  """
  @spec fetch_game(Server.id()) :: {:ok, Server.t()} | :error
  def fetch_game(id) do
    case Phoenix.Tracker.get_by_key(@name, @games_topic, id) do
      [{_id, %{game: game}}] -> {:ok, game}
      _ -> :error
    end
  end

  @impl true
  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  @impl true
  def handle_diff(diff, state) do
    for {topic, topic_diff} <- diff do
      handle_topic_diff(topic, topic_diff, state)
    end

    {:ok, state}
  end

  defp handle_topic_diff(@games_topic, {joins, leaves}, state) do
    joins = Map.new(joins)
    leaves = Map.new(leaves)

    messages =
      for id <- Enum.uniq(Map.keys(joins) ++ Map.keys(leaves)) do
        case {joins[id], leaves[id]} do
          {%{game: game}, nil} -> {:game_created, game}
          {nil, %{game: game}} -> {:game_closed, game}
          {%{game: game}, %{}} -> {:game_updated, game}
        end
      end

    for message <- messages do
      Phoenix.PubSub.direct_broadcast!(
        state.node_name,
        state.pubsub_server,
        "tracker_games",
        message
      )
    end
  end
end
