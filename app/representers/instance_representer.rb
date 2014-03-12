class InstanceRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property :id
  property :node, extend: NodeRepresenter
  property :service, extend: ServiceRepresenter
  property :port
  collection :tags
  property :check, extend: CheckRepresenter
end
