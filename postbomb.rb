require 'net/http'
require 'net/https'
require 'uri'
require 'json'

$counter = 0
puts 'How many calls to perform? (e.g. 1000)'
i = gets.chomp.to_i || 100

def send_json
  # uri = URI.parse("https://api.yotpo.com/v1/widget/reviews")
  uri = URI.parse("https://api.yotpo.com/reviews/dynamic_create")
  header = {'Content-Type': 'application/json','User-Agent': 'hxii/rb'}
  body = {
    "appkey": "7F6qsTFeWlOGgJksj8mkdKeNv0XRK75SoGIkdIhI",
    "domain": "https://fantailoriginals.com",
    "sku": "4421099913290",
    "product_title": "SENIOR SWELL  - GLE ENGLISH WILLOW BAT",
    "product_description": "",
    "product_url": "https://fantailoriginals.com/products/senior-swell-gle-english-willow",
    "product_image_url": "https://cdn.shopify.com/s/files/1/0986/8642/products/swell_main_GREY_large.jpg%3Fv=1580266614",
    "display_name": "Yotpo",
    "email": "pglushak+rbtest1@yotpo.com",
    "review_content": "One of the best I've ever tried",
    "review_title": "Would definitely buy again some time best product ever",
    "review_score": "5"
  }
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new(uri.request_uri, header)
  request.body = body.to_json
  response = http.request(request)
  time1 = Time.new
  puts '(' + $counter.to_s + ') ' + time1.inspect + " " + response.code.to_s
end

# send_json()

puts 'Starting bombardment..'

while $counter < i do
  send_json()
  $counter += 1
  sleep rand(0..3)
  #sleep 300
end
