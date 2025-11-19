defmodule ElixirCollectathonWeb.GameLive do
  @moduledoc """
  LiveView for displaying the game canvas and rendering game state.

  This LiveView:
  - Subscribes to game state updates via PubSub
  - Receives game state broadcasts from the game server
  - Pushes game updates to the client via JavaScript events
  - Displays the game canvas where players and items are rendered

  The game state is updated at 30 Hz and pushed to the client for rendering.
  """
  alias Phoenix.PubSub
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathon.Games.Server, as: GameServer
  use ElixirCollectathonWeb, :live_view

  @doc """
  Mounts the LiveView and subscribes to game state updates.

  Verifies the game exists before subscribing. If the game doesn't exist,
  the socket is returned without subscription (TODO: handle redirect).
  """

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
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

  @doc """
  Handles game state updates received from PubSub.

  Pushes the game state to the client via a JavaScript event for rendering.
  """

  @spec handle_info({atom(), Game.t()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:state, state}, socket) do
    {:noreply, push_event(socket, "game_update", state)}
  end
end
