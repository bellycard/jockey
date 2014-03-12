class EnvironmentsController < ApiController
  respond_to :json
  before_filter :ensure_user!

  def create
    environment = Environment.create!(environment_params)
    represent_and_render environment, with: EnvironmentRepresenter
  end

  def show
    environment = Environment.lookup(params[:id])
    represent_and_render environment, with: EnvironmentRepresenter
  end

  def index
    environments = Environment.where({})
    represent_and_render environments, with: EnvironmentRepresenter
  end

  private

  def environment_params
    mash_params.slice(:name)
  end
end
