class AddGithubWebhookToApps < ActiveRecord::Migration
  def change
    add_column :apps, :subscribe_to_github_webhook, :boolean, default: true
    add_column :apps, :github_webhook_secret, :string
  end
end
