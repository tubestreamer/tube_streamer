defmodule TubeStreamer.Stream do
  use GenServer

  defmodule Supervisor do
    @moduledoc false
    
    def start_link() do
      import Elixir.Supervisor.Spec

      children = [
        worker(TubeStreamer.Stream, [], restart: :temporary)
      ]

      Elixir.Supervisor.start_link(children, strategy: :simple_one_for_one, name: __MODULE__)
    end
  end

  def start_link(url, opts \\ []) do
    GenServer.start_link(__MODULE__, [url, opts])
  end

  def new(url, opts \\ []) do
    length = Elixir.Supervisor.which_children(TubeStreamer.Stream.Supervisor)
             |> length()
    limit = Application.get_env(:tube_streamer, :streams_limit, 10)
    if length < limit, 
      do: Elixir.Supervisor.start_child(TubeStreamer.Stream.Supervisor, [url, opts]),
      else: :too_much_streams
  end

  def stream(conn, pid) do
    GenServer.cast(pid, {:stream, conn})
    conn
  end

  def await(pid) do
    if Process.alive?(pid) do
      :timer.sleep(100)
      await(pid)
    else
      :done
    end
  end

  def init([url, _opts]) do
    cmd = System.find_executable("youtube-dl")
    args = ["-f", "bestaudio", "--no-warnings", "-q", "-r", "320K", "-o", "-", url]
    {:ok, %{url: url, cmd: cmd, args: args}}
  end

  def handle_cast({:stream, conn}, %{cmd: cmd, args: args} = state) do
    port = Port.open({:spawn_executable, cmd}, [:in, :eof, :binary, args: args])
    {:noreply, Map.merge(state, %{port: port, conn: conn})}
  end

  def handle_info({port, {:data, data}}, %{port: port, conn: conn} = state) do
    case Plug.Conn.chunk(conn, data) do
      {:ok, _} -> {:noreply, state}
      {:error, _} -> 
        Port.close(port)
        {:stop, :normal, state}
    end
  end

  def handle_info({port, :eof}, %{port: port, conn: _conn} = state) do
    Port.close(port)
    {:stop, :normal, state}
  end
end
