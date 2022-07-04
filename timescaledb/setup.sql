CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE TABLE IF NOT EXISTS app_telemetry (
  id SERIAL,
  client VARCHAR,
  request_timestamp TIMESTAMP NOT NULL,
  verb TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  is_async BOOLEAN NOT NULL,
  async_completed TEXT,
  status_code INTEGER,
  response_time FLOAT,
  time_unit TEXT,
  app_db_calls INTEGER,
  app_db_conns INTEGER,
  total_app_db_conns INTEGER,
  jetty_threads INTEGER,
  total_jetty_threads INTEGER,
  jetty_idle INTEGER,
  jetty_queued INTEGER,
  active_threads INTEGER,
  queries_in_flight INTEGER,
  queued INTEGER,
  dw_id VARCHAR,
  dw_db_connections INTEGER,
  dw_db_total_conns INTEGER,
  threads_blocked INTEGER
);

CREATE TABLE IF NOT EXISTS container_telemetry (
  id SERIAL,
  client VARCHAR,
  metric_timestamp TIMESTAMP NOT NULL,
  metric_name TEXT NOT NULL,
  measure NUMERIC
);

CREATE TABLE IF NOT EXISTS connection_metrics (
  id SERIAL,
  metric_timestamp TIMESTAMP NOT NULL,
  number_of_connections INTEGER
);

SELECT create_hypertable('app_telemetry', 'request_timestamp');
SELECT create_hypertable('container_telemetry', 'metric_timestamp');
SELECT create_hypertable('connection_metrics', 'metric_timestamp');

CREATE INDEX IF NOT EXISTS endpoint_time ON app_telemetry (endpoint, request_timestamp DESC);
CREATE INDEX IF NOT EXISTS metric_time ON container_telemetry (metric_name, metric_timestamp DESC);
CREATE INDEX IF NOT EXISTS metric_time ON connection_metrics (number_of_connections, metric_timestamp DESC);