require "mongo"
require "time"
include Mongo

# MongoShovel:
# Shovels data in any flat-file format into mongodb
class MongoShovel

	# imports a delimited file
	def import_delimited(filename, delimiter, mongo_settings, opts)
		# initialize opts
		opts ||= {}
		opts[:names_in_first_row] ||= false
		opts[:qualifier] ||= nil

		qualifier = opts[:qualifier]
		type_converters = opts[:type_converters]

		# init mongo settings
		mongo_settings[:port] ||= 27017
		
		if (!mongo_settings[:db] || !mongo_settings[:collection])
			puts "Please specify a database and collection to import into"
			return
		end

		@client = MongoClient.new(mongo_settings[:server], mongo_settings[:port])
		@db = @client.db(mongo_settings[:db])
		@coll = @db.collection(mongo_settings[:collection])

		# make sure file exists
		if !File.exists?(filename)
			puts "The specified file is inaccessible: #{filename}"
		else
			# set column names
			# read first row of data for names
			names = []
			File.open(filename) do |file|
				file.each do |line|
					names = get_values(line, delimiter, qualifier)
					break
				end
			end

			# use column index for column names in the absence of actual names
			if !opts[:names_in_first_row]
				i_names = []
				(0...names.length).each do |i|
					i_names.push(i.to_s)
				end
				names = i_names
			end

			#puts names

			# open file
			File.open(filename) do |file|
				# skip first row if it contains column names
				skip = opts[:names_in_first_row]

				file.each do |line|
					if skip
						skip = false
						next
					end

					# build data object
					data = get_values(line, delimiter, qualifier)
					obj = {}
					
					(0...data.length).each do |i|
						obj[names[i]] = data[i]
					end

					insert_data(@coll, obj, type_converters)
				end
			end
		end
	end

	# returns values from the specified data row
	def get_values(row, delimiter, qualifier)
		# remove final carriage return
		row.slice!(row.length - 1)
		vals = row.split(delimiter)

		if qualifier
			qsize = qualifer.length
			vals.each do |v|
				v.slice!(qsize, v.length - (qsize * 2))
			end
		end	

		vals
	end

	# inserts the specified hash of data into the specified collection
	# doing type conversions as necessary
	def insert_data(coll, data, converters)
		# convert t
		if converters
			converters.each do |key, prc|
				if data.has_key?(key)
					data[key] = prc.call(data[key])
				end
			end
		end

		# insert it
		coll.insert(data)
	end

	# generates a hashtable of type converters for use with data import
	# map: a map of column name => datatype
	def generate_type_converters(map)
		# type => converter hash
		procs = {
			"integer" => (Proc.new do |str|
				str.to_i
			end),

			"float" => (Proc.new do |str|
				str.to_f
			end),

			"datetime" => (Proc.new do |str|
				begin
					Time.parse(str)
				rescue
					# invalid date
					puts "invalid date: #{str}"
					str
				end
			end)
		}

		# build return hash of converters, keyed by field
		converters = {}

		map.each do |k, v|
			if procs.has_key?(v)
				converters[k] = procs[v]
			else
				raise StandardError.new("Converter not available for datatype: #{v}")
			end
		end

		converters
	end
end
