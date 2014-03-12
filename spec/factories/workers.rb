# == Schema Information
#
# Table name: workers
#
#  id             :integer          not null, primary key
#  scale          :integer
#  command        :string(255)
#  app_id         :integer
#  environment_id :integer
#  created_at     :datetime
#  updated_at     :datetime
#  name           :string(255)
#

FactoryGirl.define do
  factory :worker do
    scale 1
    command 'MyString'
    association :app
    association :environment
    sequence(:name) { |n| "name-#{n}" }
    before(:create) { |obj|
      FactoryGirl.create(:config_set, app: obj.app, environment: obj.environment) unless obj.config_set
    }
  end
end
