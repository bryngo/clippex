defmodule ClippexWeb.PageController do
  use ClippexWeb, :controller

  def home(conn, _params) do
    # value = Application.get_env(:clippex, :twitch)[:test]
    # IO.inspect("Twitch test value: #{value}")
    render(conn, :home)
  end
end
