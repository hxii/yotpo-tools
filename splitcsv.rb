require 'csv'
require 'optparse'

$options = {}

ARGV << '-h' if ARGV.empty?

optparse = OptionParser.new do|opts|
	opts.banner = "Usage: splitcsv.rb [options]"
	$options[:header] = true
	opts.on( "-h", "--[no-]header", "CSV Includes header") do |header|
		$options[:header] = header
	end
	$options[:split] = 1000
	opts.on( "-s", "--split COUNT", "How many lines to split by (default: 1000)" ) do |split|
		$options[:split] = split
	end
	opts.on( "-f", "--file FILE", "File to process" ) do |file|
		$options[:file] = file
	end
end.parse!

# raise OptionParser::MissingArgument if $options[:file].nil?

$header = []
$data = []

def parse_csv
	$data = File.read(File.expand_path($options[:file])).split("\n")
	if $options[:header]
		$header = $data[0]
		$data = $data.drop(1)
	end
end

def split_csv
	count = 0
	$data.each_slice($options[:split].to_i) do |item|
		filename = File.basename(File.expand_path($options[:file]), ".csv") 
		file = File.open("#{filename}_#{count}.csv","w")
		file.puts $header
		file.puts item
		count += 1
	end
end

parse_csv()
split_csv()
