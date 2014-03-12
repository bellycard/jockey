class Webhook < ActiveRecord::Base
  belongs_to :app
  serialize :body

  def self.post_for_app(app, options = {})
    # post a webhook to all registered for this app && for all registered for everything
    webhooks = Webhook.where(app: app) | where(system: true)
    webhooks.uniq.each do |webhook|
      begin
        # call the webhook type's post method
        webhook.post(options)
      rescue => e
        logger.warn("Webhook #{webhook.id} failed: #{e.message}")
      end
    end
  end

  def post(options = {})
    options = options.merge(body) if body
    # I'm a generic URL webhook.  Post with a http client
    response = Faraday.post(url, options)
    logger.info("Callback to #{url} returned status #{response.status}")
  rescue => e
    logger.warn("Callback to #{url} failed: #{e.message}")
  end
end
