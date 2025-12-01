defmodule ElixirCollectathonWeb.HomeLive do
  @moduledoc """
  LiveView for the home page where users can create or join games.

  This LiveView provides:
  - A form to create new games
  - A form to join existing games by game ID
  - Feature cards and how-to-play information
  - Navigation to game and controller views

  Users can switch between creating and joining games using the form view toggle.
  """
  alias ElixirCollectathon.Games.Supervisor, as: GameSupervisor
  alias ElixirCollectathon.Games.Server, as: GameServer
  alias ElixirCollectathonWeb.Routes, as: Routes
  use ElixirCollectathonWeb, :live_view

  @doc """
  Renders a feature card component with an icon, header, and description.
  """
  attr :icon_name, :string, required: true
  slot :header, required: true
  slot :inner_block, required: true

  @spec feature_card(map()) :: Phoenix.LiveView.Rendered.t()
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

  @doc """
  Renders a how-to-play card component with a header and description.
  """
  slot :header, required: true
  slot :inner_block, required: true

  @spec how_to_play_card(map()) :: Phoenix.LiveView.Rendered.t()
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

  @doc """
  Mounts the LiveView and initializes form assigns.

  Sets up empty forms for creating and joining games.
  """
  @spec mount(map(), %{optional(String.t()) => String.t()}, Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_, %{"form_view" => form_view, "game_id" => game_id}, socket) do
    {
      :ok,
      socket
      |> assign(
        create_game_form: to_form(%{}),
        join_game_form: to_form(%{"player_name" => "", "game_id" => game_id}),
        trigger_join_game: false,
        form_view: form_view
      )
    }
  end

  def mount(_, %{"form_view" => form_view}, socket) do
    {
      :ok,
      socket
      |> assign(
        create_game_form: to_form(%{}),
        join_game_form: to_form(%{"player_name" => "", "game_id" => ""}),
        trigger_join_game: false,
        form_view: form_view
      )
    }
  end

  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(
        create_game_form: to_form(%{}),
        join_game_form: to_form(%{"player_name" => "", "game_id" => ""}),
        trigger_join_game: false,
        form_view: "create-and-join"
      )
    }
  end

  @doc """
  Handles LiveView events.

  ## Events

  ### "create_game"
  Creates a new game and redirects to the game view on success.
  Shows an error flash message if game creation fails.

  ### "change_form_view"
  Switches between "create-and-join" and other form view modes.

  ### "join_game"
  Validates the game exists and attempts to join the player to the game.
  Handles various error cases:
  - Game doesn't exist
  - Game is full (4 players)
  - Player name already taken
  """

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("create_game", _unsigned_params, socket) do
    case GameSupervisor.create_game() do
      {:ok, game_id} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "Game successfully created.")
          |> push_navigate(to: Routes.game(game_id))
        }

      {:error, :max_retries} ->
        {
          :noreply,
          socket
          |> put_flash(:error, "There was an issue creating a game, try again later.")
        }
    end
  end

  def handle_event("change_form_view", %{"form_view" => form_view}, socket) do
    {
      :noreply,
      socket
      |> assign(
        form_view: form_view,
        join_game_form: to_form(%{"player_name" => "", "game_id" => ""})
      )
    }
  end

  def handle_event(
        "join_game",
        %{"game_id" => game_id, "player_name" => player_name} = params,
        socket
      ) do
    if not GameServer.does_game_exist?(game_id) do
      handle_join_result({:error, :game_does_not_exist}, params, socket)
    else
      GameServer.join(game_id, player_name)
      |> handle_join_result(params, socket)
    end
  end

  @spec handle_join_result(:ok, map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  defp handle_join_result(:ok, _params, socket) do
    {
      :noreply,
      socket
      |> assign(trigger_join_game: true)
    }
  end

  @spec handle_join_result({:error, atom()}, map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  defp handle_join_result({:error, :game_does_not_exist}, params, socket) do
    errors = [game_id: {"No game exists with this ID.", []}]

    {
      :noreply,
      socket
      |> assign(:join_game_form, to_form(params, errors: errors))
    }
  end

  defp handle_join_result({:error, :max_players_reached}, _params, socket) do
    {
      :noreply,
      socket
      |> put_flash(:error, "There are already four players in this game.")
    }
  end

  defp handle_join_result({:error, :already_added}, params, socket) do
    errors = [player_name: {"A player with this name already exists in this game.", []}]

    {
      :noreply,
      socket
      |> assign(:join_game_form, to_form(params, errors: errors))
    }
  end

  defp handle_join_result({:error, :game_already_started}, params, socket) do
    errors = [game_id: {"This game has already started. Try joining a different game.", []}]

    {
      :noreply,
      socket
      |> assign(:join_game_form, to_form(params, errors: errors))
    }
  end

  defp handle_join_result(_other, _params, socket) do
    {
      :noreply,
      socket
      |> put_flash(:error, "There was an issue joining this game, please try again later.")
    }
  end
end
