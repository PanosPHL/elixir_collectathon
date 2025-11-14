defmodule ElixirCollectathonWeb.HomeLive do
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer
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
      assign(socket, create_game_form: %{}, join_game_form: %{})

    {:ok, socket}
  end

  def handle_event("create_game", _unsigned_params, socket) do
    {:ok, game_id} = GameSupervisor.create_game()

    {:noreply, push_navigate(socket, to: ~p"/game/#{game_id}")}
  end

  def handle_event("join_game", %{"game_id" => game_id, "player_name" => player_name}, socket) do
    case GenServer.call(GameServer.via_tuple(game_id), {:join, player_name}) do
      :ok ->
        {:noreply, push_navigate(socket, to: ~p"/controller/#{game_id}?player=#{player_name}")}

      # TO DO: Handle unhappy paths
      # 1. Game does not exist
      # 2. Player name already exists
      # 3. Other issue joining game
      _ ->
        {:noreply, socket}
    end
  end
end
