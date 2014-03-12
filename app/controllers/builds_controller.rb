class BuildsController < ApiController
  respond_to :json
  before_filter :ensure_user!

  def index
    builds = Build.where({})
    if params[:app]
      app = App.lookup(params[:app])
      builds = builds.where(app: app)
    end
    builds = builds.where(state: params[:state]) if params[:state]
    builds = builds.where(rref: params[:rref]) if params[:rref]
    render json: paginate(builds.includes(:app), with: BuildRepresenter)
  end

  def create
    app = App.lookup(params[:app])
    raise ActiveRecord::RecordNotFound unless app
    build = app.builds.create!(build_params)
    build.run_in_container!
    represent_and_render build, with: BuildRepresenter
  end

  def show
    build = Build.find(params[:id])
    represent_and_render build, with: BuildRepresenter
  end

  def logs
    build = Build.find(params[:id])
    raise ActiveRecord::RecordNotFound unless build.container_id
    render json: { logs: build.docker_logs }
  end

  private

  def build_params
    mash_params.slice(:app_id, :ref, :callback_url)
  end
end
