FROM confluentinc/cp-kafka:7.3.1

USER root

COPY ./run.sh .

RUN chmod +x ./run.sh

CMD [ "/bin/sh", "-c", "kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --create --if-not-exists --topic ftptransactions --replication-factor 3 --partitions 10 --config min.insync.replicas=2 && kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --create --if-not-exists --topic resttransactions --replication-factor 3 --partitions 10 --config min.insync.replicas=2 && kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --list && ./run.sh && exit 0" ]
