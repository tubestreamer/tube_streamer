defmodule TubeStreamer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tube_streamer,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TubeStreamer.Application, []},
      extra_applications: [:lager, :logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix,             "~> 1.3.0"},
      {:phoenix_pubsub,      "~> 1.0"},
      {:phoenix_html,        "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext,             "~> 0.11"},
      {:cowboy,              "~> 1.0"},
      {:distillery,          "~> 2.0.0-pre"},
      {:phoenix_swagger,     "~> 0.6.4"},
      {:poolboy,             "~> 1.5"},
      {:exometer_core,       "~> 1.5.2"},
      {:exometer_influxdb,   "~> 0.6.0"},
      {:parse_trans,         "~> 3.2.0", override: true},
    ]
  end
end
