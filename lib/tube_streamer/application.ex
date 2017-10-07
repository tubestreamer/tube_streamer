defmodule TubeStreamer.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(TubeStreamerWeb.Endpoint, []),
      supervisor(TubeStreamer.Stream.Supervisor, []),
      worker(TubeStreamer.Stream.MetaCache, []),
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    opts = [strategy: :one_for_one, name: TubeStreamer.Supervisor]
    sup = Supervisor.start_link(children, opts)
    TubeStreamer.Metrics.init()
    sup
  end

  defp poolboy_config do
    [name:           {:local, :dl_worker},
     worker_module:  TubeStreamer.DlWorker,
     size:           System.schedulers_online(),
     max_overflow:   1]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TubeStreamerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
