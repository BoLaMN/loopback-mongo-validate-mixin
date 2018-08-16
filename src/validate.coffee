debug = require('debug') 'loopback:component:mongo-validation'

generate = require './schema'

module.exports = (Model, options = {}) ->

  validationLevel = options.validationLevel or 'strict'
  validationAction = options.validationAction or 'warn'

  Model.once 'attached', (app) ->
    return unless typeof Model.getConnector is 'function'

    connector = Model.getConnector()

    return unless connector.name is 'mongo'

    connector.connect (err, db) ->
      if err
        throw err

      collMod = connector.collectionName Model.modelName
      $jsonSchema = generate app, Model

      validator = { $jsonSchema }

      db.createCollection collMod, (err) ->
        if err
          debug 'collection %s already existed', collMod

        db.command { collMod, validator, validationLevel, validationAction }
          .then (res) ->
            debug 'created %s %o', collMod, validator
          .catch (e) ->
            console.error collMod + ' errored', e, validator

      return
    return
  return