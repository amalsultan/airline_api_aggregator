defmodule AirlineApiAggregator.CheapestOffer do
  @moduledoc """
    Includes methods to get cheapest offers by fetching all the offers of given data providers. It consumes a list of data providers from the config file.
  """
  require Logger
  import SweetXml

  @doc """
   Takes origin, destination and departure data as input. Then it fetches providers data from config file. Calls get_data/2 method asynchronously to send the api call to the given data providers one by one. It recieves the cheapest offer by each provider and then takes the minimum of all.
  """
  @spec get_cheapest_offer(%{
          :departure_date => any,
          :destination => any,
          :origin => any,
          optional(any) => any
        }) :: %{airline: <<_::16>>, amount: 0}
  def get_cheapest_offer(%{origin: _origin, destination: _destination, departure_date: _departure_date} = args) do
    Application.fetch_env!(:airline_api_aggregator, :data_providers)
    |> Enum.map(fn data_provider -> Task.async(fn -> get_data(data_provider, args) end) end)
    |> Enum.map(fn task -> Task.await(task, 60000) end)
    |> Enum.filter(fn {status, _data} -> status == :ok end)
    |> get_minimum_offer()
  end

  @doc """
   Takes api arguments and provider data as input. This function has two implementations on the basis of data providers. One for AFKL and other for BA. It calls build_soap_request/2 to generate xml request. It uses appropriate headers,url and xml_request body to send post request to provider. which returns an xml response if request is sucessful. Response body is parsed to get the minium offer by provider.
   In case of failed post request it returns error.
  """
  @spec get_data(%{:api_key => any, :id => any, optional(any) => any}, any) ::
          {:error, :failed | :not_found} | {:ok, %{airline: <<_::16>>, amount: float}}
  def get_data(%{id: id, api_key: nil}, _args) do
    Logger.error("Api key #{String.downcase(id)}_api_key for #{id} is not set in environment variables")
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

  def get_data(%{id: "AFKL"= id ,url: url, soap_action: soap_action, content_type: content_type, api_key: api_key}, args) do
    xml_request = build_soap_request(id, args)
    headers = ["Content-Type": content_type, SOAPAction: soap_action, api_key: api_key]
    Logger.info("getting offers from #{id}")
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

  @doc """
   Takes provider id and request parameters as input. This function has different implementation for each provider. It concatinates request paramaters in request body
  """
  @spec build_soap_request(<<_::16>>, %{
          :departure_date => any,
          :destination => any,
          :origin => any,
          optional(any) => any
        }) :: <<_::64, _::_*8>>
  def build_soap_request("BA", %{origin: origin, destination: destination, departure_date: departure_date}) do
    "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\"><s:Body xmlns=\"http://www.iata.org/IATA/EDIST\"><AirShoppingRQ Version=\"3.0\" xmlns=\"http://www.iata.org/IATA/EDIST\"><PointOfSale><Location><CountryCode>DE</CountryCode></Location></PointOfSale><Document/><Party><Sender><TravelAgencySender><Name>test agent</Name><IATA_Number>00002004</IATA_Number><AgencyID>test agent</AgencyID></TravelAgencySender></Sender></Party><Travelers><Traveler><AnonymousTraveler><PTC Quantity=\"1\">ADT</PTC></AnonymousTraveler></Traveler></Travelers><CoreQuery><OriginDestinations><OriginDestination><Departure><AirportCode>#{origin}</AirportCode><Date>#{departure_date}</Date></Departure><Arrival><AirportCode>#{destination}</AirportCode></Arrival></OriginDestination></OriginDestinations></CoreQuery></AirShoppingRQ></s:Body></s:Envelope>"
  end

  def build_soap_request("AFKL", %{origin: origin, destination: destination, departure_date: departure_date}) do
    "<S:Envelope xmlns:S=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns=\"http://www.iata.org/IATA/2015/00/2018.2/IATA_AirShoppingRQ\"><S:Header/><S:Body><IATA_AirShoppingRQ><Party><Participant><Aggregator><AggregatorID>NDCABT</AggregatorID><Name>NDCABT</Name></Aggregator></Participant><Recipient><ORA><AirlineDesigCode>AF</AirlineDesigCode></ORA></Recipient><Sender><TravelAgency><AgencyID>12345675</AgencyID><IATANumber>12345675</IATANumber><Name>nom</Name><PseudoCityID>PAR</PseudoCityID></TravelAgency></Sender></Party><PayloadAttributes><CorrelationID>5</CorrelationID><VersionNumber>18.2</VersionNumber></PayloadAttributes><Request><FlightCriteria><OriginDestCriteria><DestArrivalCriteria><IATALocationCode>#{destination}</IATALocationCode></DestArrivalCriteria><OriginDepCriteria><Date>#{departure_date}</Date><IATALocationCode>#{origin}</IATALocationCode></OriginDepCriteria><PreferredCabinType><CabinTypeName>ECONOMY</CabinTypeName></PreferredCabinType></OriginDestCriteria></FlightCriteria><Paxs><Pax><PaxID>PAX1</PaxID><PTC>ADT</PTC></Pax></Paxs></Request></IATA_AirShoppingRQ></S:Body></S:Envelope>"
  end

  @doc """
   Takes provider if and xml response data by the provider as input. It uses xpath to get all the price offers by the provider and returns minimum of all prices. The method has seperate implementation for both providers.
  """
  @spec parse_response(<<_::16>>, any) ::
          {:error, :not_found} | {:ok, %{airline: <<_::16>>, amount: float}}
  def parse_response("BA"= id, data) do
    with price_list <- xpath(data, ~x"//TotalPrice/SimpleCurrencyPrice/text()"l), {:ok, minimum_price} <- get_minimum_price(price_list), {:ok, cheapest_price} <- char_list_to_float(minimum_price) do
      {:ok, %{amount: cheapest_price, airline: id}}
    else
      {:error, message} ->
        Logger.error("Couldn't parse required data from #{id}")
        {:error, message}
    end
  end

  def parse_response("AFKL"=id, data) do
    with price_list <- xpath(data, ~x"//ns2:FarePriceType/ns2:Price/ns2:TotalAmount/text()"l), {:ok, minimum_price} <- get_minimum_price(price_list), {:ok, cheapest_price} <- char_list_to_float(minimum_price) do
      {:ok, %{amount: cheapest_price, airline: id}}
    else
      {:error, message} ->
        Logger.error("Couldn't get required data from #{id}")
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
