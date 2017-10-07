defmodule TubeStreamerWeb.Plug.Metrics do
  alias Plug.Conn

  @behaviour Plug

  @request_timings       [:api, :request, :rtt]
  @request_counter       [:api, :request, :counter]
  @total_request_counter [:api, :request, :counter, :total]

  @histogram_opts        [slot_period: 100, time_span: 60000]

  def init(default), do: default

  def call(conn, _default) do
    Conn.assign(conn, :http_req_start_timestamp, :erlang.system_time(:milli_seconds))
    |> Conn.register_before_send(fn(conn) ->
      before_time = conn.assigns[:http_req_start_timestamp]
      after_time = :erlang.system_time(:milli_seconds)
      lapse = after_time - before_time
      update_metrics(conn.status, lapse)
      conn
    end)
  end

  defp update_metrics(status, ms) do
    :exometer.update_or_create(@request_counter ++ [status], 1, :counter, [])
    :exometer.update_or_create(@total_request_counter, 1, :counter, [])
    :exometer.update_or_create(@request_timings, ms, :histogram, @histogram_opts)
  end
end
