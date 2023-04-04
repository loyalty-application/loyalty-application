curl -i --max-time 60 --retry-connrefused --retry 10 -X PUT -H "Accept:application/json" -H "Content-Type:application/json" $CONNECTOR_HOST/connectors/source-mongo-01/config -d '{
    "task.max": "2",
    "value.converter.schemas.enable": "true",
    "name": "source-mongo-01",
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "connection.uri": "'$ME_CONFIG_MONGODB_URL'",
    "database": "loyalty",
    "collection": "unprocessed",
    "publish.full.document.only": "true",
    "topic.namespace.map": "{\"loyalty.unprocessed\":\"resttransactions\"}",
    "output.format.key": "schema",
    "output.format.value": "json",
    "output.schema.key": "{\"type\":\"record\",\"name\":\"keySchema\",\"fields\":[{\"name\":\"fullDocument.card_id\",\"type\":\"string\"}]}",
    "output.schema.value": "{\"type\":\"record\",\"name\":\"TransactionRecord\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"transaction_id\",\"type\":\"string\"},{\"name\":\"merchant\",\"type\":\"string\"},{\"name\":\"mcc\",\"type\":\"int\"},{\"name\":\"currency\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"float\"},{\"name\":\"transaction_date\",\"type\":\"string\"},{\"name\":\"card_id\",\"type\":\"string\"},{\"name\":\"card_pan\",\"type\":\"string\"},{\"name\":\"card_type\",\"type\":\"string\"}]}",
    "startup.mode": "copy_existing"
  }'
