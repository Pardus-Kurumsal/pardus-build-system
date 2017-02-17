ifneq ("$(wildcard config.mk)","")
    CONFIG_MK=config.mk
endif

-include config.mk

POSTGRES_DELAY ?= 8

DOCKER_VOLS ?= /var/dockers

DRONE_PORT ?= 8080
DRONE_PASSWD ?= 123456

DTRACKER_PORT ?= 8000
DTRACKER_PASSWD ?= 123456

GOGS_HOST ?= localhost
GOGS_SECRET_KEY ?= m22UoANwkbZd1PD
GOGS_WEB_PORT ?= 10080
GOGS_SSH_PORT ?= 10022
GOGS_PASSWD ?= 123456
GOGS_APP_INI_PATH ?= $(DOCKER_VOLS)/gogs/gogs/conf/app.ini

POSTGRES_PASSWD ?= 123456

CGIT_SCAN_PATH ?= /var/git
CGIT_PORT ?= 8888
CGIT_RC_FILE ?= etc/cgitrepos

CGIT_RC_PATH := $(DOCKER_VOLS)/$(CGIT_RC_FILE)
CGIT_RC_CONTENT := "scan-path=$(CGIT_SCAN_PATH)"

CLEANFILES := dronerc docker-compose.yml $(CGIT_RC_PATH) \
	    $(GOGS_APP_INI_PATH) bootstrap.sql

ifneq ($(ADD_SUFFIX),)
    SUFFIX:=_$(shell date +'%Y%m%d%H%M%S')
endif

all: setup

docker-compose.yml: docker-compose.yml.in $(CONFIG_MK)
	@echo 'GEN	'$@;
	@sed -e 's|@@DOCKER_VOLS@@|$(DOCKER_VOLS)|g' \
	     -e 's|@@DRONE_PORT@@|$(DRONE_PORT)|g' \
	     -e 's|@@DRONE_PASSWD@@|$(DRONE_PASSWD)|g' \
	     -e 's|@@DTRACKER_PORT@@|$(DTRACKER_PORT)|g' \
	     -e 's|@@DTRACKER_PASSWD@@|$(DTRACKER_PASSWD)|g' \
	     -e 's|@@GOGS_WEB_PORT@@|$(GOGS_WEB_PORT)|g' \
	     -e 's|@@GOGS_SSH_PORT@@|$(GOGS_SSH_PORT)|g' \
	     -e 's|@@GOGS_PASSWD@@|$(GOGS_PASSWD)|g' \
	     -e 's|@@SUFFIX@@|$(SUFFIX)|g' \
	     -e 's|@@CGIT_PORT@@|$(CGIT_PORT)|g' $< > $@

dronerc: dronerc.in $(CONFIG_MK)
	@echo 'GEN	'$@
	@sed -e 's|@@DRONE_PASSWD@@|$(DRONE_PASSWD)|g' $< > $@

$(CGIT_RC_PATH): $(CONFIG_MK)
	@echo 'GEN	'$@
	@mkdir -p $(dir $@)
	@echo $(CGIT_RC_CONTENT) > $@

$(GOGS_APP_INI_PATH): app.ini.in $(CONFIG_MK)
	@echo 'GEN	'$@
	@mkdir -p $(dir $@)
	@sed -e 's|@@SUFFIX@@|$(SUFFIX)|g' \
	     -e 's|@@GOGS_PASSWD@@|$(GOGS_PASSWD)|g' \
	     -e 's|@@GOGS_HOST@@|$(GOGS_HOST)|g' \
	     -e 's|@@GOGS_WEB_PORT@@|$(GOGS_WEB_PORT)|g' \
	     -e 's|@@GOGS_SSH_PORT@@|$(GOGS_SSH_PORT)|g' \
	     -e 's|@@GOGS_SECRET_KEY@@|$(GOGS_SECRET_KEY)|g' $< > $@

setup-postgres: $(CONFIG_MK)
	./create_db_users.sh $(POSTGRES_PASSWD) $(POSTGRES_DELAY) \
	    $(GOGS_PASSWD) $(DRONE_PASSWD) $(DTRACKER_PASSWD) $(DOCKER_VOLS)

setup-containers: dronerc $(CGIT_RC_PATH) $(GOGS_APP_INI_PATH) docker-compose.yml
	@echo 'Starting up docker-compose'
	@docker-compose up -d

setup: setup-postgres setup-containers
	@echo 'DONE!'

clean:
	@echo 'Removing composed docker containers...';docker-compose down -v > /dev/null 2>&1 || true
	-rm -f $(CLEANFILES)

destructive-clean: clean
	@echo 'WARNING: Removing persistent container data: '$(DOCKER_VOLS)
	-rm -fr $(DOCKER_VOLS)

.PHONY: clean destructive-clean setup-postgres setup
