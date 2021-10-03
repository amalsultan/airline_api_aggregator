defmodule AirlineApiAggregator.CheapestOffer do
  @moduledoc """
    Includes methods to get cheapest offers by fetching all the offers of given data providers. It consumes a list of data providers from the config file.
  """
  require Logger
  import SweetXml

  @spec get_cheapest_offer(%{
          :departure_date => any,
          :destination => any,
          :origin => any,
          optional(any) => any
        }) :: %{airline: <<_::16>>, amount: 0}
  def get_cheapest_offer(%{origin: _origin, destination: _destination, departure_date: _departure_date} = args) do
    Application.fetch_env!(:api_aggregator, :data_providers)
    |> Enum.map(fn data_provider -> Task.async(fn -> get_data(data_provider, args) end) end)
    |> Enum.map(fn task -> Task.await(task, 60000) end)
    |> Enum.filter(fn {status, _data} -> status == :ok end)
    |> get_minimum_offer()
  end

  def get_data(%{id: id, api_key: nil}, _args) do
    Logger.error("Api key for #{id} is not set in environment variables")
    {:error, :not_found}
  end

  def get_data(%{id: "BA"= id ,url: url, soap_action: soap_action, content_type: content_type, api_key: api_key}, args) do
    xml_request = build_soap_request(id, args)
    headers = ["Content-Type": content_type, Soapaction: soap_action, "Client-Key": api_key]
    Logger.info("Getting offers from #{id}")
    HTTPoison.post!(url, xml_request, headers, [timeout: 50_000, recv_timeout: 50_000])
    |> case do
       %HTTPoison.Response{status_code: 200, body: body} ->
      parse_response(id, body)
      %HTTPoison.Response{status_code: status_code} ->
        Logger.error("#{id} sends #{status_code} error")
        {:error, :failed}
      _->
        Logger.error("Unknown error occured while getting data from #{id}")
        {:error, :failed}
       end
  end

  def build_soap_request("BA", %{origin: origin, destination: destination, departure_date: departure_date}) do
    "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\"><s:Body xmlns=\"http://www.iata.org/IATA/EDIST\"><AirShoppingRQ Version=\"3.0\" xmlns=\"http://www.iata.org/IATA/EDIST\"><PointOfSale><Location><CountryCode>DE</CountryCode></Location></PointOfSale><Document/><Party><Sender><TravelAgencySender><Name>test agent</Name><IATA_Number>00002004</IATA_Number><AgencyID>test agent</AgencyID></TravelAgencySender></Sender></Party><Travelers><Traveler><AnonymousTraveler><PTC Quantity=\"1\">ADT</PTC></AnonymousTraveler></Traveler></Travelers><CoreQuery><OriginDestinations><OriginDestination><Departure><AirportCode>#{origin}</AirportCode><Date>#{departure_date}</Date></Departure><Arrival><AirportCode>#{destination}</AirportCode></Arrival></OriginDestination></OriginDestinations></CoreQuery></AirShoppingRQ></s:Body></s:Envelope>"
  end

  def parse_response("BA"= id, data) do
    with price_list <- xpath(data, ~x"//TotalPrice/SimpleCurrencyPrice/text()"l), {:ok, minimum_price} <- get_minimum_price(price_list), {:ok, cheapest_price} <- char_list_to_float(minimum_price) do
      {:ok, %{amount: cheapest_price, airline: id}}
    else
      {:error, message} ->
        Logger.error("Couldn't parse required data from #{id}")
        {:error, message}
    end
  end

  #Helper Methods
  defp char_list_to_float(value) when is_list(value) do
    float_val =
      value
      |> to_string()
      |> String.to_float()
    {:ok, float_val}
  end

  defp char_list_to_float(_value) do
    {:error, :not_found}
  end

  defp get_minimum_price(price_list) when length(price_list) > 0 do
    minimum_price = price_list
    |> Enum.min()
    {:ok, minimum_price}
  end

  defp get_minimum_price(_price_list) do
    {:error, :not_found}
  end

  def get_minimum_offer(all_offers) when length(all_offers) > 0 do
    all_offers
    |> Enum.min_by(fn {_status, data} -> data.amount end)
  end

  def get_minimum_offer(_all_offers) do
    {:error, :not_found}
  end
end
