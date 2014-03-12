class App < ActiveRecord::Base
  include Lookup
  include RailsAdminGenericRender
  acts_as_paranoid

  belongs_to :stack
  has_many :builds
  has_many :config_sets
  has_many :workers
  has_many :deploys

  validates_format_of :repo, with: /\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\z/
  validates_uniqueness_of :name, :repo
  validates_presence_of :stack, :name, :repo

  def generate_github_webhook_secret
    self.github_webhook_secret ||= SecureRandom.hex
  end

  def create_github_webhook
    # Determine URL for webhook
    url = "#{ ENV['URL'] }/github_webhooks/#{id}"

    # Create Webhook
    client = Octokit::Client.new(access_token: ENV['GITHUB_OAUTH_TOKEN'])
    client.create_hook(
      repo,
      'web',
      { url: url, content_type: 'json', secret: github_webhook_secret },
      events: ['push'], active: true
    )
  end

  def current_deploy(environment)
    deploys.where(environment: environment, state: 'deployed').order(created_at: :desc).first
  end

  after_commit :create_app_with_defaults, on: :create
  before_validation :set_defaults

  rails_admin do
    configure :render_kibana do
      visible false # so it's not on new/edit
    end

    edit do
      field :name
      field :repo
      field :stack
      field :subscribe_to_github_webhook
    end

    show do
      include_all_fields
      field :render_kibana do
        label 'Kibana'
      end
    end
  end

  private

  def set_defaults
    self.stack ||= Stack.find_by_name(:api)
  end

  def create_app_with_defaults
    # hook it up to github
    if subscribe_to_github_webhook
      generate_github_webhook_secret
      create_github_webhook
      save!
    end

    # create config_sets for production, development
    default_environments = [:production, :development]
    environments = Environment.where(name: default_environments)
    environments.each do |environment|
      config_sets.create(environment: environment,
                         config: { 'id' => environment.name,
                                   'RACK_ENV' => environment.name
                                 }
                        )
      # setup a web worker at scale of ZERO so that we don't deploy something before configuring it
      workers.create(environment: environment, scale: 0, command: '/start web', name: 'web')
    end
  end
end
