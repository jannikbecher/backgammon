defmodule BackgammonWeb.BoardComponents do
  @moduledoc """
  Provides Backgammon board UI components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import BackgammonWeb.Gettext

  @doc """

  """
  attr :color, :atom, values: [:black, :white], required: true

  def checker(assigns) do
    ~H"""
    <%= if @color == :black do %>
      <div class="w-10 h-10 rounded-full bg-black" />
    <% else %>
      <div class="w-10 h-10 rounded-full bg-white" />
    <% end %>
    """
  end
end
