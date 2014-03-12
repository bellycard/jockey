module DockerLoggable
  extend ActiveSupport::Concern

  included do
    def docker_logs
      Container.logs(container_host, container_id)
    end
  end
end
