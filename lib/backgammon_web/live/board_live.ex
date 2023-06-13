defmodule BackgammonWeb.BoardLive do
  use BackgammonWeb, :live_view

  import BackgammonWeb.BoardComponents

  alias Backgammon.Server

  @impl true
  def mount(_params, _session, socket) do
    {:ok, game} = Server.start_link([])
    state = Server.get_current_state(game)
    available_actions = Server.get_available_actions(game)

    {:ok,
     socket
     |> assign(
       game: game,
       board: state.board,
       current_player: state.current_player,
       dice_roll: state.dice_roll,
       available_actions: available_actions,
       move_stack: []
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Container for the board -->
    <div class="grid grid-cols-[1.5fr_6fr_1fr_6fr_1.5fr] grid-rows-[5fr_1fr_5fr] bg-gray-300">
      <!-- left -->
      <div class="col-start-1 col-end-2 row-start-1 row-end-4">
        <div class="grid grid-rows-3 h-full items-center">
          <div class="row-span-1">
            Score white
          </div>
          <div class="row-span-1">
            Time
          </div>
          <div class="row-span-1">
            Score Black
          </div>
        </div>
      </div>
      <!-- middle -->
      <div class="col-start-3 col-end-4 row-start-1 row-end-4">
        <div class="grid grid-rows-5 h-full items-center">
          <div class="row-start-1">
            White pips
          </div>
          <div id="white-bar" class="row-start-2" phx-hook="Sortable">
            <.bg_checker :for={checker <- @board[:white_bar]} color={checker} />
          </div>
          <div id="black-bar" class="row-start-4" phx-hook="Sortable">
            <.bg_checker :for={checker <- @board[:black_bar]} color={checker} />
          </div>
          <div class="row-start-5">
            Black pips
          </div>
        </div>
      </div>
      <div class="col-start-2 col-end-5 row-start-2 row-end-3">
        <div class="grid grid-cols-3 h-full w-full place-content-center">
          <div
            :if={@current_player == :white and @dice_roll != nil}
            class="col-start-1 text-center"
            phx-click="end_turn"
          >
            <.bg_two_dice numbers={@dice_roll} />
          </div>
          <div class="col-start-2 text-center">
            <button
              :if={@available_actions == [:start_game]}
              phx-click={JS.push("action_clicked", value: %{index: 0})}
            >
              Start Game
            </button>
            <button
              :if={@available_actions == [:roll_dice]}
              phx-click={JS.push("action_clicked", value: %{index: 0})}
            >
              Roll Dice
            </button>
          </div>
          <div
            :if={@current_player == :black and @dice_roll != nil}
            class="col-start-3 text-center"
            phx-click="end_turn"
          >
            <.bg_two_dice numbers={@dice_roll} />
          </div>
        </div>
      </div>
      <!-- right -->
      <div id="black-bear-off" class="col-start-5 col-end-6 row-start-1 row-end-1" phx-hook="Sortable">
        <.bg_checker :for={checker <- @board[:black_bear_off]} color={checker} />
      </div>
      <div id="white-bear-off" class="col-start-5 col-end-6 row-start-3 row-end-4" phx-hook="Sortable">
        <.bg_checker :for={checker <- @board[:white_bear_off]} color={checker} />
      </div>
      <!-- Outer Black -->
      <div class="col-start-2 col-end-3 row-start-1 row-end-2">
        <div class="grid grid-cols-6">
          <.bg_point id="p13" direction="down" color="red" checkers={@board[13]} />
          <.bg_point id="p14" direction="down" color="blue" checkers={@board[14]} />
          <.bg_point id="p15" direction="down" color="red" checkers={@board[15]} />
          <.bg_point id="p16" direction="down" color="blue" checkers={@board[16]} />
          <.bg_point id="p17" direction="down" color="red" checkers={@board[17]} />
          <.bg_point id="p18" direction="down" color="blue" checkers={@board[18]} />
        </div>
      </div>
      <!-- Home Black -->
      <div class="col-start-4 col-end-5 row-start-1 row-end-2">
        <div class="grid grid-cols-6">
          <.bg_point id="p19" direction="down" color="red" checkers={@board[19]} />
          <.bg_point id="p20" direction="down" color="blue" checkers={@board[20]} />
          <.bg_point id="p21" direction="down" color="red" checkers={@board[21]} />
          <.bg_point id="p22" direction="down" color="blue" checkers={@board[22]} />
          <.bg_point id="p23" direction="down" color="red" checkers={@board[23]} />
          <.bg_point id="p24" direction="down" color="blue" checkers={@board[24]} />
        </div>
      </div>
      <!-- Outer White -->
      <div class="col-start-2 col-end-3 row-start-3 row-end-4">
        <div class="grid grid-cols-6">
          <.bg_point id="p12" direction="up" color="blue" checkers={@board[12]} />
          <.bg_point id="p11" direction="up" color="red" checkers={@board[11]} />
          <.bg_point id="p10" direction="up" color="blue" checkers={@board[10]} />
          <.bg_point id="p9" direction="up" color="red" checkers={@board[9]} />
          <.bg_point id="p8" direction="up" color="blue" checkers={@board[8]} />
          <.bg_point id="p7" direction="up" color="red" checkers={@board[7]} />
        </div>
      </div>
      <!-- Home White -->
      <div class="col-start-4 col-end-5 row-start-3 row-end-4">
        <div class="grid grid-cols-6">
          <.bg_point id="p6" direction="up" color="blue" checkers={@board[6]} />
          <.bg_point id="p5" direction="up" color="red" checkers={@board[5]} />
          <.bg_point id="p4" direction="up" color="blue" checkers={@board[4]} />
          <.bg_point id="p3" direction="up" color="red" checkers={@board[3]} />
          <.bg_point id="p2" direction="up" color="blue" checkers={@board[2]} />
          <.bg_point id="p1" direction="up" color="red" checkers={@board[1]} />
        </div>
      </div>
    </div>
    """
  end

  def handle_event("action_clicked", %{"index" => index} = params, socket) do
    game = socket.assigns.game
    action = Server.get_available_actions(game) |> Enum.at(index)

    {:noreply, apply_action(socket, action)}
  end

  def handle_event("move_checker", %{"from" => from, "to" => to} = params, socket) do
    from = parse_id(from)
    to = parse_id(to)
    new_move_stack = socket.assigns.move_stack ++ [{from, to}]

    {:noreply, assign(socket, move_stack: new_move_stack)}
  end

  defp parse_id("black-bar"), do: :black_bar
  defp parse_id("white-bar"), do: :white_bar
  defp parse_id("black-bear-off"), do: :black_bear_off
  defp parse_id("white-bear-off"), do: :white_bear_off
  defp parse_id("p" <> point), do: String.to_integer(point)

  def handle_event("end_turn", _params, socket) do
    turn = {:turn, socket.assigns.move_stack}
    available_actions = socket.assigns.available_actions

    valid_move? = Enum.find(available_actions, &(&1 == turn))

    if valid_move? do
      {:noreply,
       socket
       |> apply_action(turn)
       |> assign(move_stack: [])}
    else
      # TODO handle unallowed turns correctly
      {:noreply, socket}
    end
  end

  defp apply_action(socket, action) do
    game = socket.assigns.game
    {:ok, game_state} = Server.apply_action(game, action)
    available_actions = Server.get_available_actions(game)

    socket
    |> assign(
      board: game_state.board,
      current_player: game_state.current_player,
      dice_roll: game_state.dice_roll,
      available_actions: available_actions
    )
  end
end
