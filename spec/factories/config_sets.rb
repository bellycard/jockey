# == Schema Information
#
# Table name: config_sets
#
#  id             :integer          not null, primary key
#  config         :text(2147483647) not null
#  app_id         :integer          not null
#  environment_id :integer          not null
#  created_at     :datetime
#  updated_at     :datetime
#

FactoryGirl.define do
  factory :config_set do
    association :app
    association :environment
    config { { foo: :bar } }
  end
end
