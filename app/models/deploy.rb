class Deploy < ActiveRecord::Base
  include DockerLoggable
  include RailsAdminGenericRender

  belongs_to :build
  belongs_to :environment
  belongs_to :app

  validates_presence_of :build, :environment
  validates_associated :build, :environment

  before_validation :set_initial_state, on: :create

  scope :incomplete, -> { where(completed_at: nil) }
  scope :stuck, -> { incomplete.where("created_at <= ?", 1.hour.ago) }

  rails_admin do
    configure :render_actions do
      visible false # so it's not on new/edit
    end

    show do
      include_all_fields
      field :app
      field :rref
      field :render_actions do
        label 'Actions'
      end
    end
  end

  scope :in_progress_for, lambda { |environment|
    env = Environment.lookup(environment)
    where(state: %w(created building deploying), environment: env)
  }

  valid_states = %w(created failed building deploying deployed stopped)
  validates_inclusion_of :state, in: valid_states

  valid_states.each do |s|
    define_method "#{s}?" do
      state == s
    end
  end

  def run!
    update!(state: 'building')

    wait_for_build

    update!(state: 'deploying')
    Napa::Logger.logger.info("#{app.name} for deploy:#{id} is running.")

    update_github_tag
    Napa::Logger.logger.info("Setting #{environment.name} tag for #{app.name} on Github.")

    spawn_containers

    # wait for boot unless all worker's scale is zero
    wait_for_boot unless workers.map(&:scale).all?(&:zero?)

    # stop other workers
    stop_containers
    running_deploys.each(&:stop!)

    update!(state: 'deployed', completed_at: Time.now)

    msg = "Deploy #{id} for #{app.name}:#{rref.first(10)} #{state.upcase}"
    Napa::Logger.logger.info(msg)
    Webhook.post_for_app(app, message: msg, color: '#00ff00', from_name: 'jockey deploy')
  rescue => e
    reason = "#{e.message}\nStacktrace:\n#{e.backtrace.join("\n\t")}"
    update(state: 'failed', failure_reason: reason, completed_at: Time.now)

    msg = "Deploy #{id} for #{app.name}:#{rref.first(10)} #{state.upcase}"
    Napa::Logger.logger.error("#{msg}:\n#{reason}")
    Webhook.post_for_app(app, message: "#{msg}: #{e.message.first(255)}", color: '#ff0000', from_name: 'jockey deploy')
  ensure
    post_to_callback
  end

  def run_in_container!
    container = Container.background("rake deploy:run[#{id}]")
    update!(container_host: container['host'], container_id: container['id'])
  rescue => e
    msg = "Failed to start deploy container:\n#{e.message}\n\nStacktrace:\n#{e.backtrace.join("\n\t")}"
    Napa::Logger.logger.error(msg)
  end

  def wait_for_boot
    counter = 0
    loop do
      break if running?
      raise "Could not detect a running instance of #{app.name} for deploy:#{id}" if counter > 500
      Napa::Logger.logger.warn("Waiting for #{app.name} to boot...")
      counter += 1
      sleep(1)
    end
  end

  def stop_containers
    # stop containers running this service
    # if a service is running more than once on a node, there will be more than one service in the list
    consul_instances.each do |instance|
      # skip this deploy's instances
      next if instance.tags.include?("deploy_id:#{id}")

      begin
        logger.info("stopping #{app.name} for deploy #{id} on #{instance.node.id}")
        Container.stop(instance.node, instance.id)

        # TODO: once things are stable, we likely don't need to flood slack with every stop/start
        Webhook.post_for_app(
          app,
          message: "#{app.name} deploy #{id}:#{rref.first(10)} stopped",
          color: '#cccccc',
          from_name: 'jockey deploy'
        )
      rescue => e
        logger.error(e.message)
        logger.error(
          "Could not stop an container #{instance.id} on node: #{instance.node.id}"
        )
        raise e
      end
    end
  end

  def running?
    # TODO: ensure one of each worker is up rather than one total
    begin
      consul_instances.each do |instance|
        # skip the health checks not related to this deploy
        next unless instance.tags.include?("deploy_id:#{id}")
        # consider success a single instance is healthy
        return true if instance.healthy?
      end
    rescue Consul::RecordNotFound
      return false
    end
    false
  end

  def wait_for_build
    # define how long to wait for a build, or a default of 1800 seconds (30 minutes)
    build_timeout = ENV['DEPLOY_BUILD_TIMEOUT'] || 1800

    counter = 0
    loop do
      # reload model, as we expect it to change
      build.reload

      break if build.completed?
      raise "build #{build.id} failed: #{build.failure_reason}" if build.failed?
      raise "Timed out (#{build_timeout} seconds) waiting for build #{build.id} to complete" if counter > build_timeout

      Napa::Logger.logger.warn("Waiting for build #{build.id} for app #{app.name} to complete...")
      counter += 1
      sleep(1)
    end
  end

  def running_deploys
    Deploy.where(app: app, environment: environment, state: [:created, :deploying, :deployed]).where.not(id: id)
  end

  def workers
    Worker.where(app: app, environment: environment)
  end

  def rref
    build.try(:rref) || ''
  end

  def consul_instances
    workers.map(&:instances).flatten
  end

  def rref=(reference)
    self.build = app.builds.latest_for_rref(reference)
    self.build ||= app.builds.build(ref: reference)
  end

  def spawn_containers
    workers.each do |worker|
      nodes = NodeSelection.new(worker: worker).next_available_nodes(worker.scale)
      nodes.each do |node|
        create_container_for_worker(worker.id, node.id)
      end
    end
  end

  def create_container_for_worker(worker_id, node_id)
    worker = workers.find(worker_id)
    node = Consul::Node.find(node_id)
    Container.start_worker(node, worker, build.rref, 'deploy_id' => id)
  end

  def update_github_tag(force = false)
    client = Octokit::Client.new(access_token: ENV.fetch('GITHUB_OAUTH_TOKEN'))
    # https://github.com/octokit/octokit.rb/blob/196a637daf352702d6250188af16b825ecc02abb/lib/octokit/client/refs.rb#L67
    # https://github.com/bellycard/napa/blob/032b9a36d7a11d7e4b9d1a7460c2a5e846b19532/lib/napa/deploy.rb#L31-L42
    begin
      client.update_ref(app.repo, "tags/#{environment.name}", self.build.rref, force)
    rescue Octokit::UnprocessableEntity
      client.create_ref(app.repo, "tags/#{environment.name}", self.build.rref)
    end
  end

  def set_initial_state
    self.state ||= 'created'
  end

  def stop!
    update! state: 'stopped'
  end

  def post_to_callback
    return if callback_url.blank?

    Napa::Logger.logger.info("Posting deploy data to callback for deploy #{id}")
    conn = Faraday.new(url: callback_url) do |faraday|
      faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
    end
    conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = DeployRepresenter.new(self).to_json
      req.options.timeout = 30           # open/read timeout in seconds
      req.options.open_timeout = 30      # connection open timeout in seconds
    end
  end
end
