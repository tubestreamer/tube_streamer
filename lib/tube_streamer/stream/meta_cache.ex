defmodule TubeStreamer.Stream.MetaCache do
  use GenServer

  alias :dets, as: Dets
  alias :poolboy, as: Poolboy

  @ttl      60*60*24*30 # 30 days
  @timeout  60*60*1     # 1 hour

  @table    :meta_cache_table

  @cache_miss [:cache, :meta, :miss]
  @cache_hit  [:cache, :meta, :hit]

  def start_link() do
    filename = Application.get_env(:tube_streamer, :filename, "./cache.dets")
               |> String.to_charlist()
    GenServer.start_link(__MODULE__, [filename: filename], name: __MODULE__)
  end

  def member?(url), do: Dets.member(@table, url)

  def get(url) do
    case Dets.lookup(@table, url) do
      [] -> 
        case GenServer.call(__MODULE__, {:get, url}, 30_000) do
          :handling -> 
            :timer.sleep(500)
            get(url)
          result -> 
            :exometer.update_or_create(@cache_miss, 1, :counter, [])
            result
        end
      [{_, result, _}] -> 
        :exometer.update_or_create(@cache_hit, 1, :counter, [])
        {:ok, result}
    end
  end

  def delete_all(), do: 
    Dets.info(@table) != :undefined and Dets.delete_all_objects(@table)

  def size(), do: Dets.info(@table, :size)

  def list(), do: Dets.traverse(@table, fn(val) -> {:continue, val} end)

  def take(n \\ 1000), do:
    Dets.first(@table) |> take(n, [])

  defp take(_, 0, acc), do: acc
  defp take(:"$end_of_table", _, acc), do: acc
  defp take(key, n, acc), do: 
    Dets.next(@table, key) |> take(n-1, [hd(Dets.lookup(@table, key)) | acc])

  def init(args) do
    Process.flag(:trap_exit, true)
    opts =[file: args[:filename], type: :set]
    Dets.open_file(@table, opts)
    restart_timer()
    {:ok, %{handling_urls: []}}
  end

  def handle_call({:get, url}, from, %{handling_urls: urls} = state) do
    if member?(url, urls) do
      {:reply, :handling, state}
    else
      pid = :proc_lib.spawn_link(fn ->
        result = Poolboy.transaction(:dl_worker, 
                                     fn(pid) -> 
                                       TubeStreamer.DlWorker.get_meta(pid, url) 
                                     end, 
                                     30_000)
        if {:ok, meta} = result, do: Dets.insert(@table, {url, meta, ttl()}), else: :ok
        GenServer.reply(from, result)
      end)
      state = %{state | handling_urls: [{url, pid} | urls]}
      {:noreply, state}
    end
  end

  def handle_info({:'EXIT', pid, _reason}, %{handling_urls: urls} = state) do
    urls = delete(pid, urls)
    {:noreply, %{state | handling_urls: urls}}
  end

  def handle_info(:timeout, state) do
    now = :erlang.system_time(:seconds)
    Dets.select_delete(@table, [{{:'$1', :'$2', :'$3'}, 
                                 [{:'<', :'$3', now}], 
                                 [true]}])
    restart_timer()
    {:noreply, state}
  end

  defp member?(_url, []), do: false
  defp member?(url, [{url, _} | _]), do: true
  defp member?(url, [_ | rest]), do: member?(url, rest)

  defp delete(_pid, []), do: []
  defp delete(pid, [{_, pid} | rest]), do: delete(pid, rest)
  defp delete(pid, [head | rest]), do: [head | delete(pid, rest)]

  defp ttl(), do: :erlang.system_time(:seconds) + @ttl
  defp restart_timer(), do: 
    :erlang.send_after(:timer.seconds(@timeout), __MODULE__, :timeout)
end
