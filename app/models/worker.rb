class Worker < ActiveRecord::Base
  belongs_to :app
  belongs_to :environment
  has_paper_trail
  validate :config_set_exists
  validates_presence_of :name
  validates_numericality_of :scale, less_than_or_equal_to: 11, only_integer: true, greater_than_or_equal_to: 0
  after_commit :reconcile_if_scale_changed, on: :update

  def config_set
    ConfigSet.where(app_id: app_id, environment_id: environment_id).first
  end

  def reconcile!
    @reconcile = Reconcile.create(environment: environment, app: app)
    @reconcile.run_in_container!
  end

  def running?
    nodes_running_on.any?
  end

  def nodes_running_on
    Consul::Service.find(consul_service_name).nodes
  rescue Consul::RecordNotFound
    []
  end

  def instances
    Consul::Service.find(consul_service_name).instances
  rescue Consul::RecordNotFound
    []
  end

  def consul_service_name
    # needs to match what we can pull from the container's image name
    "#{app.name}-#{name}".gsub(/_/, '-').parameterize
  end

  def restart!(healthy: nil)
    consul_instances = instances
    consul_instances.select! { |i| i.healthy? == healthy } unless healthy.nil?
    consul_instances.each do |instance|
      logger.info("restarting #{app.name} on #{instance.node.id}")
      Container.restart(instance.node, instance.id)
    end
  end

  private

  def reconcile_if_scale_changed
    reconcile! if previous_changes[:scale]
  end

  def config_set_exists
    errors.add(:base, 'config set does not exist') unless config_set
  end
end
