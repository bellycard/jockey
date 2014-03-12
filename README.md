![Jockey](docs/images/logo.jpg)
[![Circle CI](https://circleci.com/gh/bellycard/jockey.svg?style=svg&circle-token=b594a3940e56f1e9588f33a0338f53d7f55e6e29)](https://circleci.com/gh/bellycard/jockey)

Jockey is an api-driven deployment orchestration framework built around [Docker](https://www.docker.com/) and [Consul](http://www.consul.io/). It allows us to intelligently scale out our service-oriented architecture. It replaces our Chef-based application deployment.

All logic in Jockey is in the backend and exposed by an API. Logic should never exist in a client (Web app, CLI, Hubot, or others). This allows us to build or integrate with tools to enhance our infrastructure further.

Authentication is done against a Github Organization rather than any internal system, as Jockey will likely be used to deploy said internal system.

# Definitions

### App
An App is an application that contains all of its code in a single repository. At this time, only Github repositories are supported. An App can contain a Dockerfile in its repository, which defines how it should be built and run. If one does not exist, [Buildstep](https://github.com/progrium/buildstep/) will be used, which utilizes the Heroku build packs.

### Build
A Build is the result of the `docker build` command. Builds are used in all environments; thus, environment variables are not present during the build.

### Environment
Environments provide logical grouping for Apps. Typically these will be Production, Staging, or similar.

### Stack
Stacks provide another logical grouping for deployment of Apps. Every intersection of Environment and Stack is deployed to a single AWS Auto Scaling Group. This allows each Stack to have different Security Groups (firewall rules) and Instance Types (different ram, cpu, and disk combinations).

### Config Set
Config sets are a group of configuration parameters that are applied to an application in an environment. Eventually, there will be Environment-wide and Stack-wide Config Sets.

### Worker
Apps have one or more Workers. Each worker specifies its own command and scale (how many instances are requested). For example, and App may have web, rabbitmq, and sidekiq workers. Each of these workers can be scaled independently.

Currently, only workers named `web` will be able to receive incoming traffic. Your web worker must accept http traffic on port 8888. In the future, any worker will be able to receive traffic (http, https, or tcp) on any port.

### Deploy
A Deploy is an instance of a Build and Worker at a known time. When a Deploy is created, it instructs each worker to start worker.scale number of instances on the appropriate docker hosts.

# CLI
One interface into Jockey is the CLI. For information on its use and installation, check out [https://github.com/bellycard/jockey_cli](https://github.com/bellycard/jockey_cli).

# Development
To hack on Jockey, you'll need to spin up a large number of dependencies. Fortunately, most of them can run in Docker containers.

### Install Docker and Docker-Compose
Install [Docker](https://docs.docker.com/installation/mac/) 1.6.0 or later and [docker-compose](http://www.fig.sh/install.html) 1.2.0 or later.

Run `boot2docker init && boot2docker start` to start Docker on your machine. Take note of the boot2docker ip (which can be viewed anytime by running `boot2docker ip`). It will likely be `192.168.59.103`, unless there was a conflict on your system already. These commands will also instruct you to add environment variables to your shell's configuration. You should do this.

**If your boot2docker IP isn't the default, be sure to use the actual IP in the ngrok instructions below.**

In development, the Docker Registry will not be running with https, so you'll have to make one change to your boot2docker instance:

1. SSH to the boot2docker vm via `boot2docker ssh`
1. Allow connections to our internal registry by running `echo 'EXTRA_ARGS="--insecure-registry 0.0.0.0/0 "' | sudo tee -a /var/lib/boot2docker/profile` (if you use docker-machine rather than boot2docker, you'll need to edit this file to add the argument instead)
1. Restart docker by running `sudo /etc/init.d/docker restart`
1. Exit the boot2docker vm by running `exit`

### Install ngrok
Because we use Github as our Authentication Provider, we need a way for Github to connect back to Jockey. This requirement could be bypassed with a clever use of your system's hosts file; however, using ngrok will also allow testing of Webhooks and other Github-specific features.

ngrok can be installed from [https://ngrok.com/download](https://ngrok.com/download). [Creating an account](https://ngrok.com/dashboard) is optional, but will enable you to use a custom URL.

Fire up ngrok by running `ngrok 192.168.59.103:4044`. Take note of the Forwarding URLs, specifically the HTTPS version. If you created an account with ngrok, you can specify a custom domain (which is unlikely to change), by running `ngrok -subdomain=jockey-yourname 192.168.59.103:4044` instead.

### Setting up a development Github app
Jockey requires both a Github Application and OAuth Token to access our organization and repositories.

1. Visit [https://github.com/settings/applications](https://github.com/settings/applications)
1. In the `Developer applications` section, click `Register new application`
1. Give your application a name and URL.
1. Add your ngrok forwarding URL (with HTTPS) as the `Authorization callback URL`
1. Click `Register application`
1. Take note of the `Client ID` and `Client Secret`
1. Go back to [https://github.com/settings/applications](https://github.com/settings/applications)
1. In the `Personal access tokens` section, click `Generate new token`
1. Give the token a description, and select the following scopes:
   * repo
   * public_repo
   * write:repo_hook
   * repo:status
   * read:org
   * read:repo_hook
   * repo_deployment
1. Click `Generate Token`
1. Take note of the personal access token

### Starting Jockey
Jockey contains an example `docker-compose.yml` file to bring up an entire development environment. To use it:

1. If you've stopped boot2docker (or restarted your computer), you'll need to start it back up by running `boot2docker up`
1. If your ngrok tunnel is no longer up, restart ngrok, preferably with a custom subdomain (`ngrok -subdomain=jockey-yourname 192.168.59.103:4044`)
1. If your ngrok tunnel has changed its forwarding address, be sure to update your [Github Application](https://github.com/settings/applications)'s callback URL
1. `cp docker-compose.yml.example docker-compose.yml`
1. Open `docker-compose.yml` in your favorite editor - in the `web.environment` stanza:
   - Add your your ngrok URL as the `URL`
   - Add your Github Application Client ID as the `GITHUB_KEY`
   - Add your Github Application Client Secret as the `GITHUB_SECRET`
   - Add your Github Personal access token as the `GITHUB_OAUTH_TOKEN`
1. Run `docker-compose up`
1. Once containers are all up, run `docker-compose run web rake db:reset` to initialize your database with seed data

You should now be able to browse to your ngrok URL and login. You can also use the Jockey CLI against your local instance by altering the JOCKEY_URL Environment variable. There is a sample app already created with the seed data. You can test deploying it by running:

```
JOCKEY_URL=https://ngrok-url jockey deploy 678d49f786ba777441ee9106c1be390048c539ac --app jockey-sample-app --environment development --interactive
```

This will build and deploy [the jockey sample app](https://github.com/bellycard/jockey-sample-app) in two containers. You should see them when running `docker ps` or by viewing [the Consul UI](http://192.168.59.103:8500/ui/#/dc1/services/jockey-sample-app-web). **The initial build may take a while**, as your computer will need to download base images and compile gems.

### Testing changes
All changes you make to Jockey locally, will be reflected in the running containers. The web container runs WEBrick, so changes will be seen right away.

##### Useful links
Once your Jockey environment is up, you can access some of its internals for debugging

 - [ngrok Status](http://localhost:4040)
 - [Consul UI](http://192.168.59.103:8500)
