require "sinatra"
require "sinatra/reloader"

get("/") do
  erb(:home)
end


get("/umbrella"){
  erb(:umbrella)
}
