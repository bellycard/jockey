class DeployRepresenter < Napa::Representer
  property :id, type: String
  property :state
  property :build, extend: BuildRepresenter
  property :environment, extend: EnvironmentRepresenter
  property :app, extend: AppRepresenter
  collection :instances, as: :instances, if: -> (opts) { opts[:include_instances] }
  property :created_at
  property :updated_at
  property :container_id
  property :container_host
  property :completed_at
  property :failure_reason
end
