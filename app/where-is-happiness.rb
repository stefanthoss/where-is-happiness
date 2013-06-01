#!/usr/bin/env ruby
# encoding: UTF-8
require 'sinatra'
require 'yaml'
require 'mysql2'
require 'json'

config = YAML.load_file('../config.yml')

set :environment, :development

get '/getstreampoints' do
client = Mysql2::Client.new(:host => config['db']['host'],
  :username => config['db']['username'],
  :password => config['db']['password'],
  :database => config['db']['database'],
  :host => config['db']['host'])

  points = Hash.new
  points['tweets'] = []

  from_id = params[:fromid].nil? ? -1 : params[:fromid]

  unless params[:keyword].nil?
    query = "SELECT * FROM tweets WHERE id > #{from_id} AND text LIKE \"%#{params[:keyword]}%\""
  else
    query = "SELECT * FROM tweets WHERE id > #{from_id}"
  end

  tweets = client.query(query)
  tweets.each do |tweet|
    points['tweets'] << { 'lat' => tweet['lat'], 'lon' => tweet['lng'] }
    points['lastid'] = tweet['id']
  end

 points.to_json
end
