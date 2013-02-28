# MongoShovel
_Shoveling flat files into MongoDB_

## Why?
Because mongoimport is somewhat [limited](https://groups.google.com/forum/?hl=en&fromgroups=#!searchin/mongodb-user/mongoimport$20delimited/mongodb-user/ihTAYsI1ddA/hObYuGeP2k0J) in the types of flat files it can load.

## Usage
ruby shovel.rb test_data\test_data.csv -d "|" -c test_data\conn.yml --collection "test_data" -t test_data\test_data.yml -n
