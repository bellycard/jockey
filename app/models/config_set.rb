class ConfigSet < ActiveRecord::Base
  belongs_to :app
  belongs_to :environment
  serialize :config
  validate :unique_environment_and_app
  validates_presence_of :config
  has_paper_trail
  after_commit :restart_all_workers
  after_commit :call_webhooks

  rails_admin do
    field :config, :json
    include_all_fields
  end

  def config_array
    env_arrary = []
    config.each do |k, v|
      env_arrary << "#{k}=#{v}"
    end
    env_arrary
  end

  def config_command_line_args
    config_string = ''
    config.each do |k, v|
      config_string << " -e #{k}=\"#{v}\""
    end
    config_string
  end

  def restart_all_workers
    # https://github.com/bellycard/jockey/issues/288
  end

  def workers
    Worker.where(app: app, environment: environment)
  end

  private

  def unique_environment_and_app
    errors.add(:base, 'environment and app not unique') if ConfigSet.where(app: app, environment: environment)
                                                                    .where.not(id: id).count > 0
  end

  def call_webhooks
    Webhook.post_for_app(app,  message: webhook_message, color: '#00ffff')
  end

  def webhook_message
    changer = originator ? User.find(originator).name : 'Jockey'
    "ConfigSet for #{app.name}:#{environment.name} changed by #{changer}"
  end
end
