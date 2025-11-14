defmodule ElixirCollectathonWeb.ControllerLive do
  alias ElixirCollectathon.Games.Server, as: GameServer
  use ElixirCollectathonWeb, :live_view

  def mount(%{"player" => player_name, "game_id" => game_id}, _session, socket) do
    {:ok, assign(socket, player_name: player_name, game_id: game_id)}
  end

  def handle_event("joystick_move", %{"x" => x, "y" => y}, socket) do
    %{game_id: game_id, player_name: player_name} = socket.assigns

    GameServer.update_velocity(game_id, player_name, {x, y})

    {:noreply, socket}
  end
end
