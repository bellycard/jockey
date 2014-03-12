module Consul
  class RecordNotFound < Exception
  end
end

require 'consul/base'
require 'consul/node'
require 'consul/service'
require 'consul/instance'
require 'consul/check/script'
require 'consul/check/ttl'
