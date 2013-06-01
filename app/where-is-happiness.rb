#!/usr/bin/env ruby
# encoding: UTF-8
require 'sinatra'
require 'yaml'
require 'mysql2'
require 'json'

config = YAML.load_file('../config.yml')

set :environment, :development

client = Mysql2::Client.new(:host => config['db']['host'],
  :username => config['db']['username'],
  :password => config['db']['password'],
  :database => config['db']['database'],
  :host => config['db']['host'])

get '/getstreampoints' do
  points = Hash.new
  points['tweets'] = []
  
if #{params[:fromid]}.nil?
  query =  "SELECT * FROM tweets"
else
  query =  "SELECT * FROM tweets WHERE id > #{params[:fromid]}"
end

tweets = client.query(query)
tweets.each do |tweet|
  points['tweets'] << { 'lat' => tweet['lat'], 'lon' => tweet['lng'] }
  points['lastid'] = tweet['id']
end

 points.to_json
end
