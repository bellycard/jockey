class NodeRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property 'id', as: :id
  property 'address', as: :address
end
