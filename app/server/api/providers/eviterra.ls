_           = require "underscore"
async       = require "async"
cache       = require "./../../cache"
database    = require "./../../database"
moment      = require "moment"
request     = require "request"
xml2js      = require "xml2js"

# Globals
parser = new xml2js.Parser(xml2js.defaults["0.1"])
moment.lang('ru')

# Providers
exports.name = "eviterra"

query = (origin, destination, extra, cb) ->

	evUrl = "http://api.eviterra.com/avia/v1/variants.xml?from=#{origin.place.iata}&to=#{destination.place.iata}&date1=#{origin.date}&adults=#{extra.adults}"

	(error, body) <- cache.request evUrl
	console.log "EVITERRA: Queried Eviterra serp | #{evUrl} | status: #{!!body}"
	return cb(error, null) if error

	(error, json) <- parser.parseString body
	return cb(error, null) if error

	cb null, json

process = (flights, cb) -> 
	if not flights or not flights.variant
		return cb({message: 'No flights found'}, null)

	for variant in flights.variant
		if variant.segment.flight.length?
			variant.transferNumber  = variant.segment.flight.length
			variant.firstFlight     = variant.segment.flight[0]
			variant.lastFlight      = variant.segment.flight[variant.transferNumber-1]
		
		else
			variant.transferNumber  = 1
			variant.firstFlight     = variant.segment.flight
			variant.lastFlight      = variant.firstFlight    

	allAirports   = []
	for variant in flights.variant
		allAirports.push variant.firstFlight.departure
		allAirports.push variant.lastFlight.arrival

	# todo add all list!
	allCarriers = _.map flights.variant, (variant) -> variant.firstFlight?.marketingCarrier?
	allCarriers = _.uniq allCarriers

	allAirports = _.uniq allAirports

	(err, airportsInfo) <- database.airports.find({iata:{$in:allAirports}}).toArray()
	(err, airlinesInfo) <- database.airports.find({iata:{$in:allCarriers}}).toArray()

	newFlights = []

	for variant in flights.variant
		
		arrivalDestinationDate  = moment variant.lastFlight.arrivalDate     + 'T' + variant.lastFlight.arrivalTime
		departureOriginDate     = moment variant.firstFlight.departureDate  + 'T' + variant.firstFlight.departureTime

		departureAirport        = _.filter( airportsInfo, (el) -> el.iata is variant.firstFlight.departure      )[0]
		arrivalAirport          = _.filter( airportsInfo, (el) -> el.iata is variant.lastFlight.arrival         )[0]

		carrier                 = _.filter( airlinesInfo, (el) -> el.iata is variant.lastFlight?.marketingCarrier?)[0]
		delete carrier._id if carrier

		return cb(
			{ message: "No airport found | departure: #{departureAirport} | arrival: #{arrivalAirport}" }, 
			null
		) if not(departureAirport and arrivalAirport)

		# UTC massage
		utcArrivalDate          = arrivalDestinationDate.clone().subtract 'hours', arrivalAirport.timezone  
		utcDepartureDate        = departureOriginDate.clone().subtract    'hours', departureAirport.timezone

		flightTimeSpan          = utcArrivalDate.diff utcDepartureDate,   'hours'
		flightTimeSpan          = 1 if (flightTimeSpan is 0)

		newFlight = 
			arrival   : arrivalDestinationDate.format "hh:mm"#\LL
			carrier   : carrier
			departure : departureOriginDate.format "hh:mm"#\LL
			duration  : flightTimeSpan * 60 * 60
			price     : parseInt variant.price
			provider  : \eviterra
			stops     : variant.transferNumber - 1
			url       : variant.url + \ostroterra

		newFlights.push newFlight

	cb null, do
		results : newFlights
		complete: true

exports.search = (origin, destination, extra, cb) ->
	(error, json)     <- query origin, destination, extra
	return cb(error, null) if error
	
	(error, results)  <- process json
	return cb(error, null) if error

	cb null, results
