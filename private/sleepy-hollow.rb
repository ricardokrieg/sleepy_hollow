require 'ai4r'
require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

client = Mongo::Client.new('mongodb://stark:passtrash123@ds063892.mongolab.com:63892/general')

client[:sleepyhollow_races].find.each do |race|
    puts race
end
