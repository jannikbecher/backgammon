defmodule BackgammonWeb.BoardComponents do
  @moduledoc """
  Provides Backgammon board UI components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """

  """
  attr :color, :atom, values: [:black, :white], required: true
  attr :class, :string, default: ""

  def bg_checker(assigns) do
    ~H"""
    <div class={"#{@class} w-9 h-9 rounded-full bg-#{if @color == :black, do: "black", else: "white"} focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400
          drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
          drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"} />
    """
  end

  @doc """

  """
  attr :id, :string, required: true
  attr :direction, :string, required: true
  attr :color, :string, required: true
  attr :checkers, :list

  def bg_point(assigns) do
    ~H"""
    <div class="relative overflow-hidden h-48">
      <div class={"absolute inset-0 triangle-#{@direction} bg-#{@color}-500 z-0"} />
      <div
        id={@id}
        class={"absolute inset-0 flex flex-col z-10 #{if @direction == "up", do: "justify-end"} items-center"}
        phx-hook="Sortable"
      >
        <.bg_checker :for={color <- @checkers} color={color} />
      </div>
    </div>
    """
  end

  @doc """

  """
  attr :number, :integer, required: true

  def bg_dice(assigns) do
    ~H"""
    <span class="text-2xl">
      <%= get_dice_unicode(@number) %>
    </span>
    """
  end

  @doc """

  """
  attr :numbers, :any, required: true

  def bg_two_dice(assigns) do
    ~H"""
    <span class="text-2xl">
      <%= get_dice_unicode(elem(@numbers, 0)) %>
      <%= get_dice_unicode(elem(@numbers, 1)) %>
    </span>
    """
  end

  defp get_dice_unicode(number) do
    case number do
      1 -> <<9856::utf8>>
      2 -> <<9857::utf8>>
      3 -> <<9858::utf8>>
      4 -> <<9859::utf8>>
      5 -> <<9860::utf8>>
      6 -> <<9861::utf8>>
    end
  end
end
