# == Schema Information
#
# Table name: environments
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#  deleted_at :datetime
#

FactoryGirl.define do
  factory :environment do
    name 'some_environment'
  end
end
