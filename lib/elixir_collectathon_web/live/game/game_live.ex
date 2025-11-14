defmodule ElixirCollectathonWeb.GameLive do
  alias Phoenix.PubSub
  alias ElixirCollectathon.Games.Server, as: GameServer
  use ElixirCollectathonWeb, :live_view

  def mount(%{"id" => game_id}, _session, socket) do
    case GenServer.whereis(GameServer.via_tuple(game_id)) do
      nil ->
        # TO DO: Handle redirect to different LiveView if a GenServer process with the associated game_id doesn't
        # exist
        {:ok, socket}

      _ ->
        if connected?(socket),
          do: PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

        {:ok, assign(socket, game_id: game_id)}
    end
  end

  def handle_info({:state, state}, socket) do
    {:noreply, push_event(socket, "game_update", state)}
  end
end
