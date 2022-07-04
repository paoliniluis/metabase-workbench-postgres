FROM mariadb:10.1.48

# We use a standard set of database names and users for our sample images
# MySQL requires a root user password, we just use the same sample password
ENV MYSQL_DATABASE=sample MYSQL_USER=metabase MYSQL_PASSWORD=metasample123 MYSQL_ROOT_PASSWORD=metasample123

ADD https://github.com/metabase/metabase-qa/raw/master/dbs/mysql/data/sample_data.sql.gz /docker-entrypoint-initdb.d/sample_data.sql.gz
RUN chown -R mysql:mysql /docker-entrypoint-initdb.d/

# Similar to other images, we specify a custom mysql data directory so it can be persisted to an image
CMD ["--datadir=/var/lib/mysql-mbsample", "--default-authentication-plugin=mysql_native_password"]
