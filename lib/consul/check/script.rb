module Consul
  # A Check is a health check in Consul. These can be applied to nodes and services.
  # Only one check per service is supported. This will be changing in 0.5.0 - https://github.com/hashicorp/consul/pull/591
  # A service check can only be added when creating the instance of the service. This also changes in 0.5.0.
  # There is currently no way to get a check's attributes from the Consul API - https://github.com/hashicorp/consul/issues/623
  # For all of the reasons above, this class is only scaffolding for service checks.
  module Check
    # A Script Check runs a given `script` by filename every `interval` seconds, passing or failing based on exit code
    # http://www.consul.io/docs/agent/http.html#agent_check_register
    class Script < Base
      attr_accessor :script, :interval

      def initialize(script, interval)
        @script = script
        @interval = interval
        raise ArgumentError, 'interval must be a number' unless interval.is_a?(Numeric)
      end
    end
  end
end
