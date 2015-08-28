request = Meteor.npmRequire('request')#.defaults({'proxy': 'http://165.225.166.107:3128'})
cheerio = Meteor.npmRequire('cheerio')

if Meteor.isServer
    Meteor.startup ->
        console.log "Started"

        base_url = 'http://form.timeform.betfair.com'

        date = '20150701'
        url = "#{base_url}/daypage?date=#{date}"

        request url, (error, response, html) ->
            throw error if error

            race_urls = []

            $ = cheerio.load(html)

            $('li.full').filter ->
                console.log $(this).attr('title')

                race_urls.push($(this).children().first().attr('href'))
            # filter

            console.log race_urls
            console.log "#{race_urls.length} races"
        # request
    # startup
# isServer
