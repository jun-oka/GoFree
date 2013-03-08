(function(){
  var database;
  database = require("./../database");
  exports.dashboard = function(req, res){
    return database.users.find().count(function(err, numberOfUsers){
      return database.search.find().count(function(err, numberOfSearches){
        return database.conversions.find().count(function(err, numberOfConversions){
          return res.render("dashboard/index", {
            numberOfUsers: numberOfUsers,
            numberOfSearches: numberOfSearches,
            numberOfConversions: numberOfConversions
          });
        });
      });
    });
  };
}).call(this);
