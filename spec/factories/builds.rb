# == Schema Information
#
# Table name: builds
#
#  id             :integer          not null, primary key
#  app_id         :integer          not null
#  ref            :string(255)      not null
#  status         :integer
#  callback_url   :string(255)
#  completed_at   :datetime
#  created_at     :datetime
#  updated_at     :datetime
#  rref           :string(255)
#  failure_reason :string(255)
#

require "digest/sha2"

FactoryGirl.define do
  factory :build do
    association :app
    ref 'something'
    rref { Digest::SHA256.hexdigest(Time.now.to_f.to_s) }
    state 'completed'
  end
end
