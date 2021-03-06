{ extend } = require 'lodash'

module.exports = (app, ctor) ->

  any = [ 'double', 'string', 'object', 'array', 'binData'
    'undefined', 'objectId', 'bool', 'date', 'null'
    'regex', 'dbPointer', 'javascript', 'symbol'
    'javascriptWithScope', 'number', 'timestamp', 'long'
    'decimal', 'minKey', 'maxKey'
  ]

  getModelInfo = (model) ->
    { models } = app.registry.modelBuilder

    coerce = (val, required = false) ->
      return val unless typeof val is 'string'

      v = switch val.toLowerCase()
        when 'number' then 'number'
        when 'objectid' then 'objectId'
        when 'boolean' then 'bool'
        when 'string' then 'string'
        when 'any' then any
        else ('' + val).toLowerCase()

      if not required and typeof v is 'string' and v isnt 'null'
        v = [ v, 'null', 'undefined' ]

      v

    formatInfo = (definition) ->
      obj = properties: {}

      req = []

      for key, property of definition.properties
        obj.properties[key] = {}

        { type, bsonType } = property

        if property.required
          req.push key

        if bsonType
          obj.properties[key].bsonType = coerce(bsonType, property.required)
        else if type.definition
          name = type?.modelName or type?.name

          { properties, required } = getModelInfo models[name]

          if properties?
            obj.properties[key] =
              bsonType: 'object'
              properties: properties
              additionalProperties: true

            if required?.length
              obj.properties[key].required = required

        else if Array.isArray type
          subtype = type[0]

          if subtype.definition
            name = subtype?.modelName or subtype?.name

            { properties, required } = getModelInfo models[name]

            if properties?
              obj.properties[key] =
                bsonType: 'array'
                additionalItems: true
                items:
                  bsonType: 'object'
                  properties: properties
                  additionalProperties: true

              if required?.length
                obj.properties[key].items.required = required
          else
            obj.properties[key] =
              bsonType: 'array'
              additionalItems: true
              items:
                bsonType: coerce(subtype?.modelName or subtype?.name, property.required)
                additionalProperties: true
                properties: {}
        else
          obj.properties[key].bsonType = coerce(type.name or type, property.required)

      for key, value of definition.settings.relations
        continue unless type in [ 'hasOne', 'belongsTo' ]

        if value.foreignKey
          key = value.foreignKey

        { properties } = getModelInfo models[value.model]

        obj.properties[key] ?= properties.id


      if req.length
        obj.required = req

      obj

    baseModel = undefined
    baseProperties = undefined

    if model.definition.base
      baseModel = getModelInfo model.app.models[model.definition.base]
      baseProperties = formatInfo baseModel.definition

    properties = formatInfo model.definition

    extend properties, baseProperties

  schema = getModelInfo ctor
  schema.bsonType = 'object'
  schema.additionalProperties = true
  schema.required ?= [ 'id' ]

  if schema.properties.id
    schema.properties._id = schema.properties.id
    delete schema.properties.id

  idIdx = schema.required.indexOf 'id'

  if idIdx > -1
    schema.required[idIdx] = '_id'

  schema
