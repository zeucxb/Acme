defmodule Acme.MixProject do
  use Mix.Project

  def project do
    [
      app: :acme,
      version: "0.1.0",
      elixir: "~> 1.6-rc",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Acme.CLI],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:timex, "~> 3.1"},
      {:tzdata, "~> 0.1.7"}
    ]
  end
end
