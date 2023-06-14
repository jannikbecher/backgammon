defmodule Backgammon.Game do
  @moduledoc false

  defstruct [
    :board,
    :current_player,
    :dice_roll,
    :valid_turns,
    :move_stack,
    :game_state,
    :game_value,
    :clients_map,
    :users_map
  ]

  alias Backgammon.Game
  alias Backgammon.Game.Board

  import Backgammon.Helpers

  @type t :: %Game{
          board: Board.t(),
          current_player: :black | :white | nil,
          dice_roll: dice_roll() | nil,
          # TODO: create turn type
          valid_turns: list(),
          move_stack: list(checker_move()),
          game_state: :ready | :running | :finished,
          game_value: -3..3,
          clients_map: %{client_id() => any()},
          users_map: %{any() => any()}
        }

  @type from :: 1..24 | :bar
  @type to :: 1..24 | :bear_off

  @type dice_roll :: {1..6, 1..6}

  @type checker_move :: {from(), to()}

  @type client_id :: Backgammon.Utils.id()

  @type operation ::
          {:start_game, client_id(), dice_roll()}
          | {:apply_turn, client_id()}
          | {:set_dice, client_id(), dice_roll()}
          # TODO: implement user logic. For now Test User
          | {:client_join, client_id(), any()}
          | {:client_leave, client_id()}

  @spec new(keyword()) :: t()
  def new(_opts \\ []) do
    %Game{
      board: Board.new(),
      current_player: nil,
      dice_roll: nil,
      valid_turns: [],
      move_stack: [],
      game_state: :ready,
      game_value: 0,
      clients_map: %{},
      users_map: %{}
    }
  end

  @spec apply_operation(t(), operation()) :: {:ok, t(), list()} | :error
  def apply_operation(game, operation)

  def apply_operation(game, {:start_game, _client_id, dice_roll}) do
    game
    |> with_actions()
    |> start_game(dice_roll)
    |> wrap_ok()
  end

  def apply_operation(game, {:move_checker, _client_id, move}) do
    with true <- valid_checker_move?(game, move) do
      game
      |> with_actions()
      |> move_checker(move)
      |> wrap_ok
    else
      _ -> :error
    end
  end

  def apply_operation(game, {:apply_turn, _client_id}) do
    with true <- game.move_stack in game.valid_turns do
      game
      |> with_actions()
      |> apply_turn()
      |> wrap_ok()
    else
      _ -> :error
    end
  end

  def apply_operation(game, {:set_dice, _client_id, dice_roll}) do
    game
    |> with_actions()
    |> set_dice(dice_roll)
    |> wrap_ok()
  end

  def apply_operation(game, {:client_join, client_id, user}) do
    with false <- Map.has_key?(game.clients_map, client_id) do
      game
      |> with_actions()
      |> client_join(client_id, user)
      |> wrap_ok()
    else
      _ -> :error
    end
  end

  def apply_operation(game, {:client_leave, client_id}) do
    with true <- Map.has_key?(game.clients_map, client_id) do
      game
      |> with_actions()
      |> client_leave(client_id)
      |> wrap_ok()
    else
      _ -> :error
    end
  end

  # ===

  defp with_actions(game, actions \\ []), do: {game, actions}

  defp add_action({game, actions}, action) do
    {game, actions ++ [action]}
  end

  defp wrap_ok({game, actions}), do: {:ok, game, actions}

  defp set!({game, actions}, changes) do
    changes
    |> Enum.reduce(game, fn {key, value}, info ->
      Map.replace!(info, key, value)
    end)
    |> with_actions(actions)
  end

  defp start_game({game, _} = game_actions, start_roll) do
    start_player =
      case start_roll do
        {d1, d2} when d1 > d2 -> :black
        {d1, d2} when d1 < d2 -> :white
      end
    valid_turns = Board.calculate_valid_turns(game.board, start_player, start_roll)

    game_actions
    |> set!(
      game_state: :running,
      current_player: start_player,
      dice_roll: start_roll,
      valid_turns: valid_turns
    )
  end

  defp move_checker({game, _} = game_actions, move) do
    game_actions
    |> set!(move_stack: game.move_stack ++ [move])
  end

  defp apply_turn({game, _} = game_actions) do
    turn = game.move_stack
    opponent = get_opponent(game.current_player)
    new_board = Board.apply_turn(game.board, turn)

    {game_state, game_value} =
      case Board.check_winner(new_board, game.current_player) do
        0 -> {:running, 0}
        game_value -> {:finished, game_value}
      end

    game_actions
    |> set!(
      board: new_board,
      current_player: opponent,
      dice_roll: nil,
      move_stack: [],
      game_state: game_state,
      game_value: game_value
    )
  end

  defp set_dice({game, _} = game_actions, dice_roll) do
    valid_turns = Board.calculate_valid_turns(game.board, game.current_player, dice_roll)

    game_actions
    |> set!(
      dice_roll: dice_roll,
      valid_turns: valid_turns
    )
  end

  defp client_join({game, _} = game_actions, client_id, user) do
    game_actions
    |> set!(
      clients_map: Map.put(game.clients_map, client_id, user.id),
      users_map: Map.put(game.users_map, user.id, user)
    )
  end

  defp client_leave({game, _} = game_actions, client_id) do
    {user_id, clients_map} = Map.pop(game.clients_map, client_id)

    users_map =
      if user_id in Map.values(clients_map) do
        game.users_map
      else
        Map.delete(game.users_map, user_id)
      end

    game_actions
    |> set!(clients_map: clients_map, users_map: users_map)
  end

  # ===

  defp valid_checker_move?(game, move) do
    move_stack = game.move_stack
    num_made_moves = length(move_stack)

    available_moves =
      game.valid_turns
      |> Enum.reduce([], fn turn, acc ->
        if Enum.take(turn, num_made_moves) == move_stack do
          [Enum.at(turn, num_made_moves) | acc]
        else
          acc
        end
      end)

    move in available_moves
  end
end
