defmodule PrettyGraphs.MixProject do
  use Mix.Project

  @app :pretty_graphs
  @version "0.1.0"
  # <-- Update this to your real repo URL before publishing
  @source_url "https://github.com/nickkaltner/pretty_graphs"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      # Helpful when running `mix hex.build` locally to ensure only expected files go in.
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # -- Hex / Docs metadata ----------------------------------------------------

  defp description do
    """
    PrettyGraphs: generate clean, accessible SVG bar charts (and future chart types)
    for Phoenix LiveView and general HTML embedding. Simple API, customizable
    styling, gradient fills, per-bar attributes/classes for LiveView integration,
    and responsive-friendly output.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "README" => "#{@source_url}#readme"
      },
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url,
      source_ref: "v#{@version}",
      # Avoid warnings for README references prior to having multiple modules.
      skip_undefined_reference_warnings_on: ["README.md"]
    ]
  end

  # -- Dependencies -----------------------------------------------------------

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
      # Add future runtime deps here
    ]
  end
end
