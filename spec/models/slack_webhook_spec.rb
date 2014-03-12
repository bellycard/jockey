# == Schema Information
#
# Table name: webhooks
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  body       :string(255)
#  app_id     :integer
#  type       :string(255)
#  system     :boolean
#  room       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe SlackWebhook do

  describe '#post' do
    it 'posts' do
      allow(Slack::Notifier).to receive(:ping)
      webhook = FactoryGirl.create(:slack_webhook, type: 'SlackWebhook', room: 'BAR')
      expect_any_instance_of(Slack::Notifier).to receive(:ping) do |c, message, opts|
        expect(opts[:attachments].first[:color]).to eq(nil)
        expect(opts[:attachments].first[:text]).to eq('foo')
      end
      webhook.post(from_name: 'test', message: 'foo')
    end

    it 'sets defaults correctly' do
      allow(Slack::Notifier).to receive(:ping)
      webhook = FactoryGirl.create(:slack_webhook, type: 'SlackWebhook', room: 'BAR')
      expect_any_instance_of(Slack::Notifier).to receive(:ping) do |c, message, opts|
        expect(opts[:attachments].first[:color]).to eq('#ff0000')
        expect(opts[:attachments].first[:text]).to eq('foo')
      end
      webhook.post(message: 'foo', color: '#ff0000')
    end
  end
end
