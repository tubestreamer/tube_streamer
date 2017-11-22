defmodule TubeStreamer.Stream.MetaCache do
  use GenServer

  alias :ets, as: Ets
  alias :poolboy, as: Poolboy

  @ttl      60*60*12   # 12 hours
  @timeout  60*60*1    # 1 hour

  @table    :meta_cache_table

  @cache_miss [:cache, :meta, :miss]
  @cache_hit  [:cache, :meta, :hit]

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def lookup(url) do
    case Ets.lookup(@table, url) do
      [] -> :not_found
      [{_, result, _}] -> result
    end
  end

  def get(url) do
    case Ets.lookup(@table, url) do
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
    Ets.info(@table) != :undefined and Ets.delete_all_objects(@table)

  def size(), do: Ets.info(@table, :size)

  def list(), do: Ets.tab2list(@table)

  def init(_args) do
    Process.flag(:trap_exit, true)
    opts =[:public, :ordered_set, :named_table, 
           read_concurrency: true, 
           write_concurrency: true]
    Ets.new(@table, opts)
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
        if {:ok, meta} = result, do: Ets.insert(@table, {url, meta, ttl()}), else: :ok
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
    Ets.select_delete(@table, [{{:'$1', :'$2', :'$3'}, 
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
