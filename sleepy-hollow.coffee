request = Meteor.npmRequire('request')#.defaults({'proxy': 'http://165.225.166.107:3128'})
cheerio = Meteor.npmRequire('cheerio')
util = Meteor.npmRequire('util')
async = Meteor.npmRequire('async')

get_race_urls = (date_url, callback) ->
    request date_url, (error, response, html) ->
        throw error if error

        race_urls = []

        $ = cheerio.load(html)

        $('li.full').filter ->
            race_urls.push($(this).children().first().attr('href'))
        # filter

        console.log "#{race_urls.length} races"

        callback(race_urls)
    # request
# get_race_urls

scrape_race = (race_url, callback) ->
    request race_url, (error, response, html) ->
        throw error if error

        $ = cheerio.load(html)

        info = {
            'url': race_url
        }

        result_id_regex = /^http:\/\/form\.timeform\.betfair\.com\/raceresult\?raceId\=(.*)$/i
        race_id_regex = /.*\"registerServices\":\[\"markets\"\]\,\"periodicUpdates\":\{\"markets\":\{\"keys\":\{\"\d\":\[\"(.*?)\"\]\}.*/i

        result_id_matches = result_id_regex.exec(race_url)
        race_id_matches = race_id_regex.exec(html)

        if result_id_matches and result_id_matches.length == 2
            info['result_id'] = result_id_matches[1]
        # if

        if race_id_matches and race_id_matches.length == 2
            info['race_id'] = race_id_matches[1]
        else
            info['race_id'] = null
        # if

        $('.when').filter ->
            info['date'] = $(this).text().trim_spaces()
        # filter

        $('.location').filter ->
            info['track'] = $(this).text().trim_spaces()
        # filter

        $('.i13n-ltxt-time').filter ->
            info['time'] = $(this).text().replace(/\+/, '').trim_spaces()
        # filter

        $('.race-description').filter ->
            info['name'] = $(this).text().trim_spaces()
        # filter

        $('.race-info').filter ->
            info['race_info'] = {}

            race_info = $(this).text().trim_spaces()

            regex_going = /^Going:\ (.*?)\ \|/i
            regex_distance = /Distance:\ (.*?)\ \|/i
            regex_age = /Age:\ (.*?)\ \|/i
            regex_prize = /Total prize money:\ (.*?)\ \|/i
            regex_runners = /Runners:\ (.*?)\ \|/i
            regex_type = /Race Type:\ (.*?)$/i

            matches_going = regex_going.exec(race_info)
            matches_distance = regex_distance.exec(race_info)
            matches_age = regex_age.exec(race_info)
            matches_prize = regex_prize.exec(race_info)
            matches_runners = regex_runners.exec(race_info)
            matches_type = regex_type.exec(race_info)

            if matches_going and matches_going.length == 2
                info['race_info']['going'] = matches_going[1].trim_spaces()
            # if

            if matches_distance and matches_distance.length == 2
                info['race_info']['distance'] = matches_distance[1].trim_spaces()
            # if

            if matches_age and matches_age.length == 2
                info['race_info']['age'] = matches_age[1].trim_spaces()
            # if

            if matches_prize and matches_prize.length == 2
                info['race_info']['prize'] = matches_prize[1].trim_spaces()
            # if

            if matches_runners and matches_runners.length == 2
                info['race_info']['runners'] = matches_runners[1].trim_spaces()
            # if

            if matches_type and matches_type.length == 2
                info['race_info']['type'] = matches_type[1].trim_spaces()
            # if
        # filter

        $('.extra-info').filter ->
            extra_info = $(this).children().first().text()

            info['winning_time'] = /^.*Winning\ Time:\ (.*?)$/i.exec(extra_info)[1]
            info['ran'] = /^(.*?)\ Ran.*$/i.exec(extra_info)[1]
        # filter

        info['horses'] = []
        $('.full-results tbody tr').filter ->
            horse = {
                position: $(this).children('.pos-draw').children('.pos').text().trim_spaces(),
                draw: $(this).children('.pos-draw').children('.draw').text().trim_spaces(),
                distance: $(this).children('.dist').text().trim_spaces(),
                name: $(this).children('.horse').text().trim_spaces(),
                url: $(this).children('.horse').children('a').attr('href'),
                age: $(this).children('.age').text().trim_spaces(),
                weight: $(this).children('.wgt-or').children('.wgt').text().trim_spaces(),
                official_rating: $(this).children('.wgt-or').children('.or').text().trim_spaces(),
                equitation: $(this).children('.eq').text().trim_spaces(),
                jockey_name: $(this).children('.jockey-trainer').children('.jockey').text().trim_spaces(),
                jockey_url: $(this).children('.jockey-trainer').children('.jockey').attr('href'),
                trainer_name: $(this).children('.jockey-trainer').children('.trainer').text().trim_spaces(),
                trainer_url: $(this).children('.jockey-trainer').children('.trainer').attr('href'),
                inplay_high_low: $(this).children('.inplay-high-low').text().trim_spaces(),
                bsp: $(this).children('.bsp-perc').children('.bsp').text().trim_spaces(),
                isp: $(this).children('.bsp-perc').children('.isp').text().replace(/\//, '').trim_spaces(),
                percentage: $(this).children('.bsp-perc').children('.perc').text().trim_spaces(),
                place: $(this).children('.place').text().trim_spaces(),
            }

            info['horses'].push(horse)
        # filter

        callback(info)
    # request
# scrape_race

if Meteor.isServer
    Meteor.startup ->
        console.log "Started"

        base_url = 'http://form.timeform.betfair.com'
        base_date = '201507'

        dates = [
            '01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
            '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
            '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31',
        ]

        date = base_date + dates[0]

        url = "#{base_url}/daypage?date=#{date}"

        get_race_urls url, (race_urls) ->
            async.each race_urls, (race_url, async_callback) ->
                race_url = base_url + race_url

                scrape_race race_url, (info) ->
                    console.log util.inspect(info, false, null)
                    async_callback()
                # scrape_race
            , (error) ->
                throw error if error

                console.log "Done!"
            # each
        # get_race_urls
    # startup
# isServer
