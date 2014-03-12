FactoryGirl.define do
  factory :slack_webhook do
    url 'http://localhost.com'
    body nil
    app nil
    system false
    type 'SlackWebhook'
  end
end
