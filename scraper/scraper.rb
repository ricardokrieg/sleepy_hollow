require 'nokogiri'
require 'open-uri'
require 'json'
require 'fileutils'
require 'colorize'

# require './lib/database.rb'

class Scraper
    def self.get_race_urls(base_url, dates)
        dates.map do |date|
            url = "#{base_url}/daypage?date=#{date}"
            puts url

            html = Nokogiri::HTML(open(url))

            html.css('li.full a:first-child').map {|a| base_url + a.attr('href')}
        end.flatten
    end

    def self.scrape_race(url)
        html = Nokogiri::HTML(open(url))

        race_data = {}

        result_id_regex = /^http:\/\/form\.timeform\.betfair\.com\/raceresult\?raceId\=(.*)$/i
        race_id_regex = /.*\"registerServices\":\[\"markets\"\]\,\"periodicUpdates\":\{\"markets\":\{\"keys\":\{\"\d\":\[\"(.*?)\"\]\}.*/i

        result_id_matches = result_id_regex.match(url)
        race_id_matches = race_id_regex.match(html)

        if result_id_matches && result_id_matches.size == 2
            race_data['betfair_result_id'] = result_id_matches[1]
        end

        if race_id_matches && race_id_matches.size == 2
            race_data['betfair_race_id'] = race_id_matches[1]
        else
            race_data['betfair_race_id'] = nil
        end

        puts url
        puts race_data

        # Races.update({betfair_result_id: race_data['betfair_result_id']}, race_data, {upsert: true})
        # race = Races.findOne({betfair_result_id: race_data['betfair_result_id']})
    end
end
