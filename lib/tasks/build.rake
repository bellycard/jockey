namespace :build do
  desc 'run a build, given its id'
  # rake build:run[build_id]
  task :run, [:build_id] => :environment do |t, args|
    build = Build.find(args[:build_id])
    build.run!
  end

  desc 'create and run a build'
  # rake build:create[app,ref]
  task :create, [:app,:ref] => :environment do |t, args|
    app = App.lookup(args[:app])
    raise ActiveRecord::RecordNotFound unless app
    build = app.builds.create!(app: app, ref: args[:ref])
    build.run!
  end
end
