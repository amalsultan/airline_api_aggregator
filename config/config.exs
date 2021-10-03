# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :airline_api_aggregator,
  data_providers: [
    %{id: "BA" ,url: "https://test.api.ba.com/selling-distribution/AirShopping/V2", soap_action: "AirShoppingV01", content_type: "application/xml", api_key: System.get_env("ba_api_key")},
    %{id: "AFKL", url: "https://ndc-rct.airfranceklm.com/passenger/distribmgmt/001448v02/EXT", soap_action: "\"http://www.af-klm.com/services/passenger/ProvideAirShopping/airShopping\"", content_type: "text/xml", api_key: System.get_env("afkl_api_key")}
    ]

# Configures the endpoint
config :airline_api_aggregator, AirlineApiAggregatorWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vifLCRjRGS2UK08JdrbL3Klmn1scpXh6lfSklUAL+0bpt53clkRRoxY3vwun2rX/",
  render_errors: [view: AirlineApiAggregatorWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: AirlineApiAggregator.PubSub,
  live_view: [signing_salt: "cJvy4OML"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
