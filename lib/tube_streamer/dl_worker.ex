defmodule TubeStreamer.DlWorker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, nil}
  end

  def get_meta(pid, url) do
    GenServer.call(pid, {:get_meta, url}, 30_000)
  end

  def handle_call({:get_meta, url}, from, state) do
    opts = ["--no-warnings", "-q", "-f", "bestaudio", "-g", "-e", "--get-thumbnail", "--get-duration", url]
    case System.cmd("youtube-dl", opts) do
      {data, 0} -> 
        spawn(fn ->
          [title, link, cover, duration | _] = String.split(data, "\n")
          id = Base.url_encode64(url, padding: false)
          meta = %{id: id,
                   stream: stream(id, url, link),
                   title: title, 
                   cover: cover,
                   duration: to_sec(duration)}
          GenServer.reply(from, {:ok, meta})
        end)
        {:noreply, state}
      _ -> {:reply, :not_found, state}
    end
  end

  defp to_sec(d) when is_binary(d), do: String.split(d, ":") |> to_sec()
  defp to_sec([h, m, s]), do:
    String.to_integer(h) * 60 * 60 + String.to_integer(m) * 60 + String.to_integer(s)
  defp to_sec([m, s]), do:
    String.to_integer(m) * 60 + String.to_integer(s)
  defp to_sec([s]), do: 
    String.to_integer(s)

  defp stream(id, url, link) do
    if url =~ "youtube", 
      do: link,
      else: TubeStreamerWeb.Router.Helpers.stream_url(TubeStreamerWeb.Endpoint, :index, id)
  end
end
