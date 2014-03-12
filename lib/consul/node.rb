module Consul
  # A Node is a Host running a Consul Agent
  class Node < Base
    attr_reader :dc, :id, :address

    def initialize(id, address, dc = '')
      @dc = dc
      @id = id
      @address = address
    end

    def services
      response = Faraday.get("#{consul_url}/v1/catalog/node/#{@id}?dc=#{@dc}")
      service_names = JSON.parse(response.body)['Services'].map { |_id, instance| instance['Service'] }.uniq

      # call Consul::Service.new instead of find, as the existance here proves the service exists
      service_names.map { |name| Consul::Service.new(name) }
    end

    def instances
      response = Faraday.get("#{consul_url}/v1/catalog/node/#{@id}?dc=#{@dc}")
      JSON.parse(response.body)['Services'].map { |id, instance|
        Consul::Instance.new(
          id, self, Consul::Service.new(instance['Service']), instance['Port']
        )
      }
    end

    def agent_url
      "http://#{address}:8500/v1/agent"
    end

    def self.find(id, dc = '')
      response = Faraday.get("#{consul_url}/v1/catalog/node/#{id}?dc=#{dc}")

      # This endpoint returns the body "null" if node not found
      raise Consul::RecordNotFound if response.body == 'null'

      node = JSON.parse(response.body)
      new(node['Node']['Node'], node['Node']['Address'], node['Node']['Datacenter'])
    end

    def self.find_by_address(address, dc = '')
      response = Faraday.get("#{consul_url}/v1/catalog/nodes?dc=#{dc}")
      node = JSON.parse(response.body).find { |n| n['Address'] == address }
      raise Consul::RecordNotFound unless node
      new(node['Node'], node['Address'], node['Datacenter'])
    end

    def self.all(dc = '')
      response = Faraday.get("#{consul_url}/v1/catalog/nodes?dc=#{dc}")
      JSON.parse(response.body).map { |node| new(node['Node'], node['Address'], node['Datacenter']) }
    end
  end
end
