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
  alias ElixirCollectathonWeb.Components.CustomComponents
  use ElixirCollectathonWeb, :live_view

  @doc """
  Renders a player scorecard in the game view
  """

  attr :color, :string, required: true
  attr :name, :string, required: true
  attr :letters, :list, required: true
  attr :inventory, :list, required: true
  attr :id, :string, required: true

  @spec player_scorecard(map()) :: Phoenix.LiveView.Rendered.t()
  def player_scorecard(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col p-4 gap-3 rounded-lg bg-base-200 shadow-lg">
      <div class="flex items-center gap-3">
        <div
          class="w-4 h-4 rounded-full ring-2 ring-offset-2 ring-offset-base-200"
          style={"background-color: #{@color};"}
        >
        </div>
        <h3 class="font-bold text-lg">{@name}</h3>
      </div>
      <div class="flex flex-wrap gap-1">
        <%= for {letter, collected} <- Enum.zip(@letters, @inventory) do %>
          <%= if letter == collected do %>
            <span class="flex items-center justify-center w-8 h-8 rounded bg-primary text-primary-content font-bold shadow-sm">
              {letter}
            </span>
          <% else %>
            <span class="flex items-center justify-center w-8 h-8 rounded bg-base-300/50 text-base-content/20 font-bold opacity-50">
              {letter}
            </span>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Mounts the LiveView and subscribes to game state updates.

  Verifies the game exists before subscribing. If the game doesn't exist,
  the user is redirected to the home page.
  """

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(%{"id" => game_id}, _session, socket) do
    GameServer.does_game_exist?(game_id)
    |> handle_mount(game_id, socket)
  end

  @spec handle_mount(boolean(), String.t(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  defp handle_mount(true, game_id, socket) do
    if connected?(socket),
      do: PubSub.subscribe(ElixirCollectathon.PubSub, "game:#{game_id}")

    {
      :ok,
      socket
      |> assign(
        game_id: game_id,
        letters: ~w"E L I X I R",
        countdown: nil,
        game_started: false,
        player_count: 0,
        winner: nil
      )
      |> stream(:players, [], dom_id: &"p-#{&1.name}")
    }
  end

  defp handle_mount(false, _game_id, socket) do
    {
      :ok,
      socket
      |> put_flash(:error, "Game not found.")
      |> redirect(to: Routes.home())
    }
  end

  @doc """
  Handles LiveView URL parameter changes.

  Generates a QR code for joining the game using the current URI and assigns it asynchronously to the socket.
  """
  @spec handle_params(map(), String.t(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_params(%{"id" => game_id}, uri, socket) do
    %URI{scheme: scheme, authority: authority} = URI.parse(uri)

    {
      :noreply,
      socket
      |> assign_async(:qr_code, fn ->
        {:ok,
         %{
           qr_code:
             "#{scheme}://#{authority}/?form_view=join-game&game_id=#{game_id}"
             |> QRCode.create()
             |> QRCode.render()
         }}
      end)
    }
  end

  @doc """
  Handles game state updates received from PubSub.

  - `{:state, %Game{}}`: handles updating the player list and pushing the game state to the client for JavaScript events.
  - `{:countdown, n}`: updates the countdown timer in the socket assigns.
  - `:game_started`: sets the game_started flag to true in the socket assigns.
  - `{:game_server_shutdown, reason}`: Handles redirects if reason == :timeout, otherwise does nothing.
  - All other messages are ignored
  """

  @spec handle_info({:state, Game.t()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:state, %Game{players: players, winner: winner} = state}, socket) do
    {count, sorted_players} = prepare_players(players)

    {
      :noreply,
      socket
      |> assign(player_count: count, winner: winner)
      |> stream(:players, sorted_players, dom_id: &"p-#{&1.name}", reset: true)
      |> push_event("game_update", state)
    }
  end

  @spec handle_info({:countdown, pos_integer() | String.t()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:countdown, n}, socket) do
    {
      :noreply,
      socket
      |> assign(countdown: n)
    }
  end

  @spec handle_info(:game_started, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(:game_started, socket) do
    {
      :noreply,
      socket
      |> assign(game_started: true)
    }
  end

  @spec handle_info({:game_server_shutdown, :timeout | :normal}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:game_server_shutdown, :timeout}, socket) do
    {
      :noreply,
      socket
      |> put_flash(
        :error,
        "Your game has timed out due to inactivity. Create a new game to conitnue playing."
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

  @spec prepare_players(map()) :: {integer(), list()}
  defp prepare_players(players) do
    {count, players_list} =
      Enum.reduce(players, {0, []}, fn {_name, player}, {count, acc} ->
        {count + 1, [player | acc]}
      end)

    sorted_players = Enum.sort_by(players_list, & &1.player_num)

    {count, sorted_players}
  end

  @doc """
  Handles the "start_countdown" event triggered by the user to start the game countdown.
  """

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("start_countdown", _, socket) do
    GameServer.start_countdown(socket.assigns.game_id)

    {:noreply, socket}
  end
end
