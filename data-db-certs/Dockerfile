FROM postgres:15.2-alpine

WORKDIR /var/lib/postgresql/

COPY pg_hba.conf /var/lib/postgresql/

RUN apk add openssl &&\
    mkdir keys certs &&\
    chmod og-rwx keys certs &&\
    openssl req -new -x509 -days 365 -nodes -out certs/ca.crt -keyout keys/ca.key -subj "/CN=root-ca" &&\
    mkdir pgconf &&\
    cp certs/ca.crt pgconf/ca.crt &&\
    openssl req -new -nodes -out server.csr -keyout pgconf/server.key -subj "/CN=postgres-another-data-certs" &&\
    openssl x509 -req -in server.csr -days 365 -CA certs/ca.crt -CAkey keys/ca.key -CAcreateserial -out pgconf/server.crt &&\
    chmod og-rwx pgconf/* && chown 70 pgconf/* &&\
    openssl req -new -nodes -out client.csr -keyout keys/client.key -subj "/CN=metabase" &&\
    chmod og-rwx keys/* &&\
    openssl x509 -req -in client.csr -days 365 -CA certs/ca.crt -CAkey keys/ca.key -CAcreateserial -out certs/client.crt &&\
    #now let's move these babies to the format that Metabase accepts to upload
    openssl x509 -topk8 -in certs/ca.crt -outform PEM -out /tmp/ca.pem &&\
    openssl x509 -topk8 -in certs/client.crt -outform PEM -out /tmp/client.pem &&\
    openssl pkcs8 -topk8 -inform PEM -outform DER -in keys/client.key -out /tmp/client.der -nocrypt