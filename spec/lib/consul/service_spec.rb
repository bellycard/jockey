require 'spec_helper'

describe Consul::Service do
  describe '#instances' do
    it 'calls Consul to get instances of a service' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/service/foo-web?dc=datacenter'
      response = Hashie::Mash.new(body: [
        { 'Node' => 'ip-127-0-0-1.local', 'Address' => '127.0.0.1', 'ServiceName' => 'foo-web', 'ServiceID' => 'abcdef', 'ServicePort' => 12345 },
        { 'Node' => 'ip-127-0-0-1.local', 'Address' => '127.0.0.1', 'ServiceName' => 'foo-web', 'ServiceID' => '123456', 'ServicePort' => 23456 }
      ].to_json)

      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      service = Consul::Service.new('foo-web', 'datacenter')
      instances = service.instances

      expect(instances.map { |instance| instance.id }).to include('abcdef')
      expect(instances.map { |instance| instance.port }).to include(12345)
      expect(instances.count).to be(2)
    end
  end

  describe '#nodes' do
    it 'gets uniq nodes from the service\'s instances' do
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1')
      service = Consul::Service.new('foo-web')
      instance1 = Consul::Instance.new('abcdef', node, service)
      instance2 = Consul::Instance.new('123456', node, service)

      expect(service).to receive(:instances).and_return([instance1, instance2])

      nodes = service.nodes
      expect(nodes.length).to be(1)
      expect(nodes.map { |n| n.address }).to include('127.0.0.1')
    end
  end

  describe 'healthy?' do
    it 'returns true if a service is healthy' do
      expected_url = 'http://consul.example.com:8500/v1/health/checks/foo-web?dc=datacenter'
      response = Hashie::Mash.new(body: [
        { 'Status' => 'passing' },
        { 'Status' => 'passing' }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      service = Consul::Service.new('foo-web', 'datacenter')
      expect(service.healthy?).to be(true)
    end

    it 'returns false if a service is unhealthy' do
      expected_url = 'http://consul.example.com:8500/v1/health/checks/foo-web?dc=datacenter'
      response = Hashie::Mash.new(body: [
        { 'Status' => 'passing' },
        { 'Status' => 'critical' }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      service = Consul::Service.new('foo-web', 'datacenter')
      expect(service.healthy?).to be(false)
    end
  end

  describe '.find' do
    it 'calls Consul properly and returns the expected object' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/service/foo-web?dc=datacenter'
      response = Hashie::Mash.new(body: [ { 'ServiceName' => 'foo-web' } ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      service = Consul::Service.find('foo-web', 'datacenter')

      expect(service.id).to eq('foo-web')
    end

    it 'raises an error if not found' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/service/foo-web?dc=datacenter'
      response = Hashie::Mash.new(body: [ ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      expect { Consul::Service.find('foo-web', 'datacenter') }.to raise_error Consul::RecordNotFound
    end
  end

  describe '.all' do
    it 'calls Consul properly and returns an array of services' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/services?dc=datacenter'
      response = Hashie::Mash.new(body: {
        'foo-web' => [ ],
        'bar-rabbit' => [ ]
      }.to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      services = Consul::Service.all('datacenter')

      expect(services.map { |service| service.id }).to include('foo-web')
      expect(services.count).to be(2)
    end

    it 'calls Consul properly and returns an empty array of service when there are none' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/services?dc=datacenter'
      response = Hashie::Mash.new(body: { }.to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      expect(Consul::Service.all('datacenter').count).to be(0)
    end
  end

  describe '.initialize' do
    it 'can set a DC' do
      svc = Consul::Service.new('foo-web', 'datacenter')
      expect(svc.instance_variable_get(:@dc)).to eq 'datacenter'
    end
    it 'sets a default DC of empty string' do
      svc = Consul::Service.new('foo-web')
      expect(svc.instance_variable_get(:@dc)).to eq ''
    end
  end
end
