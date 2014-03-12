class SlackWebhook < Webhook
  attr_accessor :from_name
  def post(options = {})
    client = Slack::Notifier.new url
    options = options.merge(body) if body

    channel = room || '#notifications'
    username = options[:from_name] || 'jockey'
    color = options[:color]
    client.ping '', attachments: [{ color: color, text: options[:message], fallback: options[:message] }],
                    channel: channel,
                    icon_emoji: ':horse:',
                    username: username
  end
end
