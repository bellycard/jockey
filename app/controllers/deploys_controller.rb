class DeploysController < ApiController
  respond_to :json
  before_filter :ensure_user!

  def create
    begin
      app = App.lookup(params[:app])
      environment = Environment.lookup(params[:environment])
    rescue ActiveRecord::RecordNotFound
      error!(present_error(:unprocessable_entity, 'App or Environment not found'), 422)
    end

    if params[:force] == 'true' && app.deploys.in_progress_for(environment).any?
      deploying_ids = app.deploys.in_progress_for(environment).ids

      if deploying_ids.length == 1
        message = "Deploy ID #{deploying_ids.first} is in progress."
      else
        message = "Deploy IDs #{deploying_ids.to_sentence} are in progress."
      end

      message += ' Either wait for completion, or call again with force.'

      error!(present_error(:resource_locked, message), 423)
      return
    end

    build = app.builds.where.not(state: 'failed').find_by rref: params[:rref]

    if build.nil?
      build = app.builds.create(ref: params[:rref])
      build.run_in_container!
    end

    deploy = app.deploys.create!(environment: environment, build: build, callback_url: params[:callback_url])
    deploy.run_in_container!

    render json: represent(deploy, with: DeployRepresenter), status: 202
  end

  def show
    deploy = Deploy.find(params[:id])
    represent_and_render deploy, with: DeployRepresenter
  end

  def logs
    deploy = Deploy.find(params[:id])
    raise ActiveRecord::RecordNotFound unless deploy.container_id
    render json: { logs: deploy.docker_logs }
  end

  def index
    deploys = Deploy.where({})
    if params[:app]
      app = App.lookup(params[:app])
      deploys = deploys.where(app: app)
    end
    if params[:environment]
      environment = Environment.lookup(params[:environment])
      deploys = deploys.where(environment: environment)
    end
    deploys = deploys.where(state: params[:state]) if params[:state]
    render json: paginate(deploys, with: DeployRepresenter)
  end

  private

  def deploy_params
    query_params = mash_params.slice(:config_set_id, :build_id, :scale)
    query_params
  end
end
