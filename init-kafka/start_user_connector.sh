curl -i --max-time 60 --retry-connrefused --retry 10 -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" $CONNECTOR_HOST/connectors/source-csv-spooldir-02/config -d '{
  "connector.class": "com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
  "tasks.max": "2",
  "producer.acks":"1",
  "producer.batch.size":"32768",
  "batch.size":"1000",
  "enable.idempotence":"false",
  "cleanup.policy": "DELETE",
  "topic": "users",
  "input.path": "/data/unprocessed",
  "finished.path": "/data/processed",
  "error.path": "/data/error",
  "input.file.pattern": ".*users.*\\.csv",
  "key.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Key\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"id\":{\"type\":\"STRING\",\"isOptional\":true}}}",
  "value.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Value\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"id\":{\"type\":\"STRING\",\"isOptional\":true},\"first_name\":{\"type\":\"STRING\",\"isOptional\":true},\"last_name\":{\"type\":\"STRING\",\"isOptional\":true},\"phone\":{\"type\":\"STRING\",\"isOptional\":true},\"email\":{\"type\":\"STRING\",\"isOptional\":true},\"created_at\":{\"type\":\"STRING\",\"isOptional\":true},\"updated_at\":{\"type\":\"STRING\",\"isOptional\":true},\"card_id\":{\"type\":\"STRING\",\"isOptional\":true},\"card_pan\":{\"type\":\"STRING\",\"isOptional\":true},\"card_type\":{\"type\":\"STRING\",\"isOptional\":true}}}","value.converter":"org.apache.kafka.connect.json.JsonConverter",
  "value.converter.schemas.enable":"false",
  "producer.override.acks":"1",
  "producer.override.batch.size":"32768"
}'