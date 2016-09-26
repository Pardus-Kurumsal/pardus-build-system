ifneq ("$(wildcard config.mk)","")
    CONFIG_MK=config.mk
endif

-include config.mk

POSTGRES_DELAY ?= 5

DOCKER_VOLS ?= /var/dockers

DRONE_PORT ?= 8080
DRONE_PASSWD ?= 123456

GOGS_WEB_PORT ?= 10080
GOGS_SSH_PORT ?= 10022
GOGS_PASSWD ?= 123456

POSTGRES_PASSWD ?= 123456

CGIT_SCAN_PATH ?= /var/git
CGIT_PORT ?= 8888
CGIT_RC_FILE ?= etc/cgitrepos

CGIT_RC_PATH := $(DOCKER_VOLS)/$(CGIT_RC_FILE)
CGIT_RC_CONTENT := "scan-path=$(CGIT_SCAN_PATH)"

CLEANFILES := dronerc docker-compose.yml $(CGIT_RC_PATH)

all: up

docker-compose.yml: docker-compose.yml.in $(CONFIG_MK)
	@echo 'GEN	'$@;cp -f $< $@
	@sed -i -e 's|@@DOCKER_VOLS@@|$(DOCKER_VOLS)|g' "$@"
	@sed -i -e 's|@@DRONE_PORT@@|$(DRONE_PORT)|g' "$@"
	@sed -i -e 's|@@DRONE_PASSWD@@|$(DRONE_PASSWD)|g' "$@"
	@sed -i -e 's|@@GOGS_WEB_PORT@@|$(GOGS_WEB_PORT)|g' "$@"
	@sed -i -e 's|@@GOGS_SSH_PORT@@|$(GOGS_SSH_PORT)|g' "$@"
	@sed -i -e 's|@@GOGS_PASSWD@@|$(GOGS_PASSWD)|g' "$@"
	@sed -i -e 's|@@CGIT_PORT@@|$(CGIT_PORT)|g' "$@"

dronerc: dronerc.in $(CONFIG_MK)
	@echo 'GEN	'$@;cp -f $< $@
	@sed -i -e 's|@@DRONE_PASSWD@@|$(DRONE_PASSWD)|g' "$@"

$(CGIT_RC_PATH): $(CONFIG_MK)
	@echo 'GEN	'$@
	@mkdir -p $(dir $@)
	@echo $(CGIT_RC_CONTENT) > $@

setup-postgres:
	@echo 'Setting up Postgres database server...'
	@echo 'Spinning up a new Postgres container'
	@docker run -de POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) --name=postgressetup \
	    -v $(DOCKER_VOLS)/postgres:/var/lib/postgresql/data kiasaki/alpine-postgres
	@sleep $(POSTGRES_DELAY)
	@docker exec -it postgressetup psql -U postgres -c "CREATE USER gogs WITH PASSWORD '$(GOGS_PASSWD)';"
	@docker exec -it postgressetup psql -U postgres -c "CREATE USER drone WITH PASSWORD '$(DRONE_PASSWD)';"
	@docker exec -it postgressetup psql -U postgres -c "CREATE DATABASE gogs OWNER gogs;"
	@echo 'Removing temporary Postgres container'
	@docker rm -f postgressetup

up: dronerc $(CGIT_RC_PATH) docker-compose.yml setup-postgres
	@echo 'Starting up docker-compose'
	@docker-compose up -d

clean:
	-docker-compose down -v > /dev/null 2>&1
	-rm -f $(CLEANFILES)

.PHONY: all clean setup-postgres
