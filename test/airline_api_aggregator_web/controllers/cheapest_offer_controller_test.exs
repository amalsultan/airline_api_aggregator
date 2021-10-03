defmodule AirlineApiAggregatorWeb.CheapestOfferControllerTest do
  use AirlineApiAggregatorWeb.ConnCase

  @invalid_attrs %{origin: "BER"}
  @valid_attrs %{origin: "BER", destination: "LHR", departureDate: "2021-10-17"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    test "show cheapest offer with valid attributes", %{conn: conn} do
      conn = get(conn, Routes.cheapest_offer_path(conn, :show, @valid_attrs))
      response = json_response(conn, 200)["data"]
      cheapest_offer = Map.get(response, "cheapest_offer")
      assert cheapest_offer != nil
      assert Map.get(cheapest_offer, "airline") != nil
      assert Map.get(cheapest_offer, "amount") != nil
    end
  end

  describe "show with invalid parameters" do
    test "show cheapest offer invalid attributes", %{conn: conn} do
      conn = get(conn, Routes.cheapest_offer_path(conn, :show, @invalid_attrs))
      assert json_response(conn, 200)["error"] == %{"details" => "invalid parameters"}
    end
  end
end
