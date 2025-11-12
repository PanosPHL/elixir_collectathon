defmodule ElixirCollectathonWeb.GameLive do
  alias ElixirCollectathon.Games.Server, as: GameServer
  use ElixirCollectathonWeb, :live_view

  def mount(%{"id" => game_id}, _session, socket) do
    if GenServer.whereis(GameServer.via_tuple(game_id)) do
      socket =
        assign(socket, game_id: game_id)

      {:ok, socket}
    end

    # Handle redirect to different LiveView if game_id doesn't exist as a GenServer process
  end
end
