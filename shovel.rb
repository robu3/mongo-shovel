require "optparse"
require "yaml"
require "./mongo_shovel.rb"

# Shovel:
# Terminal utility for shoveling data into MongoDB

shovel = MongoShovel.new

options = {}
mongo_settings = {}
OptionParser.new do |opts|
	opts.banner = "Usage: shovel.rb FILENAME OPTIONS"

	opts.on("-d", "--delimiter [DELIMITER]", String, "The delimiter used to seperate columns in the file") do |delimiter|
		options[:delimiter] = delimiter
	end

	opts.on("--server [NAME]", "The MongoDB server name / IP address") do |name|
		mongo_settings[:server] = name
	end

	opts.on("--db [NAME]", "The MongoDB database name") do |db|
		mongo_settings[:db] = db
	end

	opts.on("--collection [COLLECTION]", "The MongoDB collection name") do |v|
		mongo_settings[:collection] = v
	end

	opts.on("-n", "--names", "Names in first row: true / false") do |v|
		options[:names_in_first_row] = v
	end

	opts.on("-t", "--types [FILENAME]", "YAML file containing column types / conversions") do |v|
		type_map= YAML::load(File.read(v))
		options[:type_converters] = shovel.generate_type_converters(type_map)
	end

	opts.on("-c", "--mongoconfig [FILENAME]", "YAML file containing the mongo connection settings; expected keys are server, port, db, collection (be careful with the last one)") do |v|
		# config file can override passed in settings, depending on order
		# please be careful!
		settings = YAML::load(File.read(v))
		# symbolize keys
		settings.each do |k, v|
			mongo_settings[k.to_sym] = v
		end
	end

	opts.on("-?", "--help", "Show this message") do
		puts opts
		exit
	end
end.parse!

#puts options
#puts mongo_settings
#puts ARGV

if options[:delimiter]
	shovel.import_delimited(ARGV[0], options[:delimiter], mongo_settings, options)
else
	puts "Only delimited files are supported at this time; please pass in a delimiter using -d or --delimiter"
end

