# Kafka Server Quickstart

Prior to starting the containers, make sure to run the `generate-certs.bash` file and respond "yes" to all "Trust this certificate?" prompts.. This script generates the necessary certs for SSL encryption.

Use `docker compose up -d` to start the Kafka and Zookeeper servers. By default, the `docker compose up` command will expose port 9092 for non-TLS HTTP traffic and port 9093 for TLS enabled SASL_SSL traffic. Port 9093 also requires the client to specify SASL credentials. The SASL credentials on the server are set by the Docker agent to the values in the kafka_jaas.conf file.
