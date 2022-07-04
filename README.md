Metabase Workbench
===

This project was made for fun and also as a challenge to get all the app telemetry from the Metabase logs.

The components are the following:
1) Nginx with localhost self-signed certs to enable HTTP/2
2) Containerized Metabase, but configured to send the logs to an HTTP endpoint via a custom Log4J2 configuration
3) A containerized Python FastAPI application that receives the log entries from Metabase, parses that and sends the information to the "App Telemetry" in the TimescaleDB database
4) Tuned cAdvisor (to reduce the noise), a project from Google that grabs metrics from the container and sends that to a NodeJS UDP endpoint with the Statsd protocol, and persists to the "Container Telemetry" table in TimescaleDB
5) An App DB and a DW DB, the DW DB is connected via SSH and without it
6) A containerized NodeJS app that connects to the DW DB and obtains how many connections Metabase is using (to compare it against the connections that the logs say), and persists to "Connection Metrics" table in TimescaleDB
7) TimescaleDB, that is set up with 3 tables: "App Telemetry", "Container Telemetry" and "Connection Metrics"


### How to run

docker-compose up --build

### Services

localhost:8081 Nginx (HTTP/2), acting as reverse-proxy to Metabase. User/pass is 'a@b.com' / 'metabot1'
localhost:3001 Metabase (without HTTP/2) - not recommended, it's recommended to access via Nginx
localhost:8080 cAdvisor
localhost:3000 Grafana (admin/admin)