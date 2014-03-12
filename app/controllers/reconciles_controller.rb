class ReconcilesController < ApiController
  respond_to :json
  before_filter :ensure_user!

  def create
    environment = Environment.lookup(params[:environment])
    app = App.lookup(params[:app]) if params[:app]

    # ensure similar reconciles and deploys aren't currently in progress
    unless params[:force] == 'true'
      pending_reconciles = Reconcile.where(state: 'in_progress', environment: environment)
      # if reconciling one app, we should only care about global reconciles and reconciles of this app
      pending_reconciles = pending_reconciles.where('app_id IS NULL OR app_id = ?', app) if app

      if pending_reconciles.length > 0
        msg = "Reconcile ID #{pending_reconciles.ids.to_sentence} already in progress in this environment."
        msg += ' Either wait for completion, or call again with force.'
        error!(present_error(:resource_locked, msg), 423)
        return
      end

      pending_deploys = Deploy.in_progress_for(environment)
      pending_deploys = pending_deploys.where(app: app) if app

      if pending_deploys.length > 0
        msg = "Deploy ID #{pending_deploys.ids.to_sentence} already in progress in this environment."
        msg += " Either wait for completion, or call again with 'force' parameter set."
        error!(present_error(:resource_locked, msg), 423)
        return
      end
    end

    reconcile = Reconcile.create!(environment: environment, app: app, callback_url: params[:callback_url])
    reconcile.run_in_container!

    render json: represent(reconcile, with: ReconcileRepresenter), status: 202
  end

  def show
    reconcile = Reconcile.find(params[:id])
    represent_and_render reconcile, with: ReconcileRepresenter
  end

  def logs
    reconcile = Reconcile.find(params[:id])
    raise ActiveRecord::RecordNotFound unless reconcile.container_id
    render json: { logs: reconcile.docker_logs }
  end

  def index
    reconciles = Reconcile.where({})
    represent_and_render reconciles, with: ReconcileRepresenter
  end

  def preview
    environment = Environment.lookup(params[:environment])
    app = App.lookup(params[:app]) if params[:app]

    reconcile = Reconcile.new(environment: environment, app: app)
    represent_and_render reconcile, with: ReconcileRepresenter
  end
end
