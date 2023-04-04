FROM cnfldemos/cp-server-connect-datagen:0.6.0-7.3.0

COPY connect ./connect

COPY run.sh ./run.sh

RUN mkdir spend && mkdir users

RUN confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:2.0.65 && confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.10.0

