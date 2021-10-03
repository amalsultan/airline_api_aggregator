defmodule AirlineApiAggregatorWeb.CheapestOfferController do
  use AirlineApiAggregatorWeb, :controller

  alias AirlineApiAggregator.CheapestOffer

  action_fallback AirlineApiAggregatorWeb.FallbackController

  def show(conn, %{"origin" => origin, "destination" => destination, "departureDate" => departure_date}) do
    cheapest_offer = CheapestOffer.get_cheapest_offer(%{origin: origin, destination: destination, departure_date: departure_date})
    render(conn, "show.json", cheapest_offer: cheapest_offer)
  end
end
