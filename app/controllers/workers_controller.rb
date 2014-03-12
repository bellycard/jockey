class WorkersController < ApiController
  respond_to :json
  before_filter :ensure_user!

  def show
    worker = Worker.find(params[:id])
    represent_and_render worker, with: WorkerRepresenter
  end

  def index
    workers = Worker.where({})
    if params[:app]
      app = App.lookup(params[:app])
      workers = workers.where(app: app)
    end

    if params[:environment]
      environment = Environment.lookup(params[:environment])
      workers = workers.where(environment: environment)
    end

    workers = workers.where(name: params[:worker]) if params[:worker].present?
    represent_and_render workers, with: WorkerRepresenter
  end

  def update
    worker = Worker.find(params[:id])
    worker.update_attributes!(worker_params)
    represent_and_render worker, with: WorkerRepresenter
  end

  def deploys
    worker = Worker.find(params[:id])
    begin
      service = Consul::Service.find(worker.consul_service_name)
    rescue Consul::RecordNotFound
      service = Consul::Service.new(worker.consul_service_name)
    end

    deployed_workers = OpenStruct.new(
      id: worker.id,
      name: worker.consul_service_name,
      instances: service.instances
    )
    represent_and_render deployed_workers, with: DeployedWorkerRepresenter
  end

  def rescale
    app = App.lookup(params[:app])
    environment = Environment.lookup(params[:environment])
    worker = Worker.find_by!(app: app, environment: environment, name: params[:name])

    worker.update_attributes!(scale: params[:scale])
    represent_and_render worker, with: WorkerRepresenter
  end

  def restart_collection
    bad_request("'app' is a required param") unless mash_params.app?
    bad_request("'environment' is a required param") unless mash_params.environment?
    app = App.lookup(params[:app])
    environment = Environment.lookup(params[:environment])

    workers = Worker.where(app: app, environment: environment)
    workers = workers.where(name: params[:worker]) if params[:worker].present?

    raise ActiveRecord::RecordNotFound unless workers.count > 0
    healthy = bool_coerce(params[:healthy])

    workers.includes(:app).each { |w| w.restart!(healthy: healthy) }
    represent_and_render workers, with: WorkerRepresenter
  end

  def restart_member
    worker = Worker.find(params[:id])
    healthy = bool_coerce(params[:healthy])
    worker.restart!(healthy: healthy)
    represent_and_render worker, with: WorkerRepresenter
  end

  private

  def worker_params
    mash_params.slice(:scale, :name)
  end
end
