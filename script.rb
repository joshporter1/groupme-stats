require 'elasticsearch'
require 'rest-client'
require 'date'
require 'yaml'
require 'json'
require 'csv'

# load the config 
config = YAML.load_file('config.yml')
TOKEN = config['token']
GROUP_ID = config['group_id']
ES_HOST = config['es_host']

# API setup
BASE_URI = "https://api.groupme.com/v3"
GROUP_MESSAGES = "/groups/#{GROUP_ID}/messages"
GROUP_INFO = "/groups/#{GROUP_ID}"

# message param defaults
before_id = ''
max = 100

# es client
client = Elasticsearch::Client.new host: ES_HOST

data = []
room_info = JSON.parse(RestClient.get BASE_URI + GROUP_INFO, {params: {access_token: TOKEN}})['response']

CSV.open("kicks.csv", "wb") do |csv|
  headers = ['id', 'timestamp', 'event.type', 'adder_user', 'added_user', 'remover_user', 'removed_user', 'rejoined_user', 'raw']
  csv << headers

  pages = room_info['messages']['count']/max

  (0..pages).each do |i|
    response = JSON.parse(RestClient.get BASE_URI + GROUP_MESSAGES, {
      params: {
        access_token: TOKEN,
        before_id: before_id,
        limit: max
      }
    })['response']['messages']

    before_id = response.last['id']

    events = response.each { |e|
      data.push e
      # index the message. TODO: bulk insert
      client.index index: "groupme_logs_#{GROUP_ID}", type: 'message', id: e['id'], body: e
    }
    p before_id
  end
end

# write data to files
File.open("datadump_#{GROUP_ID}.json","w") do |f|
  f.write(data.to_json)
end
File.open("roominfo_#{GROUP_ID}.json","w") do |f|
  f.write(room_info.to_json)
end

