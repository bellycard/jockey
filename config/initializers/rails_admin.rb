RailsAdmin.config do |config|

  config.authenticate_with

  config.authorize_with do
    redirect_to '/auth/github' unless User.find_by_id(session[:user_id])
  end

  config.current_user_method(&:current_user)
  config.compact_show_view = false

  ## == PaperTrail ==
  # User below should be your 'whodunnit' model.
  config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    delete
    export
    show
    edit

    ## With an audit adapter, you can add:
    history_index
    history_show
  end
end
