{ extend } = require 'lodash'

module.exports = (app, ctor) ->

  any = [ 'double', 'string', 'object', 'array', 'binData'
    'undefined', 'objectId', 'bool', 'date', 'null'
    'regex', 'dbPointer', 'javascript', 'symbol'
    'javascriptWithScope', 'int', 'timestamp', 'long'
    'decimal', 'minKey', 'maxKey'
  ]

  getModelInfo = (model) ->
    { models } = app.registry.modelBuilder

    coerce = (val) ->
      switch val.toLowerCase()
        when 'number' then 'int'
        when 'objectid' then 'objectId'
        when 'boolean' then 'bool'
        when 'string' then [ 'string', 'null' ]
        when 'any' then any
        else ('' + val).toLowerCase()

    formatInfo = (definition) ->
      obj = properties: {}

      req = []

      for key, property of definition.properties
        obj.properties[key] = {}

        { type } = property

        if property.required
          req.push key

        if type.definition
          name = type?.modelName or type?.name

          { properties, required } = getModelInfo models[name]

          if properties?
            obj.properties[key] =
              bsonType: 'object'
              items:
                bsonType: 'object'
                properties: properties

        else if Array.isArray type
          subtype = type[0]

          if subtype.definition
            name = subtype?.modelName or subtype?.name

            { properties, required } = getModelInfo models[name]

            if properties?
              obj.properties[key] =
                bsonType: 'array'
                items:
                  bsonType: 'object'
                  properties: properties
          else
            obj.properties[key] =
              bsonType: 'array'
              items:
                bsonType: coerce(subtype?.modelName or subtype?.name)
        else
          obj.properties[key].bsonType = coerce(type.name or type)

      for key, value of definition.settings.relations

        type = switch value.type
          when 'embedsMany' then 'array'
          when 'embedsOne' then 'object'

        continue unless type

        if value.property
          key = value.property

        obj.properties[key] = bsonType: coerce type

        { properties, required } = getModelInfo models[value.model]

        if properties?
          obj.properties[key].items =
            bsonType: 'object'
            properties: properties

        if required?.length
          obj.properties[key].items.required = required

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

  if schema.properties.id
    schema.properties._id = schema.properties.id
    delete schema.properties.id

  schema
