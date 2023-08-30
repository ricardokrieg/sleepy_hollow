request = Meteor.npmRequire('request')#.defaults({'proxy': 'http://165.225.166.107:3128'})
cheerio = Meteor.npmRequire('cheerio')
util = Meteor.npmRequire('util')
async = Meteor.npmRequire('async')

class @Scraper
    @get_race_urls: (date_url, callback) ->
        request date_url, (error, response, html) ->
            throw error if error

            $ = cheerio.load(html)

            race_urls = []

            $('li.full').filter ->
                race_urls.push($(this).children().first().attr('href'))
            # filter

            console.log "#{race_urls.length} races"

            callback(race_urls)
        # request
    # get_race_urls

    @scrape_race: (race_url, callback) ->
        request race_url, Meteor.bindEnvironment (error, response, html) ->
            throw error if error

            $ = cheerio.load(html)

            race_data = {}

            result_id_regex = /^http:\/\/form\.timeform\.betfair\.com\/raceresult\?raceId\=(.*)$/i
            race_id_regex = /.*\"registerServices\":\[\"markets\"\]\,\"periodicUpdates\":\{\"markets\":\{\"keys\":\{\"\d\":\[\"(.*?)\"\]\}.*/i

            result_id_matches = result_id_regex.exec(race_url)
            race_id_matches = race_id_regex.exec(html)

            if result_id_matches and result_id_matches.length == 2
                race_data['betfair_result_id'] = result_id_matches[1]
            # if

            if race_id_matches and race_id_matches.length == 2
                race_data['betfair_race_id'] = race_id_matches[1]
            else
                race_data['betfair_race_id'] = null
            # if

            Races.update({betfair_result_id: race_data['betfair_result_id']}, race_data, {upsert: true})
            race = Races.findOne({betfair_result_id: race_data['betfair_result_id']})

            $('.when').filter ->
                race_data['date'] = $(this).text().strip()
            # filter

            $('.i13n-ltxt-time').filter ->
                race_data['time'] = $(this).text().replace(/\+/, '').strip()
            # filter

            $('.location').filter ->
                return if race_data['track_id']
                track_data = {name: $(this).text().strip()}

                if track_id = Tracks.findOne(track_data)
                    race_data['track_id'] = track_id._id
                else
                    race_data['track_id'] = Tracks.insert(track_data)
            # filter

            $('.race-description').filter ->
                race_data['description'] = $(this).text().strip()
            # filter

            $('.race-info').filter ->
                race_info = $(this).text().strip()

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
                    race_data['going'] = matches_going[1].strip()
                # if

                if matches_distance and matches_distance.length == 2
                    race_data['distance'] = matches_distance[1].strip()
                # if

                if matches_age and matches_age.length == 2
                    race_data['age'] = matches_age[1].strip()
                # if

                if matches_prize and matches_prize.length == 2
                    race_data['prize'] = matches_prize[1].strip()
                # if

                if matches_runners and matches_runners.length == 2
                    race_data['initial_runners'] = matches_runners[1].strip()
                # if

                if matches_type and matches_type.length == 2
                    race_data['type'] = matches_type[1].strip()
                # if
            # filter

            $('.extra-info').filter ->
                extra_info = $(this).children().first().text()

                race_data['winning_time'] = /^.*Winning\ Time:\ (.*?)$/i.exec(extra_info)[1]
                race_data['ran'] = /^(.*?)\ Ran.*$/i.exec(extra_info)[1]
            # filter

            race_data['runners'] = []

            $('.full-results tbody tr').filter ->
                horse_data = {
                    name: $(this).children('.horse').text().strip(),
                    betfair_id: $(this).children('.horse').children('a').attr('href').split('=')[1]
                }
                Horses.update({betfair_id: horse_data['betfair_id']}, horse_data, {upsert: true})
                horse = Horses.findOne({betfair_id: horse_data['betfair_id']})

                jockey_data = {
                    name: $(this).children('.jockey-trainer').children('.jockey').text().strip(),
                    betfair_id: $(this).children('.jockey-trainer').children('.jockey').attr('href').split('=')[1]
                }
                Jockeys.update({betfair_id: jockey_data['betfair_id']}, jockey_data, {upsert: true})
                jockey = Jockeys.findOne({betfair_id: jockey_data['betfair_id']})

                trainer_data = {
                    name: $(this).children('.jockey-trainer').children('.trainer').text().strip(),
                    betfair_id: $(this).children('.jockey-trainer').children('.trainer').attr('href').split('=')[1]
                }
                Trainers.update({betfair_id: trainer_data['betfair_id']}, trainer_data, {upsert: true})
                trainer = Trainers.findOne({betfair_id: trainer_data['betfair_id']})

                runner_data = {
                    race_id: race._id,
                    trac_id: race_data['track_id'],
                    horse_id: horse._id,
                    jockey_id: jockey._id,
                    trainer_id: trainer._id,

                    race_date: race_data['date'],
                    race_time: race_data['time'],
                    race_going: race_data['going'],
                    race_distance: race_data['distance'],
                    race_age: race_data['age'],
                    race_prize: race_data['prize'],
                    race_initial_runners: race_data['initial_runners'],
                    race_type: race_data['type'],
                    race_winning_time: race_data['winning_time'],
                    race_ran: race_data['ran']
                }

                runner_data['race_id'] = race._id
                runner_data['position'] = $(this).children('.pos-draw').children('.pos').text().strip()
                runner_data['draw'] = $(this).children('.pos-draw').children('.draw').text().strip()
                runner_data['distance'] = $(this).children('.dist').text().strip()
                runner_data['age'] = $(this).children('.age').text().strip()
                runner_data['weight'] = $(this).children('.wgt-or').children('.wgt').text().strip()
                runner_data['official_rating'] = $(this).children('.wgt-or').children('.or').text().strip()
                runner_data['equitation'] = $(this).children('.eq').text().strip()
                runner_data['inplay_high_low'] = $(this).children('.inplay-high-low').text().strip()
                runner_data['bsp'] = $(this).children('.bsp-perc').children('.bsp').text().strip()
                runner_data['isp'] = $(this).children('.bsp-perc').children('.isp').text().replace(/\//, '').strip()
                runner_data['percentage'] = $(this).children('.bsp-perc').children('.perc').text().strip()
                runner_data['place'] = $(this).children('.place').text().strip()

                runner_selector = {
                    race_id: race._id,
                    position: runner_data['position']
                }

                Runners.update(runner_selector, runner_data, {upsert: true})
                runner = Runners.findOne(runner_selector)

                race_data['runners'].push({
                    runner_id: runner._id,
                    horse_id: runner.horse_id,
                    position: runner.position
                })
            # filter

            race_data['winner_horse_id'] = runner['horse_id'] for runner in race_data['runners'] when runner['position'] == '1'

            if race_data['betfair_race_id']
                request "http://form.timeform.betfair.com/racecard?id=#{race_data['betfair_race_id']}", Meteor.bindEnvironment (error, response, html) ->
                    throw error if error

                    $ = cheerio.load(html)

                    $('.inner-timeform123 tbody tr').filter ->
                        selection_number = 'timeform123_' + $(this).children('.selection-number').text()

                        horse_data = {
                            name: $(this).children('.runner-name').children().first().text(),
                            betfair_id: $(this).children('.runner-name').children().first().attr('href').split('=')[1]
                        }

                        Horses.update({betfair_id: horse_data['betfair_id']}, horse_data, {upsert: true})
                        horse = Horses.findOne({betfair_id: horse_data['betfair_id']})

                        race_data[selection_number] = horse._id
                    # filter

                    race_data['correct_match'] = race_data['timeform123_1'] == race_data['winner_horse_id']

                    Races.update({_id: race._id}, race_data)

                    callback(race._id)
                # request
            else
                race_data['correct_match'] = null

                Races.update({_id: race._id}, race_data)

                callback(race._id)
            # if
        # request
    # scrape_race
# Scraper
