defmodule ClippexWeb.PageController do
  use ClippexWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
