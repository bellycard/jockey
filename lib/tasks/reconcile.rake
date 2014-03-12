namespace :reconcile do
  desc "run a reconcile, given its id"
  task :run, [:reconcile_id] => :environment do |t, args|
    reconcile = Reconcile.find(args[:reconcile_id])
    reconcile.run!
  end

  desc 'create and run a reconcile'
  task :create, [:env,:app] => :environment do |t, args|
    env = Environment.lookup(args[:env])
    app = App.lookup(args[:app]) if args[:app]

    reconcile = Reconcile.create!(environment: env, app: app)
    reconcile.run!
  end
end
