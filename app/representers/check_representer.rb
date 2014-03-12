class CheckRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property 'ttl', as: :ttl
  property 'script', as: :script
  property 'interval', as: :interval
end
