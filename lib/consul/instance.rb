module Consul
  # An Instance is an instance of a service in Consul
  # In some places in the Consul documentation, this is called a Node,
  # as it assumes a Service will only have one instance per node
  class Instance < Base
    attr_reader :id, :node, :service, :port, :tags, :check

    def initialize(id, node, service, port = nil, tags = [], check = nil)
      @id = id
      @node = node
      @service = service
      @port = port
      @tags = tags
      @check = check
      @dc = node.dc
    end

    def register!
      response = Faraday.put(
        "#{node.agent_url}/service/register",
        register_hash.to_json,
        'Content-Type' => 'application/json'
      )
      raise "failed to register instance: #{response.body}" unless response.status == 200
    end

    def deregister!
      response = Faraday.put(
        "#{node.agent_url}/service/deregister/#{id}",
        'Content-Type' => 'application/json'
      )
      raise "failed to deregister instance: #{response.body}" unless response.status == 200
    end

    def healthy?
      response = Faraday.get("#{consul_url}/v1/health/checks/#{@service.id}?dc=#{@dc}")
      checks = JSON.parse(response.body)

      return false if checks.find { |check|
        check['Node'] == @node.id &&
        check['ServiceID'] == @id &&
        check['Status'] != 'passing'
      }
      true
    end

    def self.find(id, node)
      # Ensure that this instance id exists on the node
      response = Faraday.get("#{consul_url}/v1/catalog/node/#{node.id}?dc=#{node.dc}")
      instances = JSON.parse(response.body)['Services']
      raise Consul::RecordNotFound unless instances[id]

      # We cannot get a check's attributes back from the API, so omit it - https://github.com/hashicorp/consul/issues/623
      # We might be able to fake it by duplicating data to the KV store
      new(id, node, Consul::Service.new(instances[id]['Service']), instances[id]['Port'], instances[id]['Tags'])
    end

    def self.all
      instances = []
      Consul::Node.all.each do |node|
        instances.concat(node.instances)
      end

      instances
    end

    private

    # The register endpoint has a complex definition for an Instance
    def register_hash
      i_hash = {
        'ID' => @id,
        'Name' => @service.id,
        'Port' => @port,
        'Tags' => @tags
      }

      if @check.is_a?(Consul::Check::Ttl)
        i_hash['Check'] = { 'TTL' => "#{@check.ttl}s" }
      elsif @check.is_a?(Consul::Check::Script)
        i_hash['Check'] = { 'Script' => @check.script, 'Interval' => "#{@check.interval}s" }
      elsif @check
        raise "Unknown Check type: #{@check.inspect}"
      end

      i_hash
    end
  end
end
