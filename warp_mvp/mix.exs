defmodule WarpMvp.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end

  # Configure which apps to include in the umbrella
  def apps do
    [
      :warp_engine,
      :warp_web,
      :service_warp
    ]
  end
end
