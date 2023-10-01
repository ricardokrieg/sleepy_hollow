require 'bundler/setup'

require 'fileutils'
require 'colorize'

require './scraper.rb'

MULTIPLE_RACES = 20
CSV_DELIMITER = ';'

begin
    base_url = 'http://form.timeform.betfair.com'

    start_date = Date.strptime("2013-01-01", "%Y-%m-%d")
    end_date = Date.strptime("2013-01-10", "%Y-%m-%d")

    dates = start_date.upto(end_date).map {|date| date.strftime('%Y%m%d')}

    urls = Scraper.get_race_urls(base_url, dates)
    urls.each do |url|
        Scraper.scrape_race(url)
    end
rescue Interrupt
    puts "Killed!".red
end
