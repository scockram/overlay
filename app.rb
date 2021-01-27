require 'slim'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/streaming'

set server: 'thin'
set connections: []

get '/' do
  'open console or overlay...'
end

get '/overlay' do
  @checkerboard = true if params.key?("checkerboard")
  slim :overlay
end

get '/console' do
  @names = %w{Name1 Name2 Name3}
  @lts = Dir["public/lts/*"].map { |f| File.basename(f) }
  print @lts
  slim :console
end

get '/feed', provides: 'text/event-stream'  do
  stream :keep_open do |out|
    settings.connections << out
    out.callback { settings.connections.delete(out) }
  end
end

post '/feed' do
  data = request.body.read
  settings.connections.each do |out|
    out << "data: #{data}\n\n"
  end
  204
end

