defmodule TubeStreamerWeb.PageController do
  use TubeStreamerWeb, :controller

  require Logger

  plug TubeStreamerWeb.Plug.DecodeUrl

  def index(conn, _params) do
    render conn, "index.html"
  end

  def stream(conn, %{"url" => url} = _params) do
    case TubeStreamer.Stream.MetaCache.member?(url) do
      true ->
        {:ok, stream} = TubeStreamer.Stream.MetaCache.get(url)
        render conn, "stream.html", stream
      false ->
        id = Base.url_encode64(url, padding: false)
        render conn, "stream-loading.html", url: id
    end
  end
end
