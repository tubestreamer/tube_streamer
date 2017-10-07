# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :tube_streamer, TubeStreamerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1Av9GZQj0PupVxOt/sNCDuCddKEz2rT3oEXYyhWz2uW6fEgdOk75VAQUcG4pbLW1",
  render_errors: [view: TubeStreamerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TubeStreamer.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

metrics_mod   = TubeStreamer.Metrics
memory_dps    = [:total, :processes, :processes_used, :system, :ets, :binary, :code, :atom, :atom_used]
process_dps   = [:process_count, :process_limit, :run_queue_size]
processor_dps = [:logical_processors, :logical_processors_available, :logical_processors_online]
#schedulers    = :lists.seq(1, :erlang.system_info(:schedulers))

config :exometer_core, :predefined, [
  {[:erlang, :otp_release],
    {:function, :erlang, :system_info, [:'$dp'], :value, [:otp_release]}, []},

  {[:erlang, :beam, :port],
    {:function, :erlang, :system_info, [:'$dp'], :value, [:port_count, :port_limit]}, []},

  {[:erlang, :beam, :process],
    {:function, metrics_mod, :process_info, [], :proplist, process_dps}, []},

  {[:erlang, :beam, :processor],
    {:function, :erlang, :system_info, [:'$dp'], :value, processor_dps}, []},

  {[:erlang, :beam, :garbage_collection],
    {:function, metrics_mod, :garbage_collection, [], :value, [:number_of_gcs, :words_reclaimed]}, []},

  {[:erlang, :beam, :io],
    {:function, metrics_mod, :io, [], :value, [:input, :output]}, []},

  {[:erlang, :beam, :memory],
    {:function, :erlang, :memory, [:'$dp'], :value, memory_dps}, []},

  #{[:erlang, :beam, :scheduler_usage],
    #{:function, :recon, :scheduler_usage, [1000], :proplist, schedulers}, []},

  {[:erlang, :beam, :start_time], :gauge, []},

  {[:erlang, :beam, :uptime],
    {:function, metrics_mod, :update_uptime, [], :proplist, [:value]}, []}
]

config :setup, :verify_directories, false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
