# AirlineApiAggregator

To start your Phoenix server:

  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `mix phx.server`

## Environment Variables
Please set api key as environment variables before accessing the api.

we are using two api keys:

ba_api_key=YOUR_KEY  #For British Airways (BA)

afkl_api_key=YOUR_KEY #For Air France / KLM (AFKL)

## API End Point
To access findCheapestOffer api, send get request to http://localhost:4000/findCheapestOffer with parameters:

origin=BER

destination=LHR

departureDate=2021-10-17

or access http://localhost:4000/findCheapestOffer?origin=BER&destination=LHR&departureDate=2021-10-17

