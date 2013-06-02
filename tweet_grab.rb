require 'tweetstream'
require 'afinn_analyzer'
require 'yajl'
require 'yaml'
require 'mysql2'

config = YAML.load_file('config.yml')

TweetStream.configure do |twitter_config|
  twitter_config.consumer_key       = config['twitter']['consumer_key'].to_s
  twitter_config.consumer_secret    = config['twitter']['consumer_secret'].to_s
  twitter_config.oauth_token        = config['twitter']['oauth_token'].to_s
  twitter_config.oauth_token_secret = config['twitter']['oauth_token_secret'].to_s
  twitter_config.auth_method        = :oauth
end

analyzer = AfinnAnalyzer.new "AFINN-111.txt"

def format_time time
 time.nil? ?  "NULL" : "\"#{time.utc.to_s[0..18]}\""
end

# CREATE TABLE wih.tweets (id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT, text VARCHAR(255), time DATETIME, lat DOUBLE, lng DOUBLE, mood_pos INTEGER, mood_neg INTEGER);

client = Mysql2::Client.new(:host => config['db']['host'],
  :username => config['db']['username'],
  :password => config['db']['password'],
  :database => config['db']['database'],
  :host => config['db']['host'])

tweetstream = TweetStream::Client.new

puts "Start streaming tweets..."

tweetstream.on_error do |message|
  puts "Error: #{message}"
end

tweetstream.on_limit do |skip_count|
  puts "Limit: #{skip_count}"
end

tweetstream.on_reconnect do |timeout, retries|
  puts "Timeout: #{timeout}, retries: #{retries}"
end

#SW: 37.234702,-122.519746
#NE: 37.823887,-121.839967
tweetstream.locations("-122.519746,37.234702,-121.839967,37.823887") do |status|
  unless status.geo.nil?
    lat = status.geo.coordinates[0].to_f
    lng = status.geo.coordinates[1].to_f
  # else
  #   lat = status.place.bounding_box.coordinates[0][0][1].to_f
  #   lng = status.place.bounding_box.coordinates[0][0][0].to_f
  # end
  mood = analyzer.analyze status.text
  # puts "#{status.created_at} - #{lat},#{lng} - #{status.text}"
  query = "INSERT INTO tweets (text, time, lat, lng, mood_pos, mood_neg) VALUES (\"#{client.escape(status.text)}\", #{format_time(status.created_at)}, #{lat}, #{lng}, #{mood[:positive]}, #{mood[:negative]})"
  puts query
  client.query query
end
