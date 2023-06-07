defmodule Backgammon.ServerTest do
  use ExUnit.Case

  alias Backgammon.Server

  def simulate do
    {:ok, game} = Server.start_link([])
    do_simulate(game, :running, 0)
  end

  defp do_simulate(_game, :finished, value), do: value

  defp do_simulate(game, state, _value) do
    action = Server.get_available_actions(game) |> Enum.random()
    {:ok, _, game_state, game_value} = Server.apply_action(game, action)
    do_simulate(game, game_state, game_value)
  end

  test "run 1000 games" do
    batch_size = div(1000, 8)
    for _ <- 1..8 do
      Task.async(fn ->
        for _ <- 1..batch_size do
          simulate()
        end
      end)
    end
    |> Task.await_many(:infinity)
    |> List.flatten()
    |> Enum.sum()
    |> IO.inspect()
  end
end
