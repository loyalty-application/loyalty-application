FROM cnfldemos/cp-server-connect-datagen:0.6.0-7.3.0

COPY . .

RUN wget https://go.dev/dl/go1.20.3.linux-amd64.tar.gz

RUN tar -C $HOME -xzf go1.20.3.linux-amd64.tar.gz

RUN $HOME/go/bin/go build connect.go

RUN mkdir spend && mkdir users

RUN confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:2.0.65 && confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.10.0

