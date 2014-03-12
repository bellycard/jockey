class Environment < ActiveRecord::Base
  include Lookup
  acts_as_paranoid

  has_many :config_sets
  has_many :deploys
  has_many :reconciles

  validates_presence_of :name
end
