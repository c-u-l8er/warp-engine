defmodule ServiceWarp.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_warp,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~>1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ServiceWarp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core dependencies
      {:phoenix, "~> 1.7.0"},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},

      # AI Agents
      {:autogentic, "~> 1.0.0"},

      # Database
      {:ecto, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # WarpEngine integration
      {:warp_engine, in_umbrella: true},

      # Development dependencies
      {:esbuild, "~> 0.8"},
      {:tailwind, "~> 0.2.0"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics_prometheus, "~> 1.1"},
      {:telemetry_metrics_prometheus_core, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
