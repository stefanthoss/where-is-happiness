#!/usr/bin/env ruby
# encoding: UTF-8
require 'sinatra'
require 'yaml'
require 'mysql2'
require 'json'

config = YAML.load_file('../config.yml')

set :environment, :development

get '/slides' do
  redirect "/slides/index.html"
end

get '/getstreampoints' do
  client = Mysql2::Client.new(:host => config['db']['host'],
    :username => config['db']['username'],
    :password => config['db']['password'],
    :database => config['db']['database'],
    :host => config['db']['host'])

  points = Hash.new
  points['tweets'] = []

  from_id = params[:fromid].nil? ? -1 : params[:fromid].to_i

  if params[:keyword].nil? || params[:keyword].empty?
    points['lastid'] = from_id
    query = "SELECT * FROM tweets WHERE id > #{from_id}"
    tweets = client.query(query)
    tweets.each do |tweet|
      points['tweets'] << { 'lat' => tweet['lat'], 'lon' => tweet['lng'] }
      points['lastid'] = tweet['id']
    end
  else
    points['lastid'] = from_id
    params[:keyword].split(',').each do |keyword|
      query = "SELECT * FROM tweets WHERE id > #{from_id} AND text LIKE \"%#{keyword}%\""
      tweets = client.query(query)
      tweets.each do |tweet|
        points['tweets'] << { 'lat' => tweet['lat'], 'lon' => tweet['lng'] }
        points['lastid'] = [points['lastid'], tweet['id'].to_i].max
      end
    end
  end


  client.close
  points.to_json
end

get '/getpositivepoints' do
  client = Mysql2::Client.new(:host => config['db']['host'],
    :username => config['db']['username'],
    :password => config['db']['password'],
    :database => config['db']['database'],
    :host => config['db']['host'])

  points = Hash.new
  points['tweets'] = []

  from_id = params[:fromid].nil? ? -1 : params[:fromid]

  query = "SELECT * FROM tweets WHERE id > #{from_id} AND mood_pos > 0 AND mood_neg = 0"

  points['lastid'] = from_id
  tweets = client.query(query)
  tweets.each do |tweet|
    points['tweets'] << { 'lat' => tweet['lat'], 'lon' => tweet['lng'], 'weight' => tweet['mood_pos'] }
    points['lastid'] = tweet['id']
  end

  client.close
  points.to_json
end

get '/getnegativepoints' do
  client = Mysql2::Client.new(:host => config['db']['host'],
    :username => config['db']['username'],
    :password => config['db']['password'],
    :database => config['db']['database'],
    :host => config['db']['host'])

  points = Hash.new
  points['tweets'] = []

  from_id = params[:fromid].nil? ? -1 : params[:fromid]

  query = "SELECT * FROM tweets WHERE id > #{from_id} AND mood_neg > 0 AND mood_pos = 0"

  points['lastid'] = from_id
  tweets = client.query(query)
  tweets.each do |tweet|
    points['tweets'] << { 'lat' => tweet['lat'], 'lon' => tweet['lng'], 'weight' => tweet['mood_neg'] }
    points['lastid'] = tweet['id']
  end

  client.close
  points.to_json
end

get '/getpopulation' do
  client = Mysql2::Client.new(:host => config['db']['host'],
    :username => config['db']['username'],
    :password => config['db']['password'],
    :database => config['db']['database'],
    :host => config['db']['host'])

  points = []

  query = "SELECT * FROM population WHERE lng BETWEEN -122.519746 AND -121.839967 AND lat BETWEEN 37.234702 AND 37.823887"

  population = client.query(query)
  population.each do |point|
    points << { 'lat' => point['lat'], 'lon' => point['lng'], 'weight' => point['population2000'] }
  end

  client.close
  points.to_json
end
