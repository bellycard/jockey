require 'docker'

class Container
  # Shortcut function for passing a worker rather than all parameters
  def self.start_worker(node, worker, rref, additional_tags = {})
    start(node, worker.app, worker.environment, worker.command, worker.name, rref, additional_tags)
  end

  def self.start(node, app, environment, command, worker_name, rref, additional_tags = {})
    begin
      # Pull Docker Image to Node
      Napa::Logger.logger.info("pulling image #{app.name}:#{rref} on #{node.address}")
      Docker::Image.create({ 'fromImage' => "#{ ENV['DOCKER_REGISTRY_URL'] }/#{ app.name }:#{rref}" },
                           nil,
                           NodeSelection.docker_connection_for_node(node))
    rescue => e
      # This can be called many times asynchronously, causing a situation where a second create would fail
      Napa::Logger.logger.warn("pulling image #{app.name}:#{rref} on #{node.address} failed: #{e.message}")
    end

    # Start Docker Container on Node
    unique_container_name = "#{app.name}.#{worker_name}.#{SecureRandom.uuid}"
    Napa::Logger.logger.info("deploying container #{unique_container_name} on #{node.address}")

    config_set = app.config_sets.where(environment: environment).first

    container = Docker::Container.create({
                                           'name' => unique_container_name,
                                           'Cmd' => command.split(' '),
                                           'Image' => "#{ ENV['DOCKER_REGISTRY_URL'] }/#{ app.name }:#{rref}",
                                           'Env' => config_set.config_array,
                                           'ExposedPorts' => { '8888/tcp' => {} } },
                                         NodeSelection.docker_connection_for_node(node)
                                        )
    container.start(
                     'PublishAllPorts' => true,
                     'RestartPolicy' => { 'Name' => 'always' }
                   )

    # Gather Container information
    container_info = Hashie::Mash.new(container.json)
    portmap = container_info['NetworkSettings'].try('Ports').try(:values).try(:first).try(:first)
    exposed_port = nil
    exposed_port = portmap['HostPort'].to_i if portmap
    image_name_hash = DockerImageName.image_parts(container_info['Config'].try('Image'))

    # Set up default tags
    tags = {
      'tag' => image_name_hash[:tag],
      'rref' => rref,
      'repo' => image_name_hash[:repo],
      'command' => container_info['Config'].try('Cmd')
    }

    # Add additional tags
    tags.merge!(additional_tags)

    # Convert tags into array for Consul
    tags_array = tags.map { |tag, value| "#{tag}:#{value}" }

    # Register Docker Container as Consul Instance
    service = Consul::Service.new("#{app.name}-#{worker_name}")
    check = Consul::Check::Ttl.new(60)
    instance = Consul::Instance.new(container.id, node, service, exposed_port, tags_array, check)
    instance.register!

    Napa::Logger.logger.info("deployed #{unique_container_name} on #{node.address}")

    # TODO: once things are stable, we likely don't need to flood slack with every stop/start
    Webhook.post_for_app(
      app,
      message: "#{app.name} container #{worker_name}:#{rref.first(10)} started on #{node.address}",
      color: '#00ff00',
      from_name: 'Jockey'
    )
    container
  end

  def self.restart(node, container_id)
    Napa::Logger.logger.info("restarting #{container_id} on #{node.address}")

    container = Docker::Container.get(
      container_id, {},
      NodeSelection.docker_connection_for_node(node)
    )
    container.restart
  rescue => e
    Napa::Logger.logger.error(e.message)
    Napa::Logger.logger.error(
      "Could not restart container #{container_id} on node: #{node.address}"
    )
    raise e
  end

  def self.stop(node, container_id)
    Napa::Logger.logger.info("stopping #{container_id} on #{node.address}")

    # Stop Docker Container
    container = Docker::Container.get(
      container_id, {},
      NodeSelection.docker_connection_for_node(node)
    )
    container.stop

    # Deregister Consul Instance
    Consul::Instance.find(container_id, node).deregister!
  rescue => e
    Napa::Logger.logger.error(e.message)
    Napa::Logger.logger.error(
      "Could not stop container #{container_id} on node: #{node.address}"
    )
    raise e
  end

  def self.background(command)
    # create temporary environemnt for the jockey app
    app = App.lookup('jockey')
    env = Environment.lookup(ENV['RAILS_ENV'])
    rref = 'latest' # TODO: use the currently deployed jockey rref?
    config = app.config_sets.where(environment: env).first
    worker = Worker.new(name: 'background', app: app, environment: env, command: command)
    node = NodeSelection.new(worker: worker).next_available_nodes.first

    # if ENV['DOCKER_CERT_PATH'] is set, mount it in the container
    volumes = {}
    binds = []
    if ENV['DOCKER_CERT_PATH'] && ENV['DOCKER_HOST_CERT_PATH']
      volumes[ENV['DOCKER_CERT_PATH']] = {}
      binds << "#{ENV['DOCKER_HOST_CERT_PATH']}:#{ENV['DOCKER_CERT_PATH']}:ro"
    end

    container = Docker::Container.create({
                                           'name' => "jockey.background.#{SecureRandom.uuid}",
                                           'Cmd' => command.split(' '),
                                           'Image' => "#{ ENV['DOCKER_REGISTRY_URL'] }/#{ app.name }:#{rref}",
                                           'Env' => config.config_array,
                                           'Volumes' => volumes
                                         }, NodeSelection.docker_connection_for_node(node))
    container.start('Binds' => binds)

    { 'host' => node.address, 'id' => container.id }
  end

  def self.raw_logs(container_host, container_id)
    node = Consul::Node.find_by_address(container_host)

    Docker::Container.get(
      container_id,
      {},
      NodeSelection.docker_connection_for_node(node)
    ).logs(
      stderr: true,
      stdout: true
    )
  end

  def self.logs(container_host, container_id)
    raw_logs(container_host, container_id)
      .lines
      .reject(&:blank?)
      .map { |l| l.gsub(/^[^{]+/, '') }
      .map do |l|
        begin
          JSON.parse(l)
        rescue JSON::JSONError
          l
        end
      end
  end
end
