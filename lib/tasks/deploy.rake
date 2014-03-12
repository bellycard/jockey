namespace :deploy do
  desc 'run a deploy, given its id'
  # rake deploy:run[deploy_id]
  task :run, [:deploy_id] => :environment do |t, args|
    deploy = Deploy.find(args[:deploy_id])
    deploy.run!
  end

  desc 'create and run a deploy'
  # rake deploy:create[app,env,rref]
  task :create, [:app,:env,:rref] => :environment do |t, args|
    app = App.lookup(args[:app])
    raise ActiveRecord::RecordNotFound unless app
    env = Environment.lookup(args[:env])
    raise ActiveRecord::RecordNotFound unless env

    build = app.builds.where.not(state: 'failed').find_by rref: args[:rref]

    if build.nil?
      build = app.builds.create(ref: args[:rref])
      build.run!
    end

    deploy = app.deploys.create!(environment: env, build: build)
    deploy.run!
  end
end
