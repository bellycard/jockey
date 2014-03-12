class Reconcile < ActiveRecord::Base
  include DockerLoggable

  belongs_to :environment
  belongs_to :app
  serialize :plan

  scope :incomplete, -> { where(completed_at: nil) }
  scope :stuck, -> { incomplete.where("created_at <= ?", 1.hour.ago) }

  after_initialize :generate_plan

  valid_states = %w(preview in_progress completed failed)
  validates_inclusion_of :state, in: valid_states

  before_validation :set_initial_state, on: :create

  def set_initial_state
    self.state ||= 'preview'
  end

  valid_states.each do |s|
    define_method "#{s}?" do
      state == s
    end
  end

  rails_admin do
    field :plan, :json
    include_all_fields
  end

  def generate_plan
    workers = Worker.where(environment: environment)
    workers = workers.where(app: app) if app

    self.plan = workers.reduce([]) do |plan, worker|
      instances = Consul::Service.new(worker.consul_service_name).instances

      if instances.length > worker.scale
        extra_instances_random_order = instances.sample(instances.length - worker.scale)

        extra_instances_random_order.each do |instance|
          plan << { action: 'stop', instance: instance, worker: worker }
        end

        instances -= extra_instances_random_order
      elsif instances.length < worker.scale
        ns = NodeSelection.new(worker: worker)
        nodes_needed_to_match_scale = ns.next_available_nodes(worker.scale - instances.length)
        rref = worker.app.current_deploy(environment).rref

        nodes_needed_to_match_scale.each do |node|
          plan << { action: 'start', worker: worker, rref: rref, node: node }
        end
      end

      instances.each do |instance|
        plan << { action: 'restart', instance: instance, worker: worker } unless instance.healthy?
      end
      plan
    end
  end

  def run!
    update!(state: 'in_progress')

    plan.each do |step|
      if step[:action] == 'start'
        worker = step[:worker]
        rref = step[:rref]

        Napa::Logger.logger.info("starting #{worker.name} for #{worker.app}:#{rref} in #{worker.environment}")
        Container.start_worker(step[:node], worker, rref)

      elsif step[:action] == 'stop'
        instance = step[:instance]

        Napa::Logger.logger.info("stopping container #{instance.id} on node #{instance.node.id}")
        Container.stop(instance.node, instance.id)

      elsif step[:action] == 'restart'
        instance = step[:instance]

        Napa::Logger.logger.info("restarting container #{instance.id} on node #{instance.node.id}")
        Container.restart(instance.node, instance.id)
      end
    end

    update!(state: 'completed', completed_at: DateTime.now)

    app_msg = ''
    app_msg = "app #{app.name} in " if app
    msg = "Reconcile #{id} for #{app_msg}environment #{environment.name} #{state.upcase}"
    Napa::Logger.logger.info(msg)
  rescue => e
    reason = "#{e.message}\nStacktrace:\n#{e.backtrace.join("\n\t")}"
    update(state: 'failed', failure_reason: reason, completed_at: Time.now)

    app_msg = ''
    app_msg = "app #{app.name} in " if app
    msg = "Reconcile #{id} for #{app_msg}environment #{environment.name} #{state.upcase}"
    Napa::Logger.logger.error("#{msg}:\n#{reason}")
  ensure
    post_to_callback
  end

  def run_in_container!
    container = Container.background("rake reconcile:run[#{id}]")
    update!(container_host: container['host'], container_id: container['id'])
  rescue => e
    msg = "Failed to start reconcile container:\n#{e.message}\n\nStacktrace:\n#{e.backtrace.join("\n\t")}"
    Napa::Logger.logger.error(msg)
  end

  def post_to_callback
    return if callback_url.blank?

    Napa::Logger.logger.info("Posting reconcile data to callback for reconcile #{id}")
    conn = Faraday.new(url: callback_url) do |faraday|
      faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
    end
    conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = ReconcileRepresenter.new(self).to_json
      req.options.timeout = 30           # open/read timeout in seconds
      req.options.open_timeout = 30      # connection open timeout in seconds
    end
  end
end
