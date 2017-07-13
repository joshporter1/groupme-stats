require 'date'
require 'rest-client'
require 'json'
require 'csv'

token = ''
group_id = 0
base_uri = "https://api.groupme.com/v3/groups/#{group_id}/messages"

# before_id
# string — Returns messages created before the given message ID
# since_id
# string — Returns most recent messages created after the given message ID
# after_id
# string — Returns messages created immediately after the given message ID
# limit
# integer — Number of messages returned. Default is 20. Max is 100.

before_id = ''
max = 100

CSV.open("kicks.csv", "wb") do |csv|
  headers = ['id', 'timestamp', 'event.type', 'adder_user', 'added_user', 'remover_user', 'removed_user', 'rejoined_user', 'raw']
  csv << headers


  (0..100000).each do |i|
    response = JSON.parse(RestClient.get base_uri, {
      params: {
        access_token: token,
        before_id: before_id,
        max: max
      }
    })['response']['messages']

    before_id = response.last['id']

    events = response.each { |e|
      row = [e['id'], DateTime.strptime(e['created_at'].to_s, '%s').to_s]
      if e['event']
        row.push(e['event']['type'])
        row.push((e['event']['data']['adder_user']['nickname'] rescue ''))
        row.push((e['event']['data']['added_users'].map { |e| e['nickname'] }.join(' ') rescue ''))
        row.push((e['event']['data']['remover_user']['nickname'] rescue ''))
        row.push((e['event']['data']['removed_user']['nickname'] rescue ''))
        row.push((e['event']['data']['user']['nickname'] rescue ''))
        # if e['event']['type'] == 'membership.notifications.removed'
        #   row.concat [e['event']['type'], e['event']['data']['remover_user']['nickname'], e['event']['data']['removed_user']['nickname']]
        # elsif e['event']['type'] == 'membership.announce.added'
        #   row.concat [e['event']['type'], e['event']['data']['adder_user']['nickname'], e['event']['data']['added_users'].first['nickname']]
        # end
      end
      row.push(e)
      csv << row
    }

    p before_id
  end
end
