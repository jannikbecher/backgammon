defmodule Backgammon.Games do
  @moduledoc false

  alias Backgammon.Server

  @doc """
  Spawns a new `Game` process with the given options.

  Makes the game globally visible within the game tracker.
  """
  @spec create_game(keyword()) :: {:ok, Server.t()} | {:error, any()}
  def create_game(opts \\ []) do
    id = random_node_aware_id()

    opts = Keyword.put(opts, :id, id)

    case DynamicSupervisor.start_child(Backgammon.GameSupervisor, {Server, opts}) do
      {:ok, pid} ->
        game = Server.get_by_pid(pid)

        case Backgammon.Tracker.track_game(game) do
          :ok ->
            {:ok, game}

          {:error, reason} ->
            Server.close(pid)
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns all the running games.
  """
  @spec list_games() :: list(Server.t())
  def list_games() do
    Backgammon.Tracker.list_games()
  end

  @doc """
  Returns tracked game with the given id.
  """
  @spec fetch_game(Server.id()) :: {:ok, Server.t()} | :error
  def fetch_game(id) do
    case Backgammon.Tracker.fetch_game(id) do
      {:ok, game} ->
        {:ok, game}

      :error ->
        # TODO: handle multiple nodes
        # https://github.com/livebook-dev/livebook/blob/d5f9aaf14e6cdf2b86282cdcadc202575af7f131/lib/livebook/sessions.ex#L59
        :error
    end
  end

  @doc """
  Updates the given game info across the cluster.
  """
  @spec update_game(Server.t()) :: :ok | {:error, any()}
  def update_game(game) do
    Backgammon.Tracker.update_game(game)
  end

  @doc """
  Subscribes to update in games list.

  ## Messages
    * `{:game_created, game}`
    * `{:game_updated, game}`
    * `{:game_closed, game}`
  """
  @spec subscribe() :: :ok | {:error, term()}
  def subscribe() do
    Phoenix.PubSub.subscribe(Backgammon.PubSub, "tracker_games")
  end

  defp random_node_aware_id() do
    node_part = node_hash(node())
    random_part = :crypto.strong_rand_bytes(9)
    binary = <<node_part::binary, random_part::binary>>
    Base.encode32(binary, case: :lower)
  end

  defp node_hash(node) do
    content = Atom.to_string(node)
    :erlang.md5(content)
  end
end
