require 'ai4r'
require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

client = Mongo::Client.new('mongodb://potyshopping.com.br:3001/meteor')

horse_data = {}

client[:sleepyhollow_horses].find.each do |horse|
    n_runners = client[:sleepyhollow_runners].find({horse_id: horse['_id']}).count

    horse_data[n_runners] ||= 0
    horse_data[n_runners] += 1
end

p horse_data

# net = Ai4r::NeuralNetwork::Backpropagation.new([4, 3, 2])

# 1000.times do |i|
#     net.train(example[i], result[i])
# end

# net.eval([12, 48, 12, 25])
