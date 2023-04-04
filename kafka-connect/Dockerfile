FROM cnfldemos/cp-server-connect-datagen:0.6.0-7.3.0

COPY . .

RUN sudo yum install epel-release

RUN sudo yum update

RUN sudo yum install golang

RUN go build ./connect.go

RUN mkdir spend && mkdir users

RUN confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:2.0.65 && confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.10.0

