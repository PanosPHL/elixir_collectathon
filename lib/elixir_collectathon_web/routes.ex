defmodule ElixirCollectathonWeb.Routes do
  @moduledoc """
  Helper module for generating verified routes.

  Provides type-safe route helpers using Phoenix's verified routes feature.
  All routes are verified at compile time to ensure they exist.
  """
  use ElixirCollectathonWeb, :verified_routes

  @doc """
  Returns the path to the home page.

  ## Examples

      Routes.home()
      # => ~p"/"
  """
  @spec home() :: Phoenix.VerifiedRoutes.formatted_route()
  def home(), do: ~p"/"

  @spec home(%{section: String.t()}) :: Phoenix.VerifiedRoutes.formatted_route()
  def home(%{section: section}), do: ~p"/##{section}"

  @spec home(%{form_view: String.t(), game_id: String.t()}) ::
          Phoenix.VerifiedRoutes.formatted_route()
  def home(%{form_view: form_view, game_id: game_id}),
    do: ~p"/?form_view=#{form_view}&game_id=#{game_id}"

  @spec home(%{form_view: String.t()}) :: Phoenix.VerifiedRoutes.formatted_route()
  def home(%{form_view: form_view}), do: ~p"/?form_view=#{form_view}"

  @doc """
  Returns the path to a game view.

  ## Parameters
    - `game_id` - The ID of the game

  ## Examples

      Routes.game("ABC123")
      # => ~p"/games/ABC123"
  """
  def game(game_id) do
    ~p"/games/#{game_id}"
  end

  @doc """
  Returns the path to a controller view for a game.

  ## Parameters
    - `game_id` - The ID of the game

  ## Examples

      Routes.controller("ABC123")
      # => ~p"/controller/ABC123"
  """
  def controller(game_id) do
    ~p"/controller/#{game_id}"
  end
end
