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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :webhook do
    url 'http://localhost.com'
    body nil
    app nil
    system false
  end
end
