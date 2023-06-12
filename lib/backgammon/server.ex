defmodule Backgammon.Server do
  @moduledoc false

  use GenServer

  alias Backgammon.Game

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
  @spec get_available_actions(pid()) :: list()
  def get_available_actions(pid) do
    GenServer.call(pid, :get_available_actions)
  end

  @doc """

  """
  @spec get_current_state(pid()) :: Game.t()
  def get_current_state(pid) do
    GenServer.call(pid, :get_current_state)
  end

  @doc """

  """
  @spec apply_action(pid(), Game.action()) :: {:ok, atom(), atom()} | {:error, any()}
  def apply_action(pid, action) do
    GenServer.call(pid, {:apply_action, action})
  end

  @impl true
  def init(_) do
    {:ok, Game.new()}
  end

  @impl true
  def handle_call(:get_available_actions, _from, game) do
    actions = Game.get_available_actions(game)
    {:reply, actions, game}
  end

  @impl true
  def handle_call(:get_current_state, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call({:apply_action, action}, _from, game) do
    valid_actions = Game.get_available_actions(game)

    if action in valid_actions do
      updated_game = Game.apply_action(game, action)

      {:reply, {:ok, updated_game}, updated_game}
    else
      {:reply, {:error, "Not a valid action: #{inspect(action)}"}, game}
    end
  end
end
