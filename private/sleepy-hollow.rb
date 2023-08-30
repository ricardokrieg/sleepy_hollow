require 'ai4r'
require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

client = Mongo::Client.new('mongodb://stark:passtrash123@ds063892.mongolab.com:63892/general')

client[:sleepyhollow_races].find.each do |race|
    puts race
end

net = Ai4r::NeuralNetwork::Backpropagation.new([4, 3, 2])

1000.times do |i|
    net.train(example[i], result[i])
end

net.eval([12, 48, 12, 25])
