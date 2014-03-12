class WorkerRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property :id, type: String
  property :name
  property :command
  property :scale
end
