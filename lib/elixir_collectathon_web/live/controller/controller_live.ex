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
  alias ElixirCollectathonWeb.Routes
  alias Phoenix.PubSub
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathonWeb.Components.CustomComponents
  use ElixirCollectathonWeb, :live_view

  @doc """
  Mounts the LiveView with the game ID and player name from the session.

  The player name is retrieved from the session set by the GameController
  when the player successfully joins a game.

  If no player is found in the session, the user is redirected to the home page.
  """

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(%{"game_id" => game_id}, %{"player" => player_name}, socket) do
    if connected?(socket), do: PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

    {
      :ok,
      socket
      |> put_flash(:info, "Successfully joined game.")
      |> assign(
        player_name: player_name,
        game_id: game_id,
        game_is_running: false,
        countdown: nil,
        winner: nil
      )
    }
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> put_flash(:error, "You are not currently in this game, please join a game to play.")
      |> redirect(to: Routes.home())
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

  @doc """
  Handles messages sent from the game server.

  - `{:countdown, countdown}`: Updates the countdown timer displayed to players.
  - `:game_started`: Marks the game as started in the LiveView state.
  - `{:game_server_shutdown, reason}`: Handles redirects if reason == :timeout, otherwise does nothing.
  - Any other messages are ignored.
  """

  @spec handle_info({:state, Game.t()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:state, %Game{winner: winner}}, socket) when not is_nil(winner) do
    {
      :noreply,
      socket
      |> assign(winner: winner)
    }
  end

  @spec handle_info({:countdown, pos_integer() | String.t()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:countdown, countdown}, socket) do
    {:noreply, socket |> assign(countdown: countdown)}
  end

  @spec handle_info(:game_started, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(:game_started, socket) do
    {:noreply, socket |> assign(game_is_running: true)}
  end

  @spec handle_info({:game_server_shutdown, :timeout | :normal}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:game_server_shutdown, :timeout}, socket) do
    {
      :noreply,
      socket
      |> put_flash(
        :error,
        "Your game has timed out due to inactivity. Join a new game to conitnue playing."
      )
      |> redirect(to: Routes.home())
    }
  end

  def handle_info({:game_server_shutdown, _reason}, socket) do
    {:noreply, socket}
  end

  @spec handle_info(any(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(_, socket) do
    {:noreply, socket}
  end
end
