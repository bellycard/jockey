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

FactoryGirl.define do
  factory :app do
    sequence(:name) { |n| "app_name#{n}" }
    sequence(:repo) { |n| "#{n}/repo#{n}" }
    association :stack
    subscribe_to_github_webhook false
  end
end
