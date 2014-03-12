# == Schema Information
#
# Table name: apps
#
#  id                          :integer          not null, primary key
#  name                        :string(255)      not null
#  repo                        :string(255)      not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  subscribe_to_github_webhook :boolean          default(TRUE)
#  github_webhook_secret       :string(255)
#  deleted_at                  :datetime
#  stack_id                    :integer
#

require 'spec_helper'

describe App do
  describe '#create' do
    it 'registers with github' do
      expect_any_instance_of(App).to receive(:create_github_webhook)
      FactoryGirl.create(:app, subscribe_to_github_webhook: true)
    end

    it 'creates a config set for production' do
      environment = FactoryGirl.create(:environment, name: 'production')
      app = FactoryGirl.create(:app)
      expect(app.config_sets.where(environment: environment).count).to eq(1)
    end

    it 'creates a config set for development' do
      environment = FactoryGirl.create(:environment, name: 'production')
      app = FactoryGirl.create(:app)
      expect(app.config_sets.where(environment: environment).count).to eq(1)
    end

    it 'creates a web worker for production' do
      environment = FactoryGirl.create(:environment, name: 'production')
      app = FactoryGirl.create(:app)
      expect(app.workers.where(environment: environment).count).to eq(1)
    end
  end
end
