require "sinatra"
require "sinatra/reloader"
require "http"
require "json"
require "sinatra/cookies"

get("/") do
  erb(:home)
end


get("/umbrella"){
  erb(:umbrella)
}

post("/process_umbrella"){
  # binding.irb

  @location = params.fetch("location").to_s

  # option 1
  # CGI.escape(@location)

  # option 2
  # create hash with query string keys/values and convert to query string


  GMAPS_URI = "https://maps.googleapis.com/maps/api/geocode/json?address=#{CGI.escape(@location)}&key=#{ENV.fetch("GMAPS_KEY")}"

  gmaps_req = HTTP.get(GMAPS_URI)

  gmaps_res = JSON.parse(gmaps_req)

  location = gmaps_res.dig("results", 0, "geometry", "location")
  @lat, @lng = location.dig("lat"), location.dig("lng")
  # @lat = gmaps_res.fetch("results").at(0).fetch("geometry").fetch("location").fetch("lat")
  # @lng = gmaps_res.fetch("results").at(0).fetch("geometry").fetch("location").fetch("lng")

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

  @reply = @parsed_response.dig("choices", 0, "message", "content")

  erb(:message_result)
}

get("/chat"){


  if (cookies["chat_history"] == nil)
    cookies["chat_history"] = JSON.generate([])
  end


  erb(:chat)
}

post("/chat"){

  @user_message = params.fetch("user_input")

  request_headers_hash = {
    "Authorization" => "Bearer #{ENV.fetch("GPT_KEY")}",
    "content-type" => "application/json"
  }

  request_body_hash = {
    "model" => "gpt-3.5-turbo",
    "messages": [
    {
      "role": "user",
      "content": @user_message
    }
  ]
  }

  request_body_json = JSON.generate(request_body_hash)

  raw_response = HTTP.headers(request_headers_hash).post(
    "https://api.openai.com/v1/chat/completions",
    :body => request_body_json
  )

  @chat_history = JSON.parse(cookies["chat_history"]) #is array

  @parsed_response = JSON.parse(raw_response).dig("choices", 0, "message") #is hash

  @chat_history.push({"role": "user", "content": @user_message})
  @chat_history.push(@parsed_response)
  cookies["chat_history"] = JSON.generate(@chat_history)
  

  erb(:chat)
}
