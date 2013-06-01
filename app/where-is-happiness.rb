#!/usr/bin/env ruby
# encoding: UTF-8
require 'sinatra'

get '/' do
  send_file('index.html')
end
