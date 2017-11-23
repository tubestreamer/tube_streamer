defmodule TubeStreamerWeb.SitemapController do
  use TubeStreamerWeb, :controller

  require Logger

  alias TubeStreamer.Stream.MetaCache

  def index(conn, _params) do
    locations = ["http://tubestreamer.ru/" | 
                 (for {_, %{id: id}, _} <- MetaCache.take(), 
                  do: page_url(conn, :stream, id))]
    render conn, "index.xml", locations: locations
  end
end
