require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'yaml'

$errors = {}
$counter = 0
$today = Date.today().strftime("%Y.%m.%d")
$filename = "error_#{$today}.json"
$interval = 5

def get_data
  uri = URI.parse("http://10.1.7.137:9200/api-unicorns-write-stdout-" + $today + "/_search")
  header = { 'Content-Type': 'application/json','User-Agent': 'hxii/rb' }
  body = {
    "size": 5000,
    "query": {
      "bool": {
        "must": [
          {
            "match": { "log_tag": "purchases_controller" }
          },
          {
            "match": { "severity": "ERROR" }
          },
          {
            "range": { "@timestamp": { "gte": "now-#{$interval}m", "lte": "now" } }
          }
        ]
      }
    },
    "sort": {
      "@timestamp": { "order": "desc" }
    },
    "_source": [
      "@timestamp",
      "account_id_num",
      "error1",
      "platform"
    ]
  }
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.request_uri, header)
  request.body = body.to_json
  response = http.request(request)
  return JSON.parse(response.body)['hits']['hits']
end

def parse_data(data)
	puts "[#{Time.now.utc}] - Got #{data.count} errors"
	unless $errors.has_key?('total')
		$errors['total'] = 0
	end
  data.each do |item|
    account_id = item['_source']['account_id_num']
    if item['_source']['error1'].nil?
      next
    end
    $counter += 1
    unless $errors[account_id]
      $errors[account_id] = Hash.new
    end
    unless $errors[account_id]['errors']
      $errors[account_id]['errors'] = Hash.new
    end
    unless $errors[account_id].has_key?('total')
      $errors[account_id]['total'] = 0
    end
    $errors[account_id]['total'] += 1
    platform = item['_source']['platform']
    error = item['_source']['error1'].match(/(?<=:error=>")\w+[^"]*/)[0] + ' - ' + item['_source']['error1'].match(/(?<=:field=>")\w+[^"]*/)[0]
    order = item['_source']['error1'].match(/(?<=:order_id=>")[a-zA-Z0-9\-_#.][^"]*/)
    $errors[account_id]['platform'] = platform
    unless $errors[account_id]['errors'].has_key?(error)
      if !order.nil?
        $errors[account_id]['errors'][error] = []
      else
        $errors[account_id]['errors'][error] = 0
      end
    end

    if !order.nil?
    	
      if !$errors[account_id]['errors'][error].include? order[0].to_s
        $errors[account_id]['errors'][error].push(order[0].to_s)
      else
    	next
      end
    else
      $errors[account_id]['errors'][error] += 1
    end
  end
  $errors['total'] = $counter
end

def read_log
	if File.exists?(File.expand_path($filename)) && !File.empty?(File.expand_path($filename))
		file = File.open(File.expand_path($filename), 'r')
		$errors = JSON.parse(file.read)
		$counter = $errors['total']
	end
end

def write_log(data)
	file = File.open(File.expand_path($filename), 'w')
	file.write(data.to_json)
	file.close
end

(15).times do
	read_log()
	parse_data(get_data())
	write_log($errors)
	sleep ($interval * 60 - 5)
end
