require 'sinatra/reloader' if development?
require 'sinatra/streaming'

DATA_YML = 'data.yml'

LowerThird = Struct.new(:name, :enabled) do
  def enabled?
    enabled == true
  end
end

if File.exists?(DATA_YML)
  data = YAML.load(File.read(DATA_YML))
  set names: data[:names]
  set lts: data[:lts]
else
  set names: %w{Name1 Name2 Name3}
  set lts: []
end

# Also add any LT images that are in the folder but not known about. This also
# handles the case of there being no config file (all LT's are unknown at that
# point)
Dir["public/lts/*.png"].map { |f| File.basename(f) }.each do |f|
  unless settings.lts.any? { |lt| lt.name == f }
    settings.lts.append LowerThird.new(f, true)
  end
end

# Also have to do the opposite, any thought-to-be LT's that no longer exist, have
# to be removed
set lts: settings.lts.select { |lt| File.exists?(File.join('public', 'lts', lt.name)) }

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
  File.open DATA_YML, "w" do |file|
    file.write({names:settings.names, lts:settings.lts}.to_yaml)
  end
  redirect '/admin'
end

# Deals with the posting/subscription model, basically websockets where every
# listener gets every event.
set connections: []

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

