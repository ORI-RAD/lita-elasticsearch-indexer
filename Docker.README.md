Development with Docker
===
We use [Docker](https://www.docker.com/) to run, test, and debug our application.
The following documents how to install and use Docker on a Mac. There are
[instructions](https://docs.docker.com/installation) for installing and using
docker on other operating systems.

On the mac, we use [docker for mac](https://docs.docker.com/engine/installation/mac/#/docker-for-mac).

We use [docker-compose](https://docs.docker.com/compose/) to automate most of
our interactions with the application.

Table of Contents
===
* [Installation and Upgrade](#installation-and-upgrade)
* [Launching the Application](#launching-the-application)
* [Docker Compose](#docker-compose)
* [Dockerfile](#dockerfile)
* [Useful Docker Commands](#useful-docker-commands)
* [Bash Profile](#bash-profile)

Installation and Upgrade
===
Docker makes it easy to install docker for mac, which includes docker, and docker-compose
on your mac, and keep them upgraded in sync.  Follow the instructions
to install [Docker 4 Mac]((https://docs.docker.com/engine/installation/mac/#/docker-for-mac).

Once you have docker running, you can run any of the following commands to test
that docker is working:
```
docker ps
```
This should always return a table with the following headers, and 0 or more
entries:

`CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES`

```
docker images
```
Similar to above, it should always return a table with the following headers, and
0 or more entries:

`REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE`

Launching the Application
===

Create lita.env in the Application root, using lita.env.example. If you are using
slack, you will need to create a [Slack API Token](https://my.slack.com/services/new/lita)
and add it to the LITA_SLACK_TOKEN variable.

In the Application root, run the following:
```bash
touch Gemfile.lock
docker-compose up -d
```

Docker Compose
===

Once you have docker installed, you can use docker-compose to run all of the
commands that you would normally run when developing and testing the application.
Docker Compose uses one or more yml files to specify everything required to build
and run the application and any other support application (databases, volume
containers, etc.) it requires. There are multiple docker-compose yml files in
the Application Root, explained below.

docker-compose.yml
---
This is the base docker-compose file used to manage the server.

Anyone with docker and docker-compose can run the following command from within
the Application Root (where this file you are reading resides), to build the server
image (You must be connected to the internet so that docker can
pull down any base docker images, or package/gem installs, for this to work).

```
docker-compose build
```
Once you have built the images, you can launch containers of all services
required by the app (docker calls a running instance of a docker image a docker
container):
```
docker-compose up -d
```

The docker-compose definition for the 'server' service mounts the Application
Root as /var/www/app in the server docker container.  Since the Dockerfile specifies
/var/www/app as its default WORKDIR, this allows you to make changes to the files
on your machine and see them reflected live in the running server (although see
[below](#dockerfile) for **important information about modifying the Gemfile**).

The Dockerfile hosts the application on port 3000 inside the container,
and the docker-compose service definition attaches this to port 3000 on the
host machine (this will fail if you have another service of any kind attached to
port 3000 on the same host).
To connect to this host you can use curl, or your browser to connect to
http://localhost:3000/api/v1/app/status to check the status of
the application. All other parts of the application are served at
http://localhost:3000.

docker-compose.dev.yml
---
This file extends docker-compose.yml to add service definitions to make it possible
to easily run things like bundle, rspec, rails, rake, etc (see below for more).

You can use this by adding the -f docker-compose.yml -f docker-compose.dev.yml flag
to all of your docker-compose commands, e.g.
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rails c
```

Alternatively, you can use the fact that docker-compose looks for both docker-compose.yml
and docker-compose.override.yml by default, and create a symlink from docker-compose.dev.yml
to docker-compose.override.yml that will make docker-compose use both by default, without
any of the extra -f flags.
```
ln -s docker-compose.dev.yml docker-compose.override.yml
```
Note, you should add docker-compose.override.yml to your .gitignore, so it will
never be committed to the repo. This ensures that the default behavior for those
not wishing to use the extra functionality in docker-compose.dev.yml is preserved.

You should always specify the exact service (e.g. top level key
in the docker-compose.dev.yml file) when running docker-compose commands using this
docker-compose.dev.yml file. Otherwise, docker-compose will try to run all services,
which will cause things to run that do not need to run (such as bundle).

default docker-compose commands
---
Using just the docker-compose.yml, e.g. docker-compose.override.yml file/symlink
is not present:

Launch the server to interact with the application:
```
docker-compose up -d server
```
Docker-compose is smart enough to realize all of the linked services required,
and spin them up in order. This will not launch a swift service.

Bring down and delete running containers:
```
docker-compose down
```

docker-compose.dev.yml docker-compose commands
---
Either use -f docker-compose.yml -f docker-compose.dev.yml, like so:
Run rspec
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rspec
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run rspec spec/requests
```

Or create a symlink from docker-compose.dev.yml to docker-compose.override.yml.
This is the recommended way to use docker-compose.dev.yml, as it will be more
permanent between invocations of the shell terminal.
```
ln -s docker-compose.dev.yml docker-compose.override.yml
```

Then you can run services like rspec without the extra -f flags:
```
docker-compose run rspec
docker-compose run rspec spec/requests
```

The following commands assume the symlink exists.
Run bundle (see
[below](#dockerfile) for **important information about modifying the Gemfile**)):
```
docker-compose run bundle
```

Run rake commands (default RAILS_ENV=development):
```
docker-compose run rake db:migrate
docker-compose run rake db:seed
docker-compose run rake db:migrate RAILS_ENV=test
```

Run rails commands (default RAILS_ENV=docker):
```
docker-compose run rails c
docker-compose run rails c RAILS_ENV=test
```

**Note about docker-compose down**
You should run docker-compose down using the same docker-compose yml file context,
e.g. with COMPOSE_FILE set, or the docker-compose.override.yml file in existence,
or using the -f flags for all docker-compose yml files. Otherwise, services defined
in the missing docker-compose.yml file will not be shut down and removed, and a warning
may come up in your output that says containers were 'orphaned'.

Dockerfile
===
Docker uses a [Dockerfile](https://docs.docker.com/reference/builder/) to
specify how to build an image to host an application. We have created a
Dockerfile in the Application Root. This Dockerfile:
* installs required libraries for ruby, rails, node, etc.
* installs specific versions of ruby
* installs the sqlite client libraries
* creates /var/www/app and sets this to the default working directory
* adds Gemfile and Gemfile.lock (see below)
* bundles to install required gems into the image
* exposes 3000
* sets up to run the rails server to host the service by default

**Important information about modifying the Gemfile**
When you need to add a gem to your Gemfile, you will also need to rebuild
the server. This will permenently install the new gem into the server image.

```
docker-compose build server
```
You then need to run bundle, which will update Gemfile.lock in the Application
Root
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run bundle
```
You should then commit and push the new Gemfile and Gemfile.lock to the repository.

Docker basics
===

To stop all running docker containers (you must stop a container before you can
remove it or its image):
```
docker-compose stop
```

To stop and/or remove all containers, use the following:
```
docker-compose down
```

When a docker container stops for any reason, docker keeps it around in its
system. There are ways you can start and attach to a stopped container, but
in many cases this is not useful. You should remove containers on a regular basis.
When you start up the machines from scratch, you will need to run rake db:migrate,
etc. to get the database ready.

You can list all running containers using the following command:
```
docker ps
```
You can list all containers (both running and stopped):
```
docker ps -a
```

Each docker container is given a long UUID by docker (called the CONTAINERID).  
You can use this UUID (or even the first 4 or more characters) to stop
and remove a container using the docker commandline instead of
using docker-compose (see Docker [commandline documentation](https://docs.docker.com/engine/reference/commandline)
for other things you can find out about a running container using the docker command):
```
docker stop UUID
docker rm -v UUID
```

Sometimes docker will leave files from a container on the host, which can build
up over time and cause your VM to become sluggish or behave strangely.  We
recommend adding the -v (volumes) flag to docker rm commands to make sure these
files are cleaned up appropriately.  Also, docker ps allows you to pass the -q
flag, and get only the UUID of the containers it lists.  Using the following
command, you can easily stop all running containers:
```
docker stop $(docker ps -q)
```

Similarly, to remove all stopped containers (this will skip running containers, but
print a warning for each):
```
docker rm -v $(docker ps -aq)
```

You may also need to check for volumes that have been left behind when containers
were removed without explicitly using docker rm -v, such as when docker-compose down
is run.  To list all volumes on the docker host:
```
docker volume ls
```

The output from this is very similar to all other docker outputs. Each volume is
assigned a UUID. You can remove a specific volume with:
```
docker volume rm UUID
```

You can remove all volumes using the -q pattern used in other docker commands
```
docker volume rm $(docker volume ls -q)
```

We recommend running some of these frequently to clean up containers and volumes that
build up over time. Sometimes, when running a combination docker rm $(docker ls -q)
pattern command when there is nothing to remove, docker will print a warning that
it requires 1 or more arguments, but this is ok. It can be useful to put some or
all of these in your Bash Profile.

Bash Profile
===
The following can be placed in the .bash_profile file located in your
HOME directory (e.g. ~/.bash_profile)

```bash_profile
# Docker configurations and helpers
alias docker_stop_all='docker stop $(docker ps -q)'
alias docker_cleanup='docker rm -v $(docker ps -aq)'
alias docker_images_cleanup='docker rmi $(docker images -f dangling=true -q)'
alias docker_volume_cleanup='docker volume rm $(docker volume ls -q)'

# fake rake/rails/rspec using docker under the hood
# this depends on either a docker-compose.override.yml, or COMPOSE_FILE
# environment variable
alias rails="docker-compose run rails"
alias rake="docker-compose run rake"
alias rspec="docker-compose run rspec"
alias bundle="docker-compose run bundle"
alias dcdown="docker-compose down"
```
