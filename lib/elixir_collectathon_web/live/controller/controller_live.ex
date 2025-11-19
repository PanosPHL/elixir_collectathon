defmodule ElixirCollectathonWeb.ControllerLive do
  @moduledoc """
  LiveView for the game controller interface.

  This LiveView provides:
  - A joystick/control interface for players to move their character
  - Real-time velocity updates sent to the game server
  - Player-specific view showing controls for the joined player

  Players use this view to control their character in the game.
  """
  alias ElixirCollectathon.Games.Server, as: GameServer
  use ElixirCollectathonWeb, :live_view

  @doc """
  Mounts the LiveView with the game ID and player name from the session.

  The player name is retrieved from the session set by the GameController
  when the player successfully joins a game.
  """

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(%{"game_id" => game_id}, %{"player" => player_name}, socket) do
    {
      :ok,
      socket
      |> put_flash(:info, "Successfully joined game")
      |> assign(player_name: player_name, game_id: game_id)
    }
  end

  @doc """
  Handles joystick movement events from the client.

  Updates the player's velocity in the game server based on joystick input.
  The x and y values are typically in the range [-1, 1] representing
  the direction and magnitude of movement.
  """

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("joystick_move", %{"x" => x, "y" => y}, socket) do
    %{game_id: game_id, player_name: player_name} = socket.assigns

    GameServer.update_velocity(game_id, player_name, {x, y})

    {:noreply, socket}
  end
end
