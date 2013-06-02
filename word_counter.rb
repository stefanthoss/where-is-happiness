require 'yaml'
require 'mysql2'

config = YAML.load_file('config.yml')

client = Mysql2::Client.new(:host => config['db']['host'],
  :username => config['db']['username'],
  :password => config['db']['password'],
  :database => config['db']['database'],
  :host => config['db']['host'])

query = "SELECT * FROM tweets"

words = {}

tweets = client.query(query)
tweets.each do |tweet|
  tweet['text'].split(" ").each do |word|
    word = word.downcase
    if word.length >= 3
      if words[word].nil?
        words[word] = 0
      else
        words[word] = words[word] + 1
      end
    end
  end
end

words_sorted = words.sort_by { |w, c| c }

words_sorted.each do |word|
  puts "#{word[1].to_s.rjust(5, '0')}: #{word[0]}"
end
