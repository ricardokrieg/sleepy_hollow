request = Meteor.npmRequire('request')#.defaults({'proxy': 'http://165.225.166.107:3128'})
cheerio = Meteor.npmRequire('cheerio')
util = Meteor.npmRequire('util')
async = Meteor.npmRequire('async')

class @Manager
    @scrape = ->
        console.log "Scraping..."

        base_url = 'http://form.timeform.betfair.com'
        base_date = '201507'

        dates = [
            '01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
            '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
            '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31',
        ]

        async.eachSeries dates, (date, async_dates_callback) ->
            url = "#{base_url}/daypage?date=#{base_date}#{date}"

            console.log "#{base_date}#{date} [START]"

            Scraper.get_race_urls url, Meteor.bindEnvironment (race_urls) ->
                async.eachSeries race_urls, Meteor.bindEnvironment((race_url, async_races_callback) ->
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

                    console.log "#{base_date}#{date} [END]"
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
