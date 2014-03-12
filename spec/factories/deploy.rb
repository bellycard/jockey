# == Schema Information
#
# Table name: configured_builds
#
#  id         :integer          not null, primary key
#  build_id   :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  state      :string(255)
#  worker_id  :integer
#

FactoryGirl.define do
  factory :deploy do
    association :build
    association :environment
    association :app

    before(:create) do |obj|
      cs = ConfigSet.find_or_initialize_by(app: obj.app, environment: obj.environment)
      cs.config ||= {}
      cs.save
    end
  end
end
