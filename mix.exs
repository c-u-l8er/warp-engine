defmodule IsLabDB.MixProject do
  use Mix.Project

  def project do
    [
      app: :islab_db,
      version: "1.0.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Physics-inspired database with elegant filesystem persistence",
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {IsLabDB.Application, []}
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
      maintainers: ["IsLab Team"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/company/islab_database"}
    ]
  end

  defp docs do
    [
      main: "IsLabDB",
      extras: ["README.md", "docs/complete-roadmap.md", "docs/phase1-quick-start.md", "docs/phase3-completion-summary.md", "docs/phase4-completion-summary.md"]
    ]
  end
end
