module Consul
  # The Kv object is used to interface with Consul's Key / Value store
  class Kv < Base
    attr_reader :id, :value

    def initialize(id, value, dc = '')
      @dc = dc
      @id = id
      @value = value
    end

    def save!
      response = Faraday.put("#{consul_url}/v1/kv/#{@id}?dc=#{@dc}", value)
      raise 'Failed to save to k/v store' unless response.body == 'true'
    end

    def delete!
      response = Faraday.delete("#{consul_url}/v1/kv/#{@id}?dc=#{@dc}")
      raise 'Failed to delete from k/v store' unless response.status == 200
    end

    def self.find(id, dc = '')
      response = Faraday.get("#{consul_url}/v1/kv/#{id}?dc=#{dc}")
      raise Consul::RecordNotFound unless response.status == 200

      kv = JSON.parse(response.body)
      new(kv.first['Key'], Base64.decode64(kv.first['Value']))
    end

    def self.search_by_prefix(prefix, dc = '')
      response = Faraday.get("#{consul_url}/v1/kv/#{prefix}?dc=#{dc}&recurse")
      raise Consul::RecordNotFound unless response.status == 200

      kv = JSON.parse(response.body)
      kv.map { |item| new(item['Key'], Base64.decode64(item['Value'])) }
    end

    def self.all(dc = '')
      response = Faraday.get("#{consul_url}/v1/kv/?dc=#{dc}&recurse")
      raise Consul::RecordNotFound unless response.status == 200

      kv = JSON.parse(response.body)
      kv.map { |item| new(item['Key'], Base64.decode64(item['Value'])) }
    end
  end
end
