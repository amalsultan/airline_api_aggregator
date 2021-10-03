defmodule AirlineApiAggregatorWeb.CheapestOfferTest do
  use AirlineApiAggregatorWeb.ConnCase

  alias AirlineApiAggregator.CheapestOffer

  @invalid_attrs %{origin: "BER", destination: "LHR", departure_date: "2019-10-17"}
  @valid_attrs %{origin: "BER", destination: "LHR", departure_date: "2021-10-17"}

  describe "cheapest offer" do
    test "cheapest offer with valid attributes" do
      {:ok, cheapest_offer} = CheapestOffer.get_cheapest_offer(@valid_attrs)
      assert cheapest_offer != nil
      assert Map.get(cheapest_offer, :airline) != nil
      assert Map.get(cheapest_offer, :amount) != nil
    end

    test "cheapest offer with old departure_old" do
      assert CheapestOffer.get_cheapest_offer(@invalid_attrs) == {:error, :not_found}
    end
  end
end
