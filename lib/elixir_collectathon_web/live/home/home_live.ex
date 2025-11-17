defmodule ElixirCollectathonWeb.HomeLive do
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer
  alias ElixirCollectathonWeb.Routes, as: Routes
  use ElixirCollectathonWeb, :live_view

  attr :icon_name, :string, required: true
  slot :header, required: true
  slot :inner_block, required: true

  def feature_card(assigns) do
    ~H"""
    <div class="p-6 rounded-lg bg-[#3e4451] border border-gray-700 shadow-xl">
      <.icon class="size-8 mb-2" name={@icon_name} />
      <h4 class="text-xl font-semibold text-white mb-2">{render_slot(@header)}</h4>
      <p class="text-gray-400 text-sm">
        {render_slot(@inner_block)}
      </p>
    </div>
    """
  end

  slot :header, required: true
  slot :inner_block, required: true

  def how_to_play_card(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row items-start md:space-x-8 p-6 rounded-xl bg-[#1e2229] shadow-xl">
      <div>
        <h4 class="text-2xl font-semibold text-white mb-2">{render_slot(@header)}</h4>
        <p class="text-gray-400">{render_slot(@inner_block)}</p>
      </div>
    </div>
    """
  end

  def mount(_, _, socket) do
    socket =
      socket
      |> assign(
        create_game_form: to_form(%{}),
        join_game_form: to_form(%{"player_name" => "", "game_id" => ""})
      )

    {:ok, socket}
  end

  def handle_event("create_game", _unsigned_params, socket) do
    case GameSupervisor.create_game() do
      {:ok, game_id} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "Game successfully created")
          |> push_navigate(to: Routes.game(game_id))
        }

      {:error, :max_retries} ->
        {:noreply,
         socket
         |> put_flash(:error, "There was an issue creating a game, try again later.")}
    end
  end

  def handle_event(
        "join_game",
        %{"game_id" => game_id, "player_name" => player_name} = params,
        socket
      ) do
    # Game does not exist with given ID
    if is_nil(GenServer.whereis(GameServer.via_tuple(game_id))) do
      errors = [game_id: {"No game exists with this ID", []}]

      {
        :noreply,
        socket
        |> assign(:join_game_form, to_form(params, errors: errors))
      }
    else
      case GenServer.call(GameServer.via_tuple(game_id), {:join, player_name}) do
        # Player successfully joined game
        :ok ->
          {
            :noreply,
            socket
            |> push_navigate(to: Routes.controller(game_id, player_name))
          }

        # Game already has 4 players
        {:error, :max_players_reached} ->
          {
            :noreply,
            socket
            |> put_flash(:error, "There are already four players in this game")
          }

        # Game already has player of submitted name
        {:error, :already_added} ->
          errors = [player_name: {"A player with this name already exists in this game", []}]

          {
            :noreply,
            socket
            |> assign(:join_game_form, to_form(params, errors: errors))
          }

        # Catch all error
        _ ->
          {
            :noreply,
            socket
            |> put_flash(:error, "There was an issue joining this game, please try again later.")
          }
      end
    end
  end
end
