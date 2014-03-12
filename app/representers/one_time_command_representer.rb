class OneTimeCommandRepresenter < Napa::Representer
  include Napa::Representable::IncludeNil
  property :id, type: String
  property :app, extend: AppRepresenter
  property :environment, extend: EnvironmentRepresenter
  property :command
  property :rref
  property :output
  property :callback_url
end
