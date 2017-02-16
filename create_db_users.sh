#!/bin/sh
set -e

# $1: username
# $2: password
create_db_user() {
    local user=$1
    local pass=$2

    cat << EOF >> bootstrap.sql
DO
\$body\$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = '${user}') THEN

      CREATE ROLE ${user} LOGIN PASSWORD '${pass}';
   END IF;
END
\$body\$;
EOF
}

# $1: dbname
# $2: dbuser
create_db() {
    local dbname=$1
    local dbuser=$2

    if ! docker exec -it postgressetup psql -U postgres \
        -c "CREATE DATABASE ${dbname} OWNER ${dbuser};"; then
        echo "WARNING! db \"${dbname}\" could not be created!";
    fi
}

spawn_container() {
    local postgres_passwd=$1
    local docker_vols=$2
    local postgres_delay=$3
    # echo $postgres_passwd, $docker_vols, $postgres_delay

    echo 'Spinning up a new Postgres container...'
    docker run -de POSTGRES_PASSWORD=${postgres_passwd} --name=postgressetup \
        -v ${docker_vols}/postgres:/var/lib/postgresql/data kiasaki/alpine-postgres > /dev/null 2>&1

    # Wait for service to be up and running
    while ! docker exec -it postgressetup psql -U postgres -c "\l" > /dev/null 2>&1; do \
        sleep ${postgres_delay}; \
        echo "Waiting for Postgres to start..."; \
    done
}

# $1: sql file
do_psql() {
    docker cp ${1} postgressetup:/tmp/
    docker exec -it postgressetup psql -U postgres \
        -f /tmp/bootstrap.sql > /dev/null 2>&1
}

clean_up() {
    echo 'Removing temporary Postgres container'
    docker rm -f postgressetup > /dev/null 2>&1 || true
}
trap clean_up EXIT

# Empty file, if exists
> bootstrap.sql

POSTGRES_PASSWD=$1
POSTGRES_DELAY=$2
GOGS_PASSWD=$3
DRONE_PASSWD=$4
DOCKER_VOLS=$5

create_db_user gogs ${GOGS_PASSWD}
create_db_user drone ${DRONE_PASSWD}

spawn_container ${POSTGRES_PASSWD} ${DOCKER_VOLS} ${POSTGRES_DELAY}

do_psql ./bootstrap.sql
create_db gogs gogs
