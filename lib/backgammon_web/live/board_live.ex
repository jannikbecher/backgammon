defmodule BackgammonWeb.BoardLive do
  use BackgammonWeb, :live_view

  import BackgammonWeb.BoardComponents

  alias Backgammon.Server

  @impl true
  def mount(_params, _session, socket) do
    {:ok, game} = Server.start_link([])
    state = Server.get_current_state(game)

    {:ok,
     socket
     |> assign(
       game: game,
       board: state.board,
       current_player: state.current_player,
       dice_roll: state.dice_roll
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <button phx-click="random_action">Random Action</button>
    <div class="container">
      <div class="gameBoard">
        <div id="outerBoard" class="bg-green-100" />
        <div id="p7" class="flex flex-col justify-end bg-blue-400">
          <%= for color <- @board[7] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p8" class="flex flex-col justify-end bg-blue-400">
          <%= for color <- @board[8] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p9" class="flex flex-col justify-end bg-blue-400">
          <%= for color <- @board[9] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p10" class="flex flex-col justify-end bg-blue-400">
          <%= for color <- @board[10] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p11" class="flex flex-col justify-end bg-blue-400">
          <%= for color <- @board[11] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p12" class="flex flex-col justify-end bg-blue-400">
          <%= for color <- @board[12] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p13" class="flex flex-col justify-start bg-blue-400">
          <%= for color <- @board[13] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p14" class="flex flex-col justify-start bg-blue-400">
          <%= for color <- @board[14] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p15" class="flex flex-col justify-start bg-blue-400">
          <%= for color <- @board[15] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p16" class="flex flex-col justify-start bg-blue-400">
          <%= for color <- @board[16] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p17" class="flex flex-col justify-start bg-blue-400">
          <%= for color <- @board[17] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p18" class="flex flex-col justify-start bg-blue-400">
          <%= for color <- @board[18] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="homeBoard" class="bg-green-200" />
        <div id="p1" class="flex flex-col justify-end bg-blue-200">
          <%= for color <- @board[1] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p2" class="flex flex-col justify-end bg-blue-200">
          <%= for color <- @board[2] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p3" class="flex flex-col justify-end bg-blue-200">
          <%= for color <- @board[3] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p4" class="flex flex-col justify-end bg-blue-200">
          <%= for color <- @board[4] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p5" class="flex flex-col justify-end bg-blue-200">
          <%= for color <- @board[5] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p6" class="flex flex-col justify-end bg-blue-200">
          <%= for color <- @board[6] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p19" class="flex flex-col justify-start bg-blue-200">
          <%= for color <- @board[19] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p20" class="flex flex-col justify-start bg-blue-200">
          <%= for color <- @board[20] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p21" class="flex flex-col justify-start bg-blue-200">
          <%= for color <- @board[21] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p22" class="flex flex-col justify-start bg-blue-200">
          <%= for color <- @board[22] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p23" class="flex flex-col justify-start bg-blue-200">
          <%= for color <- @board[23] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="p24" class="flex flex-col justify-start bg-blue-200">
          <%= for color <- @board[24] do %>
            <.checker color={color} />
          <% end %>
        </div>
        <div id="blackInfo">
          <%= if @current_player == :black do %>
            <%= inspect(@dice_roll) %>
          <% end %>
        </div>
        <div id="whiteInfo">
          <%= if @current_player == :white do %>
            <%= inspect(@dice_roll) %>
          <% end %>
        </div>
        <div id="whiteScore"></div>
        <div id="blackScore"></div>
        <div id="timer"></div>
        <div id="double"></div>
        <div id="whiteRun"></div>
        <div id="blackRun"></div>
        <div id="settings"></div>
        <div id="blackBear"></div>
        <div id="whiteBear"></div>
        <div id="blackBar" class="bg-green-400">
          <%= if not Enum.empty?(@board[:black_bar]) do %>
            <.checker color={:black} />
          <% end %>
        </div>
        <div id="whiteBar" class="bg-green-400">
          <%= if not Enum.empty?(@board[:white_bar]) do %>
            <.checker color={:white} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("random_action", _params, socket) do
    game = socket.assigns.game
    action = Server.get_available_actions(game) |> Enum.random()
    {:ok, game_state} = Server.apply_action(game, action)

    {:noreply,
     socket
     |> assign(
       board: game_state.board,
       current_player: game_state.current_player,
       dice_roll: game_state.dice_roll
     )}
  end
end
