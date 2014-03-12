require 'spec_helper'

describe Consul::Instance do
  describe 'register!' do
    it 'calls Consul to register an instance of a service with ttl check' do
      expected_url = 'http://127.0.0.1:8500/v1/agent/service/register'
      expected_request = { 'ID' => 'abcdef', 'Name' => 'foo-web', 'Port' => 12345, 'Tags' => [], 'Check' => { 'TTL' => '60s' } }.to_json
      response = Hashie::Mash.new('status' => 200)

      expect(Faraday).to receive(:put).with(expected_url, expected_request, 'Content-Type' => 'application/json').and_return(response)

      dc = 'datacenter'
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', dc)
      service = Consul::Service.new('foo-web', dc)
      check = Consul::Check::Ttl.new(60)
      instance = Consul::Instance.new('abcdef', node, service, 12345, [], check)
      instance.register!
    end

    it 'calls Consul to register an instance of a service with script check' do
      expected_url = 'http://127.0.0.1:8500/v1/agent/service/register'
      expected_request = {
        'ID' => 'abcdef',
        'Name' => 'foo-web',
        'Port' => 12345,
        'Tags' => [],
        'Check' => { 'Script' => 'check_http.rb', 'Interval' => '60s' }
      }.to_json
      response = Hashie::Mash.new('status' => 200)

      expect(Faraday).to receive(:put).with(expected_url, expected_request, 'Content-Type' => 'application/json').and_return(response)

      dc = 'datacenter'
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', dc)
      service = Consul::Service.new('foo-web', dc)
      check = Consul::Check::Script.new('check_http.rb', 60)
      instance = Consul::Instance.new('abcdef', node, service, 12345, [], check)
      instance.register!
    end

    it 'raises an exception if an unsupported check is provided' do
      dc = 'datacenter'
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', dc)
      service = Consul::Service.new('foo-web', dc)
      check = double(:check, :is_a? => false)
      instance = Consul::Instance.new('abcdef', node, service, 12345, [], check)

      expect { instance.register! }.to raise_error
    end
  end

  describe 'deregister!' do
    it 'calls Consul to deregister an instance of a service' do
      expected_url = 'http://127.0.0.1:8500/v1/agent/service/deregister/abcdef'
      response = Hashie::Mash.new('status' => 200)

      expect(Faraday).to receive(:put).with(expected_url, 'Content-Type' => 'application/json').and_return(response)

      dc = 'datacenter'
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', dc)
      service = Consul::Service.new('foo-web', dc)
      instance = Consul::Instance.new('abcdef', node, service)
      instance.deregister!
    end
  end

  describe 'healthy?' do
    it 'returns true if this instance is healthy' do
      dc = 'datacenter'
      expected_url = "http://consul.example.com:8500/v1/health/checks/foo-web?dc=#{dc}"
      response = Hashie::Mash.new(body: [
        { 'Node' => 'ip-127-0-0-1.local', 'ServiceID' => 'abcdef', 'Status' => 'passing' },
        { 'Node' => 'ip-127-0-0-1.local', 'ServiceID' => 'bcdefg', 'Status' => 'critical' }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', dc)
      service = Consul::Service.new('foo-web', dc)
      instance = Consul::Instance.new('abcdef', node, service, nil, nil, nil)

      expect(instance.healthy?).to be(true)
    end

    it 'returns false if a service is unhealthy' do
      dc = 'datacenter'
      expected_url = "http://consul.example.com:8500/v1/health/checks/foo-web?dc=#{dc}"
      response = Hashie::Mash.new(body: [
        { 'Node' => 'ip-127-0-0-1.local', 'ServiceID' => 'abcdef', 'Status' => 'critical' },
        { 'Node' => 'ip-127-0-0-1.local', 'ServiceID' => 'bcdefg', 'Status' => 'critical' }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', dc)
      service = Consul::Service.new('foo-web', dc)
      instance = Consul::Instance.new('abcdef', node, service, nil, nil, nil)

      expect(instance.healthy?).to be(false)
    end
  end

  describe '.find' do
    it 'calls Consul properly and returns the expected object' do
      dc = 'datacenter'
      expected_url = "http://consul.example.com:8500/v1/catalog/node/ip-127-0-0-1.local?dc=#{dc}"
      response = Hashie::Mash.new(body: { 'Services' => { 'abcdef' => {} } }.to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', dc)
      instance = Consul::Instance.find('abcdef', node)

      expect(instance.id).to eq('abcdef')
    end

    it 'raises an error if not found' do
      dc = 'datacenter'
      expected_url = "http://consul.example.com:8500/v1/catalog/node/ip-127-0-0-1.local?dc=#{dc}"
      response = Hashie::Mash.new(body: { 'Services' => { 'abcdef' => {} } }.to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', dc)
      expect { Consul::Instance.find('bcdefg', node) }.to raise_error Consul::RecordNotFound
    end
  end

  describe '.all' do
    it 'calls Consul properly and returns an array of instances' do
      node1 = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1')
      node2 = Consul::Node.new('ip-127-0-0-2.local', '127.0.0.2')
      service = Consul::Service.new('foo-web')
      expect(Consul::Node).to receive(:all).and_return([node1, node2])
      instance1 = Consul::Instance.new('abcdef', node1, service)
      instance2 = Consul::Instance.new('bcdefg', node2, service)
      expect(node1).to receive(:instances).and_return([instance1])
      expect(node2).to receive(:instances).and_return([instance2])

      all_instances = Consul::Instance.all
      expect(all_instances).to be_a(Array)
      expect(all_instances.map { |instance| instance.id }).to include('abcdef')
      expect(all_instances.map { |instance| instance.id }).to include('bcdefg')
    end
  end
end
