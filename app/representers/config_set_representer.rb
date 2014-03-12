class ConfigSetRepresenter < Napa::Representer
  property :id, type: String
  property :config, type: String
  property :config_command_line_args
  property :app, extend: AppRepresenter
  property :environment, extend: EnvironmentRepresenter
end
