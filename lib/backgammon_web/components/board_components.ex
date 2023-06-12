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
      <div class="w-10 h-10 rounded-full bg-black focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400
          drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
          drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0" />
    <% else %>
      <div class="w-10 h-10 rounded-full bg-white focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400
          drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
          drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0" />
    <% end %>
    """
  end
end
