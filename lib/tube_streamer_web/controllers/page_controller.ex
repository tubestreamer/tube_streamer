defmodule TubeStreamerWeb.PageController do
  use TubeStreamerWeb, :controller

  require Logger

  def index(conn, _params) do
    render conn, "index.html"
  end

  def stream(conn, %{"url" => id} = _params) do
    case TubeStreamer.Stream.MetaCache.lookup(id) do
      stream = %{} ->
        render conn, "stream.html", stream
      :not_found ->
        render conn, "stream-loading.html", url: id
    end
  end
end
