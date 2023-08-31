request = Meteor.npmRequire('request')#.defaults({'proxy': 'http://165.225.166.107:3128'})
cheerio = Meteor.npmRequire('cheerio')
util = Meteor.npmRequire('util')
async = Meteor.npmRequire('async')
moment = Meteor.npmRequire('moment')

class @Manager
    @scrape = ->
        console.log "Scraping..."

        base_url = 'http://form.timeform.betfair.com'

        date = moment('2013-01-01')
        last_date = moment('2015-07-31')

        dates = [date.format('YYYYMMDD')]

        while date.isBefore(last_date)
            date.add(1, 'days')

            dates.push(date.format('YYYYMMDD'))
        # while

        async.eachSeries dates, (date, async_dates_callback) ->
            url = "#{base_url}/daypage?date=#{date}"

            console.log "#{date} [START]"

            Scraper.get_race_urls url, Meteor.bindEnvironment (race_urls) ->
                async.each race_urls, Meteor.bindEnvironment((race_url, async_races_callback) ->
                    race_url = base_url + race_url

                    try
                        Scraper.scrape_race race_url, Meteor.bindEnvironment (race_id) ->
                            # console.log util.inspect(race, false, null)
                            console.log race_id
                            async_races_callback()
                        # scrape_race
                    catch e
                        console.log e
                        async_races_callback()
                    # try
                ), (error) ->
                    throw error if error

                    console.log "#{date} [END]"
                    async_dates_callback()
                # each
            # get_race_urls
        , (error) ->
            throw error if error

            console.log "Done!"
        # eachSeries
    # scrape

    @compute_accuracy = ->
        Races.find({'correct_match': true}).fetch().length
        # races = Races.find({'timeform123_1': {'$ne': null}}).fetch()
    # compute_accuracy
# Manager
