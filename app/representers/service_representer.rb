class ServiceRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property 'id', as: :id
end
