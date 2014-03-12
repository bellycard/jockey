class ReconcileRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property :id, type: String
  property :environment, extend: EnvironmentRepresenter
  property :app, extend: AppRepresenter
  property :state
  property :callback_url
  property :plan
  property :created_at
  property :updated_at
  property :completed_at
  property :container_id
  property :container_host
end
