class ConfigSetsController < ApiController
  respond_to :json
  before_filter :ensure_user!

  def create
    config_set = ConfigSet.create!(config_set_params)
    represent_and_render config_set, with: ConfigSetRepresenter
  end

  def update
    config_set = ConfigSet.find(params[:id])
    config_set.update_attributes(config: config_set.config.merge(mash_params.config))
    represent_and_render config_set, with: ConfigSetRepresenter
  end

  def show
    config_set = ConfigSet.find(params[:id])
    represent_and_render config_set, with: ConfigSetRepresenter
  end

  def index
    config_sets = ConfigSet.where({})
    if params[:app]
      app = App.lookup(params[:app])
      config_sets = config_sets.where(app: app)
    end

    if params[:environment]
      environment = Environment.lookup(params[:environment])
      config_sets = config_sets.where(environment: environment)
    end
    represent_and_render config_sets, with: ConfigSetRepresenter
  end

  private

  def config_set_params
    query_params = mash_params.slice(:app, :environment, :config)
    query_params.app = App.lookup(params[:app])
    query_params.environment = Environment.lookup(params[:environment])
    query_params
  end
end
