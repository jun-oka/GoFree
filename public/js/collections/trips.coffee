Trips = Backbone.Collection.extend(
  initialize: ()->
      @on('add', @handleAdd)
      app.log('[app.collections.Trips]: initialize')
  handleAdd: (item)->
      item.set('id', @length)
  model: app.models.Trip
)

app.collections.Trips = Trips