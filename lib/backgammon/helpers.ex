defmodule Backgammon.Helpers do
  @moduledoc false

  def get_opponent(:black), do: :white
  def get_opponent(:white), do: :black
end
