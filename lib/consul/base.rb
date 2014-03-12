module Consul
  class Base
    def self.consul_url
      CONSUL_URL
    end

    def consul_url
      self.class.consul_url
    end
  end
end
