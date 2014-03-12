class BuildRepresenter < Napa::Representer
  property :id, type: String
  property :app, extend: AppRepresenter
  property :ref
  property :rref
  property :state
  property :created_at
  property :completed_at
  property :container_host
  property :container_id
end
