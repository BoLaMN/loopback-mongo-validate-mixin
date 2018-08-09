# loopback-mixin-mongo-validate

Converts loopback models with embedded models propertys to $jsonScheme validators

* npm install loopback-mixin-mongo-validate --save

## Setup

```
  mixins:
    MongoValidate: true
```

or

```
  mixins:
    MongoValidate:
      validationLevel: 'strict|moderate'
      validationAction: 'error|warn'
```

License: MIT