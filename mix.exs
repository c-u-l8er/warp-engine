defmodule WarpEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :warp_engine,
      version: "1.0.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Revolutionary physics-inspired graph database with quantum entanglement, spacetime sharding, and 23,742 ops/sec performance",
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {WarpEngine.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},           # JSON encoding for human-readable data
      {:benchee, "~> 1.1", only: :dev}, # Performance benchmarking
      {:ex_doc, "~> 0.29", only: :dev}, # Documentation generation
      {:dialyxir, "~> 1.3", only: :dev, runtime: false}, # Static analysis
      {:credo, "~> 1.7", only: :dev}     # Code quality
    ]
  end

  defp package do
    [
      name: "warp_engine",
      description: "Revolutionary physics-inspired graph database with 23,742 ops/sec performance",
      maintainers: ["WarpEngine Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/company/warp_engine_database",
        "Documentation" => "https://hexdocs.pm/warp_engine",
        "Benchmarks" => "https://github.com/company/warp_engine_database/tree/main/benchmarks"
      },
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "docs/complete-roadmap.md",
        "docs/phase*-*.md",
        "examples/weighted_graph_database.ex",
        "benchmarks/simple_weighted_graph_benchmark.exs"
      ]
    ]
  end

  defp docs do
    [
      main: "WarpEngine",
      source_url: "https://github.com/company/warp_engine_database",
      homepage_url: "https://github.com/company/warp_engine_database",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/complete-roadmap.md",
        "docs/phase1-quick-start.md",
        "docs/phase3-completion-summary.md",
        "docs/phase4-completion-summary.md",
        "docs/phase5-completion-summary.md",
        "docs/phase6-completion-summary.md",
        "docs/phase7-temporal-management-planning.md",
        "docs/phase8-completion-summary.md"
      ],
      groups_for_extras: [
        "Getting Started": [
          "README.md",
          "CHANGELOG.md",
          "docs/complete-roadmap.md",
          "docs/phase1-quick-start.md"
        ],
        "Phase Documentation": [
          "docs/phase3-completion-summary.md",
          "docs/phase4-completion-summary.md",
          "docs/phase5-completion-summary.md",
          "docs/phase6-completion-summary.md",
          "docs/phase7-temporal-management-planning.md",
          "docs/phase8-completion-summary.md"
        ]
      ]
    ]
  end
end
