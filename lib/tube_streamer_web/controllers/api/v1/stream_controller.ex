defmodule TubeStreamerWeb.Api.V1.StreamController do
  use TubeStreamerWeb, :controller

  plug TubeStreamerWeb.Plug.DecodeUrl

  def index(conn, %{"url" => url, "parsed_url" => parsed_url} = _params) do
    if parsed_url.host =~ "youtube" do
      {:ok, %{stream: stream}} = TubeStreamer.Stream.MetaCache.get(url)
      redirect conn, external: stream
    else
      case TubeStreamer.Stream.new(url) do
        {:ok, pid} -> 
          conn = send_chunked(conn, 200)
                 |> TubeStreamer.Stream.stream(pid)
          TubeStreamer.Stream.await(pid)
          conn
        :too_much_streams -> send_resp(conn, 429, "")
      end
    end
  end

  def info(conn, %{"url" => url} = _params) do
    case TubeStreamer.Stream.MetaCache.get(url) do
      {:ok, meta} -> 
        conn
        |> put_status(200)
        |> json(meta)
      _ -> send_resp(conn, 404, "")
    end
  end
end
