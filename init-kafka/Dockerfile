FROM confluentinc/cp-kafka:7.3.1

USER root

COPY ./run.sh .

RUN chmod +x ./run.sh

RUN chmod 777 -R /data

RUN mkdir -p /data/processed && mkdir -p /data/unprocessed && mkdir -p /data/error

RUN chmod 777 -R /data

CMD [ "/bin/sh", "-c", "kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --create --if-not-exists --topic ftptransactions --replication-factor 3 --partitions 10 --config min.insync.replicas=2 && kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --create --if-not-exists --topic resttransactions --replication-factor 3 --partitions 10 --config min.insync.replicas=2 && kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --list && ./run.sh && exit 0" ]
