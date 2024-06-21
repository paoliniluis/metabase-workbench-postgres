Metabase + PostgreSQL + Grafana
===============================

This is a repository to see Metabase traces + it has the profilings of Pyroscope on it.

## Components

- Metabase: not directly exposed, since it's being exposed from nginx on 8443. Exposes a prometheus endpoint + sends logs to loki via a bun api + traces to tempo
- nginx + nginx exporter: exposes prometheus endpoint + sends traces to tempo
- pyroscope: to capture code telemetry
- postgres (as an app db and also as a dw). The postgres app db has an exporter
- setup container: it will set up Metabase with a sample database
- tempo: to capture traces
- email server
- grafana
- prometheus
- loki
- api: gets the postgres log lines and sends that to loki
- ssh server: to connect to databases via ssh tunnels


## Integrated dashboards

Metabase & Postgres dashboards

## How to run

- clone the repo
- install Docker
- do `docker compose up --build` on the root of the repository
- go to https://localhost:8443 and authenticate with a@b.com/metabot1 as the password
- then go to localhost:3030 where grafana is