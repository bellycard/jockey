class DeployedWorkerRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property :id, type: String
  property :name
  collection :instances, extend: InstanceRepresenter
end
