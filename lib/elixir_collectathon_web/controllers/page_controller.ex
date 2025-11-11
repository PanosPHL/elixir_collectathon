defmodule ElixirCollectathonWeb.PageController do
  use ElixirCollectathonWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
