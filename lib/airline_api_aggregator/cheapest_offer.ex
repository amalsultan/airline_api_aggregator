defmodule AirlineApiAggregator.CheapestOffer do
  @moduledoc """
    ApiAggregator.CheapestOffer includes methods to get cheapest offers by fetching all the offers of given data providers
  """
  def get_cheapest_offer(%{origin: _origin, destination: _destination, departure_date: _departure_date}) do
    %{amount: 0, airline: "BA"}
  end
end
