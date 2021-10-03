defmodule AirlineApiAggregatorWeb.CheapestOfferController do
  use AirlineApiAggregatorWeb, :controller

  alias AirlineApiAggregator.CheapestOffer

  action_fallback AirlineApiAggregatorWeb.FallbackController

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"origin" => origin, "destination" => destination, "departureDate" => departure_date}) do
    CheapestOffer.get_cheapest_offer(%{origin: origin, destination: destination, departure_date: departure_date})
    |> case do
      {:ok, cheapest_offer} -> render(conn, "show.json", cheapest_offer: cheapest_offer)
      {:error, message} ->
        json conn, %{error: %{details: message}}
    end
  end

  def show(conn, _) do
    json conn, %{error: %{details: "invalid parameters"}}
  end
end
