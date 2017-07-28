use Mix.Config

if :test == Mix.env do
  config :logger, backends: []
end
