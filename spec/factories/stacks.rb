# == Schema Information
#
# Table name: stacks
#
#  id   :integer          not null, primary key
#  name :string(255)
#

FactoryGirl.define do
  factory :stack do
    sequence(:name) { |n| "app_stack#{n}" }
  end
end
