defmodule ElixirCollectathonWeb.GamesListLive do
  @moduledoc """
  A LiveView that displays a list of active games.

  It subscribes to the "games" topic on the `ElixirCollectathon.PubSub` to receive real-time updates
  when games are created or shut down. It maintains a stream of game IDs.
  """

  alias Phoenix.PubSub
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Game
  alias ElixirCollectathonWeb.Routes
  use ElixirCollectathonWeb, :live_view

  @doc """
  Mounts the LiveView.

  It subscribes to the "games" PubSub topic if the socket is connected.
  It also initializes the `:game_ids` stream by querying the `ElixirCollectathon.Games.Supervisor`
  for running game servers and extracting their game IDs.
  """
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(ElixirCollectathon.PubSub, "games")

    game_ids =
      for {_, pid, _, [ElixirCollectathon.Games.Server]} <-
            DynamicSupervisor.which_children(GameSupervisor) do
        %Game{game_id: game_id} = :sys.get_state(pid)
        game_id
      end

    {
      :ok,
      socket
      |> stream(:game_ids, game_ids, dom_id: &"game_#{&1}")
    }
  end

  @doc """
  Handles info messages.

  * `{:game_created, game_id}` - Adds the new `game_id` to the `:game_ids` stream.
  * `{:game_server_shutdown, game_id}` - Removes the `game_id` from the `:game_ids` stream.
  """
  @spec handle_info({:game_created, String.t()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:game_created, game_id}, socket) do
    {
      :noreply,
      socket
      |> stream_insert(:game_ids, game_id)
    }
  end

  @spec handle_info({:game_server_shutdown, String.t()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:game_server_shutdown, game_id}, socket) do
    {
      :noreply,
      socket
      |> stream_delete(:game_ids, game_id)
    }
  end
end
