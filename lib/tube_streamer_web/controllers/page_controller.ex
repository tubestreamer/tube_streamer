defmodule TubeStreamerWeb.PageController do
  use TubeStreamerWeb, :controller

  require Logger

  plug TubeStreamerWeb.Plug.DecodeUrl

  def index(conn, _params) do
    render conn, "index.html"
  end

  def stream(conn, %{"url" => url} = _params) do
    case TubeStreamer.Stream.MetaCache.lookup(url) do
      stream = %{} ->
        render conn, "stream.html", stream
      :not_found ->
        id = Base.url_encode64(url, padding: false)
        render conn, "stream-loading.html", url: id
    end
  end
end
