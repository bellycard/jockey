require 'render_anywhere'
class NodeSelection
  attr_accessor :worker
  def initialize(worker: nil)
    self.worker = worker
  end

  def next_available_nodes(node_count = 1)
    # when deploying or rescaling, use this to determine where the next containers should go
    nodes = []
    candidate_nodes = nodes_with_service_count
    node_count.times do |node_number|
      begin
        if node_number == 1 && candidate_nodes.count > 1
          # this is the second instance of this worker
          # always put it on a different node than the first
          different_nodes = candidate_nodes.select { |node, _count| node.address != nodes.first.address }
          next_node = different_nodes.sort_by { |_node, count| count }.first.first
        else
          next_node = candidate_nodes.sort_by { |_node, count| count }.first.first
        end
      rescue
        raise 'cannot find a node'
      end

      raise 'cannot find a node' unless next_node

      # increment local copy of nodes_with_service_count so we make better decisions on next iterations
      candidate_nodes[next_node] += 1
      nodes << next_node
    end
    nodes
  end

  def nodes_with_least_running_containers
    # query all of the nodes running docker
    # return an array of the nodes where the count of running containers is the lowest
    nodes_with_service_count.sort_by { |_node, count| count }
  end

  # Return { node => count, node => count }
  def nodes_with_service_count
    Hash[available_nodes.map { |node| [node, node.instances.count] }]
  end

  def available_nodes
    # look for all nodes that we have registered as a certain type.
    # see types here https://github.com/bellycard/infrastructure/tree/master/components/coreos
    service_name = "jockey-#{worker.app.stack.name}-#{worker.environment.name}"
    begin
      @available_nodes ||= Consul::Service.find(service_name).nodes
    rescue Consul::RecordNotFound
      []
    end
  end

  def nodes_running_service
    # use our value if we've defined it.
    # We override the consul value so that we consider a node as "running a service" before the service is registered
    return @nodes_running_service if @nodes_running_service
    begin
      Consul::Service.find(worker.consul_service_name).nodes
    rescue Consul::RecordNotFound
      []
    end
  end

  def node_running_service?(node)
    nodes_running_service.map { |n| n.address }.include?(node.address)
  end

  def self.docker_connection_for_node(node)
    docker_port = ENV['DOCKER_CERT_PATH'] ? '2376' : '2375'
    Docker::Connection.new("tcp://#{node.address}:#{docker_port}", Docker.env_options.merge(read_timeout: 600, write_timeout: 600))
  end
end
