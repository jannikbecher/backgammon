defmodule Backgammon.Server do
  @moduledoc false

  defstruct [
    :id,
    :pid,
    :created_at
  ]

  use GenServer, restart: :temporary

  alias Backgammon.{Game, Utils}

  @timeout :infinity
  @client_id "__server__"
  @anonymous_client_id "__anonymous__"

  @type t :: %__MODULE__{
          id: id(),
          pid: pid(),
          created_at: DateTime.t()
        }

  @type state :: %{
          game_id: id(),
          game: Game.t(),
          client_pids_with_id: %{pid() => Game.client_id()},
          created_at: DateTime.t()
        }

  @type id :: Utils.id()

  @doc """
  Starts a backgammon game process. 

  ## Options
    * `id` (**required) - a unique id
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, any()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """

  """
  @spec get_current_state(pid()) :: Game.t()
  def get_current_state(pid) do
    GenServer.call(pid, :get_current_state)
  end

  @doc """

  """
  @spec start_game(pid()) :: {:ok, atom()}
  def start_game(pid) do
    GenServer.call(pid, {:start_game, self()})
  end

  @doc """

  """
  @spec move_checker(pid(), tuple()) :: :ok
  def move_checker(pid, move) do
    GenServer.call(pid, {:move_checker, self(), move})
  end

  @doc """

  """
  @spec apply_turn(pid()) :: {:ok, atom(), atom()} | {:error, any()}
  def apply_turn(pid) do
    GenServer.call(pid, {:apply_turn, self()})
  end

  @doc """

  """
  @spec roll_dice(pid()) :: {:ok, atom()}
  def roll_dice(pid) do
    GenServer.call(pid, {:roll_dice, self()})
  end

  @doc """
  Subscribes to game messages.

  ## Messages
    * `:game_closed`
    * `{:game_updated, game}`
    * `{:operation, operation}`
    * `{:error, error}`
  """
  @spec subscribe(id()) :: :ok | {:error, term()}
  def subscribe(game_id) do
    Phoenix.PubSub.subscribe(Backgammon.PubSub, "games:#{game_id}")
  end

  @doc """
  Fetches game information from the game server.
  """
  @spec get_by_pid(pid()) :: Server.t()
  def get_by_pid(pid) do
    GenServer.call(pid, :describe_self, @timeout)
  end

  @doc """
  Registers a game client, so that the game server is aware of it.

  The client process is automatically unregistered when it terminates.

  Returns the current game data, which the client can than
  keep in sync with the server by subscribing to the `games:id`
  topic and receiving operations to apply.

  Also returns a unique client identifier representing the registered
  client.
  """
  @spec register_client(pid(), pid(), any()) :: {Game.t(), any()}
  def register_client(pid, client_pid, user) do
    GenServer.call(pid, {:register_client, client_pid, user}, @timeout)
  end

  @doc """
  Returns game data of the given game.
  """
  @spec get_game(pid()) :: Game.t()
  def get_game(pid) do
    GenServer.call(pid, :get_game, @timeout)
  end

  @doc """
  Closes one or more games.

  This results in broadcasting a :closed message to the games topic.
  """
  @spec close(pid() | [pid()]) :: :ok
  def close(pid) do
    _ = call_many(List.wrap(pid), :close)
  end

  # ===

  defp handle_operation(state, operation) do
    broadcast_operation(state.game_id, operation)

    case Game.apply_operation(state.game, operation) do
      {:ok, new_game, actions} ->
        %{state | game: new_game}
        |> after_operation(state, operation)
        |> handle_actions(actions)

      :error ->
        state
    end
  end

  defp after_operation(state, _prev_state, _operation), do: state

  defp handle_actions(state, actions) do
    Enum.reduce(actions, state, &handle_action(&2, &1))
  end

  defp handle_action(state, _action), do: state

  @impl true
  def init(opts) do
    id = Keyword.fetch!(opts, :id)

    state = %{
      game_id: id,
      game: Game.new(),
      client_pids_with_id: %{},
      created_at: DateTime.utc_now()
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:start_game, client_pid}, _from, state) do
    client_id = client_id(state, client_pid)
    operation = {:start_game, client_id, get_start_roll()}

    {:reply, :ok, handle_operation(state, operation)}
  end

  @impl true
  def handle_call({:roll_dice, client_pid}, _from, state) do
    client_id = client_id(state, client_pid)
    operation = {:set_dice, client_id, roll_dice()}

    {:reply, :ok, handle_operation(state, operation)}
  end

  @impl true
  def handle_call({:move_checker, client_pid, move}, _from, state) do
    client_id = client_id(state, client_pid)
    operation = {:move_checker, client_id, move}

    {:reply, :ok, handle_operation(state, operation)}
  end

  @impl true
  def handle_call({:apply_turn, client_pid}, _from, state) do
    client_id = client_id(state, client_pid)
    operation = {:apply_turn, client_id}

    # TODO: handle invalid turns
    {:reply, :ok, handle_operation(state, operation)}
  end

  @impl true
  def handle_call(:describe_self, _from, state) do
    {:reply, self_from_state(state), state}
  end

  @impl true
  def handle_call({:register_client, client_pid, user}, _from, state) do
    {state, client_id} =
      if client_id = state.client_pids_with_id[client_pid] do
        {state, client_id}
      else
        Process.monitor(client_pid)
        client_id = :crypto.strong_rand_bytes(20) |> Base.encode32(case: :lower)
        state = handle_operation(state, {:client_join, client_id, user})
        state = put_in(state.client_pids_with_id[client_pid], client_id)
        {state, client_id}
      end

    {:reply, {state.game, client_id}, state}
  end

  @impl true
  def handle_call(:get_game, _from, state) do
    {:reply, state.game, state}
  end

  @impl true
  def handle_call(:close, _from, state) do
    # TODO: does anything needs to be handled before shutting down?
    {:stop, :shutdown, :ok, state}
  end

  # ===

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    state =
      if client_id = state.client_pids_with_id[pid] do
        handle_operation(state, {:client_leave, client_id})
      else
        state
      end

    {:noreply, state}
  end

  # ===

  defp client_id(state, client_pid) do
    state.client_pids_with_id[client_pid] || @anonymous_client_id
  end

  defp self_from_state(state) do
    %__MODULE__{
      id: state.game_id,
      pid: self(),
      created_at: state.created_at
    }
  end

  defp call_many(list, request) do
    list
    |> Enum.map(&:gen_server.send_request(&1, request))
    |> Enum.map(&:gen_server.wait_response(&1, :infinity))
  end

  defp broadcast_operation(game_id, operation) do
    broadcast_message(game_id, {:operation, operation})
  end

  defp broadcast_message(game_id, message) do
    Phoenix.PubSub.broadcast(Backgammon.PubSub, "games:#{game_id}", message)
  end

  # ===

  defp roll_dice() do
    {:rand.uniform(6), :rand.uniform(6)}
  end

  defp get_start_roll() do
    case roll_dice() do
      {double, double} -> get_start_roll()
      start_roll -> start_roll
    end
  end
end
