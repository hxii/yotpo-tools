require 'csv'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'optparse'

$options = {}
$ver = '2020.03.30'

puts "Pubunpub - mass publishing and unpublishing of reviews."
puts "made by Paul Glushak"
puts "version " + $ver

optparse = OptionParser.new do|opts|
	opts.banner = 'Usage: pubunpub.rb [options]'
	$options[:publish] = true
	opts.on( "-p", "--[no-]publish", "Publish reviews" ) do |pub|
		$options[:publish] = pub
	end
	$options[:unpublish] = true
	opts.on( "-u", "--[no-]unpublish", "Unpublish reviews" ) do |unpub|
		$options[:unpublish] = unpub
	end
	opts.on( "-f", "--file FILENAME", "CSV file to process (Mandatory)") do |file|
		$options[:file] = file
	end
	opts.on( "-t", "--token UTOKEN", "Utoken to use (Mandatory)") do |token|
		$options[:utoken] = token
	end
	$options[:chunk] = 1000
	opts.on( "-c", "--chunk SIZE", "Chunk size to process reviews by (default: 1000)") do |chunk|
		$options[:chunk] = chunk
	end
	$options[:sleep] = 40
	opts.on( "-s", "--sleep TIME", "Minutes to sleep inbetween unpublishing and publishing (default: 40)") do |sleep|
		$options[:sleep] = sleep
	end
end.parse!

raise OptionParser::MissingArgument if $options[:file].nil? || $options[:utoken].nil?

$data = []

def process_csv
  CSV.foreach(File.expand_path($options[:file])) do |row|
  	$data << row[0].to_i
  end
  $data.shift
end

def async_update(deleted,data)
	# puts (deleted == true ? 'Starting unpublishing...' : 'Starting publishing...')
	uri = URI.parse("https://api-write.yotpo.com/reviews/async_update")
	header = {'Content-Type': 'application/json','User-Agent': 'hxii/rb'}
	body = {
	    "utoken": $options[:utoken],
	    "review_ids": data,
	    "review_action": "update",
	    "attributes": {
	        "deleted": deleted
	    },
	    "sync": true
	}
	http = Net::HTTP.new(uri.host, uri.port)
	http.read_timeout = 120
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	request = Net::HTTP::Put.new(uri.request_uri, header)
	request.body = body.to_json
	response = http.request(request)
	puts response.code.to_s
	if response.code.to_i > 200
		puts 'Invalid response ' + response.code.to_s
	end
end

process_csv()

puts 'Processing ' + $data.count.to_s + ' reviews in ' + ($data.count.to_f / $options[:chunk].to_i).ceil.to_s + ' chunks...'

$count = 1
$data.each_slice($options[:chunk].to_i) do |chunk|
	if $options[:unpublish]
		print '[Chunk ' + $count.to_s + '] Unpublishing - '
		async_update(true,chunk)
	end
	$count += 1
end
puts 'Sleeping for ' + $options[:sleep].to_s + ' minutes...'
sleep(($options[:sleep].to_i) * 60)
$count = 1
$data.each_slice($options[:chunk].to_i) do |chunk|
	if $options[:publish]
		print '[Chunk ' + $count.to_s + '] Publishing - '
		async_update(false,chunk)
	end
	$count += 1
end