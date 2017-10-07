defmodule TubeStreamer.Metrics do
  require Logger

  alias :exometer, as: Exometer

  def subscribe([:erlang, :beam, :star_time], _), do: []

  def subscribe([:api, :request, :counter, _status] = metric, :counter), do:
     {metric, :value, get_interval(), [series_name: "api.request.counter", 
                                       tags: [status: {:from_name, 4}]]}

  def subscribe(metric, type) when type in [:gauge, :counter], do:
    {metric, :value, get_interval(), [series_name: format(metric)]}

  def subscribe(metric, :histogram), do:
    for dp <- [95, 99, :max], do:
      {metric, dp, get_interval(), [series_name: format(metric)]}

  def subscribe(metric, :function) do
    case Exometer.get_value(metric) do
      {:ok, [_head | _] = values} ->
        for {datapoint, _} <- values, do:
          {metric, datapoint, get_interval(), [series_name: format(metric)]}
      _ ->
        Logger.error("unexpected error on metric subscribe: #{inspect metric}")
        []
    end
  end

  def subscribe(_, _), do: []

  def init() do
    Exometer.update([:erlang, :beam, :start_time], timestamp())
    Exometer.update_or_create([:cache, :meta, :size], 0,
                              {:function, __MODULE__, :get_meta_cache_size, [], :value, [:value]},
                              [])
  end

  defp get_interval() do
    default = [influx: [interval: 60_000]]
    Application.get_env(:tube_stream, :metrics, default)
    |> Keyword.get(:influx)
    |> Keyword.get(:interval)
  end

  defp format([head | tail]) do
    to_string(head) <> to_string(for atom <- tail, do: "." <> to_string(atom))
  end

  def get_meta_cache_size(), do: [value: TubeStreamer.Stream.MetaCache.size()]

  def garbage_collection do
    {number_of_gcs, words_reclaimed, _} = :erlang.statistics(:garbage_collection)
    [number_of_gcs: number_of_gcs, words_reclaimed: words_reclaimed]
  end

  def io do
    {{:input, input}, {:output, output}} = :erlang.statistics(:io)
    [input: input, output: output]
  end

  def process_info do
    process_count = :erlang.system_info(:process_count)
    process_limit = :erlang.system_info(:process_limit)
    run_queue_size = :erlang.statistics(:run_queue)
    [process_count: process_count, process_limit: process_limit, run_queue_size: run_queue_size]
  end

  def update_uptime do
    {:ok, [{:value, start_time}, _ ]} = Exometer.get_value([:erlang, :beam, :start_time])
    uptime = timestamp() - start_time
    [value: round(uptime)]
  end

  def timestamp(), do: :erlang.system_time(:milli_seconds)
end
