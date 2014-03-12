module Consul
  # Services are never explicitly created in Consul; they exist once an instance of a service has been registered
  class Service < Base
    attr_reader :id

    def initialize(id, dc = '')
      @dc = dc
      @id = id
    end

    def instances
      response = Faraday.get("#{consul_url}/v1/catalog/service/#{@id}?dc=#{@dc}")
      JSON.parse(response.body).map { |instance|
        Consul::Instance.new(
          instance['ServiceID'],
          Consul::Node.new(instance['Node'], instance['Address'], instance['Datacenter']),
          Consul::Service.new(instance['ServiceName']),
          instance['ServicePort'],
          instance['ServiceTags']
        )
      }
    end

    def nodes
      instances.map { |instance| instance.node }.uniq { |node| node.id }
    end

    def healthy?
      response = Faraday.get("#{consul_url}/v1/health/checks/#{@id}?dc=#{@dc}")
      checks = JSON.parse(response.body)

      return false if checks.find { |check| check['Status'] != 'passing' }
      true
    end

    def self.find(id, dc = '')
      response = Faraday.get("#{consul_url}/v1/catalog/service/#{id}?dc=#{dc}")
      raise Consul::RecordNotFound if JSON.parse(response.body).empty?
      new(id)
    end

    def self.all(dc = '')
      response = Faraday.get("#{consul_url}/v1/catalog/services?dc=#{dc}")
      service_names = JSON.parse(response.body).map { |id, _tags| id }.uniq
      service_names.map { |name| Consul::Service.new(name) }
    end
  end
end
