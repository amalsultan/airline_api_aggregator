defmodule AirlineApiAggregatorWeb.CheapestOfferView do
  use AirlineApiAggregatorWeb, :view
  alias AirlineApiAggregatorWeb.CheapestOfferView

  def render("show.json", %{cheapest_offer: cheapest_offer}) do
    %{data: render_one(cheapest_offer, CheapestOfferView, "cheapest_offer.json")}
  end

  def render("cheapest_offer.json", %{cheapest_offer: cheapest_offer}) do
    %{
      cheapest_offer: %{
        amount: cheapest_offer.amount,
        airline: cheapest_offer.airline}}
  end
end
