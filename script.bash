# Generate server certs
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_SSL=$DIR/ssl
DIR_SERVER=$DIR_SSL/server
DIR_SERVER_CERTS=$DIR_SERVER/certs
DIR_CLIENT=$DIR_SSL/client
DIR_CLIENT_CERTS=$DIR_CLIENT/certs

mkdir -p $DIR_SSL
mkdir -p $DIR_SERVER
mkdir -p $DIR_SERVER_CERTS
mkdir -p $DIR_CLIENT
mkdir -p $DIR_CLIENT_CERTS

# ========== Server ==============

## Generate private key
openssl genrsa -out $DIR_SERVER/server.key 2048

## Generate certificate signing request
openssl req -new -key $DIR_SERVER/server.key -out $DIR_SERVER/server.csr -subj "/C=US/ST=California/L=Los Angeles/O=Your Organization/OU=IT Department/CN=host.docker.internal"

## Generate certificate (valid 365 days)
openssl x509 -req -days 365 -in $DIR_SERVER/server.csr -signkey $DIR_SERVER/server.key -out $DIR_SERVER/server.crt

## Create server pkcs
openssl pkcs12 -export -in $DIR_SERVER/server.crt -inkey $DIR_SERVER/server.key -out $DIR_SERVER/kafka-server.p12 \
    -name kafka-server -CAfile $DIR_SERVER/server.crt -caname root -password pass:server-key-password

## Create the keystore
keytool -importkeystore -deststorepass server-keystore-pass -destkeystore $DIR_SERVER/certs/kafka.keystore.jks -srckeystore $DIR_SERVER/kafka-server.p12 \
    -srcstoretype PKCS12 -srcstorepass server-key-password -alias kafka-server

## Create the truststore
keytool -keystore $DIR_SERVER/certs/kafka.truststore.jks -alias CARoot -import -file $DIR_SERVER/server.crt -storepass server-truststore-pass -noprompt

# ========== Client ==============

## Generate private key
openssl genrsa -out $DIR_CLIENT/client.key 2048

## Generate certificate signing request
openssl req -new -key $DIR_CLIENT/client.key -out $DIR_CLIENT/client.csr -subj "/C=US/ST=California/L=Los Angeles/O=Your Organization/OU=IT Department/CN=localhost"

## Generate certificate (valid 365 days)
openssl x509 -req -days 365 -in $DIR_CLIENT/client.csr -signkey $DIR_CLIENT/client.key -out $DIR_CLIENT/client.crt

## Create client pkcs
openssl pkcs12 -export -in $DIR_CLIENT/client.crt -inkey $DIR_CLIENT/client.key -out $DIR_CLIENT/kafka-client.p12 \
    -name kafka-client -CAfile $DIR_CLIENT/client.crt -caname root -password pass:client-key-password

## Create the keystore
keytool -importkeystore -deststorepass client-keystore-pass -destkeystore $DIR_CLIENT/certs/kafka.client.keystore.jks -srckeystore $DIR_CLIENT/kafka-client.p12 \
    -srcstoretype PKCS12 -srcstorepass client-key-password -alias kafka-client

## Create the truststore
keytool -keystore $DIR_CLIENT/certs/kafka.client.truststore.jks -alias CARoot -import -file $DIR_CLIENT/client.crt -storepass client-truststore-pass -noprompt

# ========== Truststore operations ==============
keytool -import -alias kafka-ca -file $DIR_CLIENT/client.crt -keystore $DIR_SERVER_CERTS/kafka.truststore.jks -storepass server-truststore-pass

keytool -import -alias kafka-ca -file $DIR_SERVER/server.crt -keystore $DIR_CLIENT_CERTS/kafka.client.truststore.jks -storepass client-truststore-pass