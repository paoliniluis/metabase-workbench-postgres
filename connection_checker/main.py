from sqlalchemy import create_engine
from sqlalchemy.sql import text
import os, datetime, time

source_host = os.environ['SOURCE']
source_type = os.environ['SOURCE_TYPE']
user_source = os.environ['USER_SOURCE']
pass_source = os.environ['PASS_SOURCE']
db_source = os.environ['DB_SOURCE']

dest_host = os.environ['DEST']
user_dest = os.environ['USER_DEST']
pass_dest = os.environ['PASS_DEST']
db_dest = os.environ['DB_DEST']

source = create_engine(f'{source_type}://{user_source}:{pass_source}@{source_host}/{db_source}')

dest = create_engine(f'postgresql://{user_dest}:{pass_dest}@{dest_host}/{db_dest}')

with dest.connect() as dest_con:
    with source.connect() as source_con:
        while True:
            if 'postgres' in source_type:
                n_of_conns_query = 'SELECT * FROM pg_stat_activity;'
            if 'mysql' in source_type or 'mariadb' in source_type:
                n_of_conns_query = 'SELECT count(*) as n_of_conn FROM information_schema.processlist WHERE user = "metabase"'
            n_of_conns = source_con.execute(n_of_conns_query)
            dest_con.execute(
                text("INSERT INTO connection_metrics (metric_timestamp, number_of_connections) VALUES (:timestamp, :connections)"), 
                [{"timestamp": datetime.datetime.now(), "connections": n_of_conns.first()[0]}]
                )