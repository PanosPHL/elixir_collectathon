defmodule ElixirCollectathonWeb.LiveViewCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a LiveView connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with LiveViews
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import Plug.Conn
      import ElixirCollectathonWeb.LiveViewCase

      alias ElixirCollectathonWeb.Routes

      @endpoint ElixirCollectathonWeb.Endpoint
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
