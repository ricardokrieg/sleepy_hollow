# export MONGO_URL=mongodb://stark:passtrash123@ds063892.mongolab.com:63892/general

if Meteor.isServer
    Meteor.startup ->
        console.log "Started"

        # Manager.scrape()
        # Manager.compute_accuracy()
    # startup
# isServer
