require 'slim'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/streaming'

LowerThird = Struct.new(:name, :enabled) do
  def enabled?
    enabled == true
  end
end

set server: 'thin'
set connections: []
set names: %w{Name1 Name2 Name3}
set lts: Dir["public/lts/*.png"].map { |f| LowerThird.new(File.basename(f), true) }

get '/' do
  'open /overlay or /console'
end

get '/overlay' do
  @checkerboard = true if params.key?("checkerboard")
  slim :overlay
end

get '/console' do
  @names = settings.names
  @lts = settings.lts.select { |lt| lt.enabled? }.map { |lt| lt.name }
  slim :console
end

get '/admin' do
  @names = settings.names
  @lts = settings.lts
  slim :admin
end

post '/admin' do
  settings.lts = params[:lts].map { |k,v| LowerThird.new(k, v == "true") }
  settings.names = params[:names].split(/\r?\n/)
  redirect '/admin'
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
  204 # no content
end

