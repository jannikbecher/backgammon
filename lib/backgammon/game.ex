defmodule Backgammon.Game do
  @moduledoc false

  defstruct [
    :board,
    :current_player,
    :dice_roll,
    :game_state,
    :game_value
  ]

  alias Backgammon.Game
  alias Backgammon.Game.Board

  import Backgammon.Helpers

  @type t :: %Game{
          board: Board.t(),
          current_player: :black | :white | nil,
          dice_roll: {1..6, 1..6} | nil,
          game_state: :ready | :running | :finished,
          game_value: -3..3
        }

  @type from :: 1..24 | :bar
  @type to :: 1..24 | :bear_off

  @type checker_move :: {from(), to()}

  @type action ::
          :start_game
          | :end_turn
          | {:turn, list(checker_move)}
          | :roll_dice
          | :no_valid_turn

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %Game{
      board: Board.new(),
      current_player: nil,
      dice_roll: nil,
      game_state: :ready,
      game_value: 0
    }
  end

  @spec get_available_actions(t()) :: list(action())
  def get_available_actions(%Game{game_state: :ready}), do: [:start_game]

  def get_available_actions(%Game{dice_roll: nil}), do: [:roll_dice]

  def get_available_actions(%Game{
        board: board,
        current_player: current_player,
        dice_roll: dice_roll
      }) do
    valid_turns =
      Board.calculate_valid_turns(board, current_player, dice_roll)
      |> Enum.map(&{:turn, &1})

    if Enum.empty?(valid_turns) do
      [:no_valid_turn]
    else
      valid_turns
    end
  end

  @spec apply_action(t(), action()) :: {:ok, t()} | :error
  # TODO handle invalid moves
  def apply_action(%Game{board: board, current_player: current_player} = game, {:turn, moves}) do
    opponent = get_opponent(current_player)
    new_board = Board.apply_turn(board, moves)

    case Board.check_winner(new_board, current_player) do
      0 ->
        %Game{game | board: new_board, current_player: opponent, dice_roll: nil}

      game_value ->
        %Game{game | board: new_board, game_state: :finished, game_value: game_value}
    end
  end

  def apply_action(%Game{} = game, :start_game) do
    {start_player, start_roll} = get_start_roll()
    %Game{game | game_state: :running, current_player: start_player, dice_roll: start_roll}
  end

  def apply_action(%Game{} = game, :roll_dice) do
    %Game{game | dice_roll: do_roll_dice()}
  end

  def apply_action(%Game{current_player: current_player} = game, :no_valid_turn) do
    %Game{game | current_player: get_opponent(current_player), dice_roll: do_roll_dice()}
  end

  defp get_start_roll() do
    case do_roll_dice() do
      {d, d} -> get_start_roll()
      {d1, d2} when d1 > d2 -> {:black, {d1, d2}}
      {d1, d2} when d1 < d2 -> {:white, {d1, d2}}
    end
  end

  defp do_roll_dice do
    {:rand.uniform(6), :rand.uniform(6)}
  end
end
