curl -i --max-time 60 --retry-connrefused --retry 10 -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" http://connect:8083/connectors/source-csv-spooldir-03/config -d '{
  "connector.class": "com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
  "task.max": "2",
  "cleanup.policy": "DELETE",
  "topic": "ftptransactions",
  "input.path": "/data/unprocessed",
  "finished.path": "/data/processed",
  "error.path": "/data/error",
  "input.file.pattern": ".*\\.csv",
  "key.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Key\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"id\":{\"type\":\"STRING\",\"isOptional\":true}}}",
  "value.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Value\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"id\":{\"type\":\"STRING\",\"isOptional\":true},\"transaction_id\":{\"type\":\"STRING\",\"isOptional\":true},\"merchant\":{\"type\":\"STRING\",\"isOptional\":true},\"mcc\":{\"type\":\"STRING\",\"isOptional\":true},\"currency\":{\"type\":\"STRING\",\"isOptional\":true},\"amount\":{\"type\":\"STRING\",\"isOptional\":true},\"transaction_date\":{\"type\":\"STRING\",\"isOptional\":true},\"card_id\":{\"type\":\"STRING\",\"isOptional\":true},\"card_pan\":{\"type\":\"STRING\",\"isOptional\":true},\"card_type\":{\"type\":\"STRING\",\"isOptional\":true}}}","value.converter":"org.apache.kafka.connect.json.JsonConverter",
  "value.converter.schemas.enable":"false",
  "producer.override.enable.idempotence":"true",
  "producer.override.acks":"all",
  "transforms": "cast,setDefaultValueToInt",
  "transforms.cast.type": "org.apache.kafka.connect.transforms.Cast$Value",
  "transforms.cast.spec": "amount:float64",
  "transforms.setDefaultValueToInt.type": "org.apache.kafka.connect.transforms.ReplaceField$Value",
"transforms.setDefaultValueToInt.field": "mcc",
"transforms.setDefaultValueToInt.default": 0,
"transforms.setDefaultValueToInt.type.to": "int32"
}'