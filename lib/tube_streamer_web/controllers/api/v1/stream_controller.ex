defmodule TubeStreamerWeb.Api.V1.StreamController do
  use TubeStreamerWeb, :controller

  plug :decode_url

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

  defp decode_url(conn, _opts) do
    try do
      url = conn.params["url"] 
            |> decode!() 
            |> default_schema()
      uri = URI.parse(url)
      true = (uri.scheme != nil && uri.host =~ "." && uri.path != nil)
      %Plug.Conn{conn | params: Map.merge(conn.params, %{"url" => url, "parsed_url" => uri})}
    catch
      _, _ -> 
        conn
        |> send_resp(404, "")
        |> halt()
    end
  end

  defp decode!(url) do
    url = Base.decode32!(url) 
    %URI{} = URI.parse(url)
    url
  end

  defp default_schema("http://" <> _ = url), do: url
  defp default_schema("https://" <> _ = url), do: url
  defp default_schema(url), do: "http://" <> url
end
