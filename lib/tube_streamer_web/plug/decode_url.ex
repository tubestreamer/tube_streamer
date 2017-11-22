defmodule TubeStreamerWeb.Plug.DecodeUrl do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    if Map.has_key?(conn.params, "url") do
      do_decode(conn)
    else
      conn
    end
  end

  defp do_decode(conn) do
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

  def decode!(url) do
    with :error <- Base.decode32(url, padding: false),
         :error <- Base.decode32(url),
         :error <- Base.url_decode64(url, padding: false),
         :error <- Base.url_decode64(url),
         :error <- :error # if we here, no encodings in pipeline worked
    do
      throw "wrong encoding"
    else
      {:ok, url} -> 
        %URI{} = URI.parse(url)
        url
    end
  end

  defp default_schema("http://" <> _ = url), do: url
  defp default_schema("https://" <> _ = url), do: url
  defp default_schema(url), do: "http://" <> url
end
