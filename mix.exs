defmodule P1Parser.Mixfile do
  use Mix.Project

  def project do
    [
      app: :p1_parser,
      description: "Parsers P1 output of a Smartmeter",
      version: "0.1.3",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:combine, "~> 0.10.0"},
      {:crc, "~> 0.9.1"},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev} 
    ]
  end

  defp package do
  [
    files: ["lib", "mix.exs", "README.md", "LICENSE*"],
    maintainers: ["Gertjan Assies"],
    licenses: ["Apache 2.0"],
    links: %{"GitHub" => "https://github.com/gertjana/p1_parser"}
  ]
end

end
