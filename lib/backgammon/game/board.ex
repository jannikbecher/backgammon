defmodule Backgammon.Game.Board do
  @moduledoc false

  import Backgammon.Helpers

  @type t :: %{
          (1..24) => list(color()),
          :black_bar => list(:black),
          :white_bar => list(:white),
          :black_bear_off => list(:black),
          :white_bear_off => list(:white)
        }

  @type color :: :black | :white

  @spec new() :: t()
  def new do
    board = for i <- 1..24, into: %{}, do: {i, []}

    %{
      board
      | 1 => new_checker(:black, 2),
        12 => new_checker(:black, 5),
        17 => new_checker(:black, 3),
        19 => new_checker(:black, 5),
        6 => new_checker(:white, 5),
        8 => new_checker(:white, 3),
        13 => new_checker(:white, 5),
        24 => new_checker(:white, 2)
    }
    |> Map.put(:black_bar, [])
    |> Map.put(:white_bar, [])
    |> Map.put(:black_bear_off, [])
    |> Map.put(:white_bear_off, [])
  end

  @spec calculate_valid_turns(t(), color(), list(integer())) :: list()
  def calculate_valid_turns(board, current_player, [step | steps]) do
    valid_moves =
      calculate_valid_moves(board, current_player, step)
      |> Enum.map(&[&1])

    do_calculate_valid_turns(board, current_player, steps, valid_moves)
  end

  @spec apply_turn(t(), list()) :: t()
  def apply_turn(board, []), do: board

  def apply_turn(board, [{from, to} | rest]) do
    board
    |> apply_move({from, to})
    |> apply_turn(rest)
  end

  def do_calculate_valid_turns(_board, _current_player, [], valid_turns), do: valid_turns

  def do_calculate_valid_turns(board, current_player, [step | steps], valid_turns) do
    updated_turns =
      Enum.flat_map(valid_turns, fn moves ->
        board
        |> apply_turn(moves)
        |> calculate_valid_moves(current_player, step)
        |> Enum.map(fn move ->
          moves ++ [move]
        end)
      end)

    do_calculate_valid_turns(board, current_player, steps, updated_turns)
  end

  defp new_checker(color, num), do: Enum.to_list(1..num) |> Enum.map(fn _ -> color end)

  defp apply_move(board, {from, to}) when is_integer(to) and to > 24 do
    apply_move(board, {from, :black_bear_off})
  end

  defp apply_move(board, {from, to}) when is_integer(to) and to < 1 do
    apply_move(board, {from, :white_bear_off})
  end

  defp apply_move(board, {from, to}) do
    [src_color | src_checkers] = board[from]

    {board, dest_checkers} =
      case board[to] do
        [] -> {board, [src_color]}
        [^src_color | _rest] -> {board, [src_color | board[to]]}
        [:black] -> {apply_move(board, {to, :white_bar}), [src_color]}
        [:white] -> {apply_move(board, {to, :black_bar}), [src_color]}
        _ -> raise "Not a valid move"
      end

    %{board | from => src_checkers, to => dest_checkers}
  end

  defp calculate_valid_moves(board, current_player, step) do
    checker_positions = get_checker_positions(board, current_player)

    Enum.reduce(checker_positions, [], fn checker, acc ->
      move = generate_move(current_player, checker, step)

      if valid_move?(board, current_player, move) do
        [move | acc]
      else
        acc
      end
    end)
  end

  defp valid_move?(board, current_player, move) do
    cond do
      checker_on_the_bar?(board, current_player) ->
        valid_bar_move?(board, current_player, move)

      bear_off?(board, current_player) ->
        valid_bear_off_move?(board, current_player, move)

      true ->
        valid_normal_move?(board, current_player, move)
    end
  end

  defp valid_bar_move?(board, :black, {:black_bar, to} = move) when to < 7 do
    valid_normal_move?(board, :black, move)
  end

  defp valid_bar_move?(board, :white, {:white_bar, to} = move) when to > 18 do
    valid_normal_move?(board, :white, move)
  end

  defp valid_bar_move?(_board, _current_player, _move), do: false

  defp valid_bear_off_move?(_board, _current_player, {_from, 25}), do: true

  defp valid_bear_off_move?(_board, _current_player, {_from, 0}), do: true

  defp valid_bear_off_move?(board, :black, {from, _to}) do
    last_checker = get_checker_positions(board, :black) |> Enum.min()
    if last_checker == from, do: true, else: false
  end

  defp valid_bear_off_move?(board, :white, {from, _to}) do
    last_checker = get_checker_positions(board, :white) |> Enum.max()
    if last_checker == from, do: true, else: false
  end

  defp valid_normal_move?(board, current_player, {from, to}) do
    opponent = get_opponent(current_player)

    if board[from] do
      case board[to] do
        [^opponent, ^opponent | _rest] -> false
        nil -> false
        _ -> true
      end
    else
      false
    end
  end

  defp generate_move(:black, checker_position, step),
    do: {checker_position, checker_position + step}

  defp generate_move(:white, checker_position, step),
    do: {checker_position, checker_position - step}

  def get_checker_positions(board, current_player) do
    Enum.reduce(board, [], fn
      {pos, [^current_player | _]}, acc when is_integer(pos) or pos in [:black_bar, :white_bar] ->
        [pos | acc]

      _, acc ->
        acc
    end)
  end

  defp checker_on_the_bar?(board, :black), do: not Enum.empty?(board.black_bar)
  defp checker_on_the_bar?(board, :white), do: not Enum.empty?(board.white_bar)

  defp bear_off?(board, :black) do
    board
    |> get_checker_positions(:black)
    |> Enum.filter(fn
      num when num < 19 -> true
      :black_bar -> true
      _ -> false
    end)
    |> Enum.empty?()
  end

  defp bear_off?(board, :white) do
    board
    |> get_checker_positions(:white)
    |> Enum.filter(fn
      num when num > 6 -> true
      :white_bar -> true
      _ -> false
    end)
    |> Enum.empty?()
  end
end
