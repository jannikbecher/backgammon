defmodule Backgammon.Game do
  @moduledoc false

  defstruct [
    :board,
    :current_player,
    :dice_roll,
    :game_state
  ]

  alias Backgammon.Game
  alias Backgammon.Game.Board

  import Backgammon.Helpers

  @type t :: %Game{
          board: Board.t(),
          current_player: :black | :white | nil,
          dice_roll: {1..6, 1..6} | nil,
          game_state: :running | :finished
        }

  @type from :: 1..24 | :bar
  @type to :: 1..24 | :bear_off

  @type checker_move :: {from(), to()}

  @type action ::
          :start_game
          | :end_turn
          | {:turn, list(checker_move)}

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %Game{
      board: Board.new(),
      current_player: nil,
      dice_roll: nil
    }
  end

  def simulate do
    game =
      new()
      |> apply_action(:start_game)

    action =
      get_available_actions(game)
      |> hd()

    do_simulate(game, action)
  end

  defp do_simulate(game, action) do
    game = apply_action(game, action)
    IO.inspect(action)

    action =
      get_available_actions(game)
      |> hd()

    do_simulate(game, action)
  end

  @spec roll_dice(t()) :: t()
  def roll_dice(game) do
    %Game{game | dice_roll: do_roll_dice()}
  end

  defp do_roll_dice do
    {:rand.uniform(6), :rand.uniform(6)}
  end

  @spec get_available_actions(t()) :: list(action())
  def get_available_actions(%Game{dice_roll: nil}), do: [:start_game]

  def get_available_actions(%Game{
        board: board,
        current_player: current_player,
        dice_roll: dice_roll
      }) do
    case dice_roll do
      {double, double} ->
        Board.calculate_valid_turns(board, current_player, [double, double, double, double])
        |> Enum.map(&{:turn, &1})

      {dice1, dice2} ->
        list1 = Board.calculate_valid_turns(board, current_player, [dice1, dice2])
        list2 = Board.calculate_valid_turns(board, current_player, [dice2, dice1])

        Enum.concat(list1, list2)
        |> Enum.map(&{:turn, &1})
    end
  end

  @spec apply_action(t(), action()) :: {:ok, t()} | :error
  def apply_action(%Game{board: board, current_player: current_player} = game, {:turn, moves}) do
    # TODO handle invalid moves
    opponent = get_opponent(current_player)
    new_board = Board.apply_turn(board, moves)

    if length(new_board.black_bear_off) == 15 do
      IO.inspect(game)
      raise "Black won"
    end

    if length(new_board.white_bear_off) == 15 do
      IO.inspect(game)
      raise "White won"
    end

    %Game{game | board: new_board, current_player: opponent}
  end

  def apply_action(%Game{} = game, :start_game) do
    {start_player, start_roll} = get_start_roll()
    %Game{game | current_player: start_player, dice_roll: start_roll}
  end

  defp get_start_roll() do
    case do_roll_dice() do
      {d, d} -> get_start_roll()
      {d1, d2} when d1 > d2 -> {:black, {d1, d2}}
      {d1, d2} when d1 < d2 -> {:white, {d1, d2}}
    end
  end
end
