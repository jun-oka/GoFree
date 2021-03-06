// Generated by LiveScript 1.2.0
(function(){
  var _, database;
  _ = require("underscore");
  database = require("./../database");
  exports.add_email = function(req, res){
    var user, email;
    user = req.user;
    email = req.params.email;
    if (!user) {
      return res.json({
        status: 'error',
        message: 'this method works only for logged in users'
      });
    }
    database.users.update({
      provider: user.provider,
      id: user.id
    }, {
      $set: {
        emails: {
          value: email
        },
        email: email
      }
    });
    return res.json({
      status: 'ok'
    });
  };
}).call(this);
