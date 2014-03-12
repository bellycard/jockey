class AppRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property :id, type: String
  property :name
  property :repo
  property :subscribe_to_github_webhook
end
