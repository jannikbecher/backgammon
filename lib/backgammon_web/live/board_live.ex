defmodule BackgammonWeb.BoardLive do
  use BackgammonWeb, :live_view

  alias Backgammon.{Server, Games, Game}

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    case Games.fetch_game(game_id) do
      {:ok, %{pid: game_pid}} ->
        {game_data, client_id} =
          if connected?(socket) do
            {game_data, client_id} =
              Server.register_client(game_pid, self(), %{id: 1, name: "Test User"})

            Server.subscribe(game_id)

            {game_data, client_id}
          else
            game_data = Server.get_game(game_pid)
            {game_data, nil}
          end

        game = Server.get_by_pid(game_pid)

        {:ok,
         socket
         |> assign(
           game: game,
           client_id: client_id,
           data_view: data_to_view(game_data)
         )
         |> assign_private(data: game_data)}

      :error ->
        {:ok, redirect(socket, to: ~p"/")}
    end
  end

  # Puts the given assigns in `socket.private`,
  # to ensure they are not used for rendering.
  defp assign_private(socket, assigns) do
    Enum.reduce(assigns, socket, fn {key, value}, socket ->
      put_in(socket.private[key], value)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container w-full aspect-[16/9]">
      <div class="bg-red-500 triangle-up h-4" />
      <div class="bg-black triangle-up h-4" />
      <!-- Container for the board -->
      <div class="grid grid-cols-[1.5fr_6fr_1fr_6fr_1.5fr] grid-rows-[5fr_1fr_5fr] bg-gray-300 h-full">
        <!-- left -->
        <div class="col-start-1 col-end-2 row-start-1 row-end-4">
          <div class="grid grid-rows-3 place-items-center h-full">
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
          <div class="grid grid-rows-5 place-items-center h-full">
            <div class="row-start-1">
              White pips
            </div>
            <div id="white-bar" class="relative row-start-2" phx-hook="Sortable">
              <.bg_checker
                :for={checker <- @data_view.board[:white_bar]}
                class="absolute"
                color={checker}
              />
            </div>
            <div id="black-bar" class="relative row-start-4" phx-hook="Sortable">
              <.bg_checker
                :for={checker <- @data_view.board[:black_bar]}
                class="absolute"
                color={checker}
              />
            </div>
            <div class="row-start-5">
              Black pips
            </div>
          </div>
        </div>
        <div class="col-start-2 col-end-5 row-start-2 row-end-3">
          <div class="grid grid-cols-3 place-items-center h-full">
            <div
              :if={@data_view.current_player == :white and @data_view.dice_roll != nil}
              class="col-start-1"
              phx-click="end_turn"
            >
              <.bg_two_dice numbers={@data_view.dice_roll} />
            </div>
            <div class="col-start-2 self-center">
              <div class="box-border h-8 w-8 bg-red-500" />
            </div>
            <div
              :if={@data_view.current_player == :black and @data_view.dice_roll != nil}
              class="col-start-3"
              phx-click="end_turn"
            >
              <.bg_two_dice numbers={@data_view.dice_roll} />
            </div>
          </div>
        </div>
        <!-- right -->
        <div class="col-start-5 col-end-6 row-start-1 row-end-4">
          <div class="grid grid-rows-3 place-items-center h-full">
            <div id="black-bear-off" class="row-start-1 bg-gray-500 w-full h-full" phx-hook="Sortable">
              <.bg_checker :for={checker <- @data_view.board[:black_bear_off]} color={checker} />
            </div>
            <div class="row-start-2">
              <.button :if={@data_view.game_state == :ready} phx-click="start_game">
                Start
              </.button>
              <.button
                :if={@data_view.game_state == :running and @data_view.dice_roll == nil}
                phx-click="roll_dice"
              >
                Roll Dice
              </.button>
              <.button
                :if={@data_view.game_state == :running and @data_view.dice_roll != nil}
                phx-click="cancel_moves"
              >
                Cancel
              </.button>
            </div>
            <div id="white-bear-off" class="row-start-3 bg-gray-500 w-full h-full" phx-hook="Sortable">
              <.bg_checker :for={checker <- @data_view.board[:white_bear_off]} color={checker} />
            </div>
          </div>
        </div>
        <!-- Outer Black -->
        <div class="col-start-2 col-end-3 row-start-1 row-end-2">
          <div class="grid grid-cols-6 h-full">
            <.bg_point id="p13" direction="down" color="red" checkers={@data_view.board[13]} />
            <.bg_point id="p14" direction="down" color="blue" checkers={@data_view.board[14]} />
            <.bg_point id="p15" direction="down" color="red" checkers={@data_view.board[15]} />
            <.bg_point id="p16" direction="down" color="blue" checkers={@data_view.board[16]} />
            <.bg_point id="p17" direction="down" color="red" checkers={@data_view.board[17]} />
            <.bg_point id="p18" direction="down" color="blue" checkers={@data_view.board[18]} />
          </div>
        </div>
        <!-- Home Black -->
        <div class="col-start-4 col-end-5 row-start-1 row-end-2">
          <div class="grid grid-cols-6 h-full">
            <.bg_point id="p19" direction="down" color="red" checkers={@data_view.board[19]} />
            <.bg_point id="p20" direction="down" color="blue" checkers={@data_view.board[20]} />
            <.bg_point id="p21" direction="down" color="red" checkers={@data_view.board[21]} />
            <.bg_point id="p22" direction="down" color="blue" checkers={@data_view.board[22]} />
            <.bg_point id="p23" direction="down" color="red" checkers={@data_view.board[23]} />
            <.bg_point id="p24" direction="down" color="blue" checkers={@data_view.board[24]} />
          </div>
        </div>
        <!-- Outer White -->
        <div class="col-start-2 col-end-3 row-start-3 row-end-4">
          <div class="grid grid-cols-6 h-full">
            <.bg_point id="p12" direction="up" color="blue" checkers={@data_view.board[12]} />
            <.bg_point id="p11" direction="up" color="red" checkers={@data_view.board[11]} />
            <.bg_point id="p10" direction="up" color="blue" checkers={@data_view.board[10]} />
            <.bg_point id="p9" direction="up" color="red" checkers={@data_view.board[9]} />
            <.bg_point id="p8" direction="up" color="blue" checkers={@data_view.board[8]} />
            <.bg_point id="p7" direction="up" color="red" checkers={@data_view.board[7]} />
          </div>
        </div>
        <!-- Home White -->
        <div class="col-start-4 col-end-5 row-start-3 row-end-4">
          <div class="grid grid-cols-6 h-full">
            <.bg_point id="p6" direction="up" color="blue" checkers={@data_view.board[6]} />
            <.bg_point id="p5" direction="up" color="red" checkers={@data_view.board[5]} />
            <.bg_point id="p4" direction="up" color="blue" checkers={@data_view.board[4]} />
            <.bg_point id="p3" direction="up" color="red" checkers={@data_view.board[3]} />
            <.bg_point id="p2" direction="up" color="blue" checkers={@data_view.board[2]} />
            <.bg_point id="p1" direction="up" color="red" checkers={@data_view.board[1]} />
          </div>
        </div>
      </div>
      <div class="bg-black triangle-down h-4" />
      <div class="bg-blue-500 triangle-down h-4" />
    </div>
    """
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    Server.start_game(socket.assigns.game.pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("end_turn", _params, socket) do
    Server.apply_turn(socket.assigns.game.pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("roll_dice", _params, socket) do
    Server.roll_dice(socket.assigns.game.pid)
    {:noreply, socket}
  end

  @impl true
  def handle_event("move_checker", %{"from" => from, "to" => to}, socket) do
    from = parse_id(from)
    to = parse_id(to)
    Server.move_checker(socket.assigns.game.pid, {from, to})
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_moves", _params, socket) do
    Server.cancel_moves(socket.assigns.game.pid)
    {:noreply, socket}
  end

  # ===

  @impl true
  def handle_info({:operation, operation}, socket) do
    {:noreply, handle_operation(socket, operation)}
  end

  @impl true
  def handle_info({:error, error}, socket) do
    message = error |> to_string()

    {:noreply, put_flash(socket, :error, message)}
  end

  @impl true
  def handle_info({:game_updated, game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_info(:game_closed, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Game has been closed")
     |> push_navigate(to: ~p"/")}
  end

  # ===

  defp handle_operation(socket, operation) do
    case Game.apply_operation(socket.private.data, operation) do
      {:ok, game, actions} ->
        socket
        |> assign_private(data: game)
        |> assign(
          data_view:
            update_data_view(socket.assigns.data_view, socket.private.data, game, operation)
        )
        |> after_operation(socket, operation)
        |> handle_actions(actions)

      :error ->
        socket
    end
  end

  defp after_operation(socket, _prev_socket, {:client_join, _client_id, user}) do
    push_event(socket, "client_joined", %{client: user})
  end

  defp after_operation(socket, _prev_socket, {:client_leave, client_id}) do
    push_event(socket, "client_left", %{client_id: client_id})
  end

  defp after_operation(socket, _pref_socket, {:cancel_moves, _client_id}) do
    push_event(socket, "reload", %{})
  end

  defp after_operation(socket, _prev_socket, _operation), do: socket

  defp handle_actions(socket, actions) do
    Enum.reduce(actions, socket, &handle_action(&2, &1))
  end

  defp handle_action(socket, _action), do: socket

  defp update_data_view(_data_view, _prev_data, game, operation) do
    case operation do
      _ -> data_to_view(game)
    end
  end

  # ===

  defp parse_id("black-bar"), do: :black_bar
  defp parse_id("white-bar"), do: :white_bar
  defp parse_id("black-bear-off"), do: :black_bear_off
  defp parse_id("white-bear-off"), do: :white_bear_off
  defp parse_id("p" <> point), do: String.to_integer(point)

  defp data_to_view(game) do
    %{
      board: game.board,
      current_player: game.current_player,
      dice_roll: game.dice_roll,
      valid_turns: game.valid_turns,
      game_state: game.game_state,
      game_value: game.game_value
    }
  end
end
