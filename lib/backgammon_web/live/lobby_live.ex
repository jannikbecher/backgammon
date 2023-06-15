defmodule BackgammonWeb.LobbyLive do
  use BackgammonWeb, :live_view

  alias Backgammon.{Games}

  @impl true
  def mount(_params, _session, socket) do
    games = Backgammon.Tracker.list_games() |> Enum.reverse()

    {:ok, assign(socket, games: games)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col aspect-square items-center justify-center bg-red-400">
      <div>
        <.button phx-click="create_game">Create Game</.button>
      </div>
      <div>
        <p :for={game <- @games}><.link navigate={~p"/games/#{game.id}"}><%= game.id %></.link></p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("create_game", _params, socket) do
    {:ok, game} = Games.create_game()
    {:noreply, assign(socket, games: [game | socket.assigns.games])}
  end
end
