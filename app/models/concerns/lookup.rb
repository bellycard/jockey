module Lookup
  extend ActiveSupport::Concern
  # add a method that allows looking up by name or id

  included do
    def self.lookup(reference)
      obj = find_by_name(reference)
      obj ||= find_by_id(reference)
      raise ActiveRecord::RecordNotFound unless obj
      obj
    end
  end
end
