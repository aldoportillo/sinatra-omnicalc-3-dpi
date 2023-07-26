require "sinatra"
require "sinatra/reloader"

get("/") do
  erb(:home)
end


get("/umbrella"){
  erb(:umbrella)
}

post("/process_umbrella"){

  @location = params.fetch("location")

  GMAPS_URI = "https://maps.googleapis.com/maps/api/geocode/json?address=#{@location}&key=#{ENV.fetch("GMAPS_KEY")}"

  gmaps_req = HTTP.get(GMAPS_URI)

  gmaps_res = JSON.parse(gmaps_req)

  lat = gmaps_res.fetch("results").at(0).fetch("geometry").fetch("location").fetch("lat")
  lng = gmaps_res.fetch("results").at(0).fetch("geometry").fetch("location").fetch("lng")

  PIRATE_URI = "https://api.pirateweather.net/forecast/#{ENV.fetch("PIRATE_WEATHER_KEY")}/#{lat},#{lng}"

  pirate_req = HTTP.get(PIRATE_URI) 
  pirate_res = JSON.parse(pirate_req) 

  @output = pirate_res

  erb(:umbrella_output)
}
