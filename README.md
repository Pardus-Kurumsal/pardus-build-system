# 1. Pardus Build Environment Setup

This project is in charge of bringing up the Pardus build environment
which consists of Drone CI/CD as a continous integration/delivery
platform of our choice, Gogs as git VCS repository manager, cgit as a
web front-end to our git repositories and a Postgres database server
that will be used by both Gogs and Drone CI.

We implemented this automation logic in a plain Makefile, because it is
the tool your author is most familiar with :). Feel free to send patches
or create PRs if you don't like.

## 2. How to use this Makefile

Follow instructions assume that you have [docker][1] and [docker-compose][2]
installed. You will also need "pardus/distrotracker" image installed on the system.

The Makefile provides you with a couple of useful targets, which you can
use to bootstrap the build environment.

- setup-postgres: Fires up a container for postgres and creates the
  users and databases required by other containers in the system.
- setup-container: Creates Drone, Gogs, cgit and postgres containers
  which will lay the ground for our build system.
- all: This is the default option used when make is run with no targets.
  It sets up the database server and then runs the containers.
- clean: Removes the containers. It just runs 'docker-compose down -v'
- destructive-clean: In addition to the previous 'clean' target, this
  also removes the persistent data under 'DOCKER_VOLS' directory.

Targets above can be built as `make <target-name>`. For example:
```
$ make setup-postgres   # create db users and set their passwords
$ make setup-containers # create and run containers

# This has the same effect as running `make setup-postgres` and then
# `make setup-containers`
$ make
```

In addition to the targets explained above, the makefile looks at the
ADD_SUFFIX variable. If this variable is not empty, the makefile appends
the current date and time as a suffix to the container names defined in
the `docker-compose.yml.in` file. For example:
```
make ADD_SUFFIX=yesplease
```

## 3. Configuration

The Makefile comes with a bunch of variables that can be overriden by
the user.  You can control how the Makefile works by changing these
variables by creating a file called 'config.mk' in the directory where
the Makefile is located. To override these variables, base your config
on 'config.mk.sample' in the source tree.

Here's the list of variables available for use in the config.mk file and
their descriptions.

|Variable           | Description                                                                       |Default value    |
|-------------------|-----------------------------------------------------------------------------------|-----------------|
|DOCKER_VOLS        | base directory for Docker containers to store data in.                            |/var/dockers     |
|POSTGRES_PASSWD    | This variable sets the superuser password for PostgreSQL.                         |123456           |
|DRONE_PORT         | Specify the port number Drone CI listens for                                      |8080             |
|DRONE_PASSWD       | This variable sets the possword for the user 'drone' in the PostgreSQL DB.        |123456           |
|DTRACKER_PORT      | Specify Distro Tracker port number.                                               |8000             |
|DTRACKER_PASSWD    | This variable sets the password for the user 'distrotracker' in PostgreSQL DB.    |123456           |
|GOGS_HOST          | Please fill in with the hostname or IP address of the Docker host machine.        |localhost        |
|GOGS_HOST          | Please fill in with the hostname or IP address of the Docker host machine.        |localhost        |
|GOGS_SECRET_KEY    | Global secret key for your server.                                                |m22UoANwkbZd1PD  |
|GOGS_WEB_PORT      | HTTP port for Gogs.                                                               |10080            |
|GOGS_SSH_PORT      | SSH port for Gogs.                                                                |10022            |
|GOGS_PASSWD        | Assigns a password to 'gogs' postgresql account.                                  |123456           |
|CGIT_SCAN_PATH     | A path which will be scanned for repositories.                                    |/var/git         |
|CGIT_PORT          | HTTP port for Cgit.                                                               |8888             |

[1]: https://docs.docker.com/engine/installation/linux/
[2]: https://docs.docker.com/compose/install/
