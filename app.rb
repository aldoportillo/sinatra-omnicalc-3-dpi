require "sinatra"
require "sinatra/reloader"
require "http"
require "json"

get("/") do
  erb(:home)
end


get("/umbrella"){
  erb(:umbrella)
}

post("/process_umbrella"){

  @location = params.fetch("location").to_s

  GMAPS_URI = "https://maps.googleapis.com/maps/api/geocode/json?address=#{@location}&key=#{ENV.fetch("GMAPS_KEY")}"

  gmaps_req = HTTP.get(GMAPS_URI)

  gmaps_res = JSON.parse(gmaps_req)

  @lat = gmaps_res.fetch("results").at(0).fetch("geometry").fetch("location").fetch("lat")
  @lng = gmaps_res.fetch("results").at(0).fetch("geometry").fetch("location").fetch("lng")

  PIRATE_URI = "https://api.pirateweather.net/forecast/#{ENV.fetch("PIRATE_WEATHER_KEY")}/#{@lat},#{@lng}"

  pirate_req = HTTP.get(PIRATE_URI) 
  pirate_res = JSON.parse(pirate_req) 

  @current_temp = pirate_res.fetch("currently").fetch("temperature")
  @summary = pirate_res.fetch("currently").fetch("summary")

  hourly_data_arr = pirate_res.fetch("hourly").fetch("data").slice(0,10)

  @rain = false

  hourly_data_arr.each{|hour|
    if(hour.fetch("precipProbability") > 0.10)
      @rain = true
    end

  }

  @output = @rain ? "You might want to carry an umbrella" : "You probably won't need an umbrella today"

  erb(:umbrella_output)
}

get("/message"){
  erb(:message)
}

post("/process_single_message"){

  @single_message = params.fetch("single_message")

  request_headers_hash = {
  "Authorization" => "Bearer #{ENV.fetch("GPT_KEY")}",
  "content-type" => "application/json"
}

  request_body_hash = {
    "model" => "gpt-3.5-turbo",
    "messages" => [
      {
        "role" => "user",
        "content" => @single_message
      }
    ]
  }

  request_body_json = JSON.generate(request_body_hash)

  raw_response = HTTP.headers(request_headers_hash).post(
    "https://api.openai.com/v1/chat/completions",
    :body => request_body_json
  )

  @parsed_response = JSON.parse(raw_response)

  erb(:message_result)
}
