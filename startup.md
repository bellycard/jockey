```
# notes for starting the environment locally
docker run -e MYSQL_ROOT_PASSWORD=root -d=true  -p "3306:3306" mysql:5.6.17
docker run -d=true -p "8300:8300" -p "8400:8400" -p "8500:8500" progrium/consul:latest -server -bootstrap -advertise='192.168.59.103'
docker run -e REMOTE_SCRIPT_URL='https://jockey.bellycard.com/container_update' -e CONSUL_URL='http://192.168.59.103:8500' -e DOCKER_HOST='tcp://192.168.59.103:2375' docker_consul_update
```

```
# notes for rails console to start up a service in the env above
ENV['CONSUL_SERVER_URL'] = 'http://192.168.59.103:8500'
bs = App.find_by_name('business-service')
environment = Environment.find_by_name('development')
config_sets = bs.config_sets
cs_dev = config_sets.where(environment: environment).first
worker = Worker.where(app: bs, environment: environment).first
builds = Build.where(app: bs, status: Build.statuses[:completed]).order(created_at: :desc)
build = builds.first
deploy = Deploy.create!(worker: worker, build: build)
deploy.deploy
```
