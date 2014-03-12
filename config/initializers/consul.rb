# if we have a docker0 address, use it.  Otherwise, use the ENV variable
# this is useful while we're calling this code inside and outside of our docker boxes.

if ENV.fetch('CONSUL_SERVER_URL')
  CONSUL_URL = ENV['CONSUL_SERVER_URL']
else
  docker_zero_address = `route -n | grep 'UG[ \t]' | awk '{print $2}'`.strip
  CONSUL_URL = docker_zero_address.start_with?('172.') ? "http://#{docker_zero_address}:8500" : ENV['CONSUL_SERVER_URL']
end
