class AppsController < ApiController
  respond_to :json
  before_filter :ensure_user!

  def create
    app = App.create!(app_params)
    represent_and_render app, with: AppRepresenter
  end

  def show
    app = App.lookup(params[:id])
    represent_and_render app, with: AppRepresenter
  end

  def index
    apps = App.where(app_params)
    represent_and_render apps, with: AppRepresenter
  end

  def available_node
    app = App.lookup(params[:app])
    environment = Environment.lookup(params[:environment])
    worker = Worker.where(app: app, environment: environment).first
    node = NodeSelection.new(worker: worker).next_available_nodes.first
    # our simple represent logic chokes on a Hash because it responsds to .to_a
    render json: { data: node }
  end

  private

  def app_params
    mash_params.slice(:subscribe_to_github_webhook, :name, :repo)
  end
end
