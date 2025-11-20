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
  alias ElixirCollectathonWeb.Routes
  use ElixirCollectathonWeb, :live_view

  @doc """
  Mounts the LiveView and subscribes to game state updates.

  Verifies the game exists before subscribing. If the game doesn't exist,
  the user is redirected to the home page.
  """

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(%{"id" => game_id}, _session, socket) do
    case GenServer.whereis(GameServer.via_tuple(game_id)) do
      nil ->
        {
          :ok,
          socket
          |> put_flash(:error, "Game not found.")
          |> redirect(to: Routes.home())
        }

      _ ->
        if connected?(socket),
          do: PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

        {
          :ok,
          socket
          |> assign(game_id: game_id)
        }
    end
  end

  @doc """
  Handles game state updates received from PubSub.

  Pushes the game state to the client via a JavaScript event for rendering.
  """

  @spec handle_info({atom(), Game.t()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:state, state}, socket) do
    {
      :noreply,
      socket
      |> push_event("game_update", state)
    }
  end
end
