'use strict'

validate = require './valiate'

module.exports = (app) ->
  app.loopback.modelBuilder.mixins.define 'MongoValidate', validate

  return
