require 'spec_helper'

describe Consul::Node do
  describe '#services' do
    it 'calls Consul to get services running on a node' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/node/ip-127-0-0-1.local?dc=datacenter'
      response = Hashie::Mash.new(body: { 'Services' => {
        'abcdef' => { 'Service' => 'foo-web' },
        '012345' => { 'Service' => 'bar-web' }
      } }.to_json)

      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', 'datacenter')
      services = node.services

      expect(services.map { |service| service.id }).to include('foo-web')
      expect(services.count).to be(2)
    end
  end

  describe '#instances' do
    it 'calls Consul to get instances of services running on a node' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/node/ip-127-0-0-1.local?dc=datacenter'
      response = Hashie::Mash.new(body: { 'Services' => {
        'abcdef' => { 'Service' => 'foo-web', 'Port' => 12345 },
        '012345' => { 'Service' => 'bar-web', 'Port' => 23456 }
      } }.to_json)

      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', 'datacenter')
      instances = node.instances

      expect(instances.map { |instance| instance.id }).to include('abcdef')
      expect(instances.map { |instance| instance.port }).to include(12345)
      expect(instances.count).to be(2)
    end
  end

  describe '#agent_url' do
    it 'returns the agent url for the Node' do
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', 'datacenter')

      expect(node.agent_url).to eq('http://127.0.0.1:8500/v1/agent')
    end
  end

  describe '.find' do
    it 'calls Consul properly and returns the expected object' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/node/ip-127-0-0-1.local?dc=datacenter'
      response = Hashie::Mash.new(body: { 'Node' => { 'Node' => 'ip-127-0-0-1.local', 'Address' => '127.0.0.1' } }.to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      node = Consul::Node.find('ip-127-0-0-1.local', 'datacenter')

      expect(node.id).to eq('ip-127-0-0-1.local')
      expect(node.address).to eq('127.0.0.1')
    end

    it 'raises an error if not found' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/node/ip-127-0-0-1.local?dc=datacenter'
      response = Hashie::Mash.new(body: 'null')
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      expect { Consul::Node.find('ip-127-0-0-1.local', 'datacenter') }.to raise_error Consul::RecordNotFound
    end
  end

  describe '.find_by_address' do
    it 'calls Consul properly and returns the expected object' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/nodes?dc=datacenter'
      response = Hashie::Mash.new(body: [
        { 'Node' => 'ip-127-0-0-1.local', 'Address' => '127.0.0.1', 'Datacenter' => 'datacenter' },
        { 'Node' => 'ip-127-0-0-2.local', 'Address' => '127.0.0.2', 'Datacenter' => 'datacenter' }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      node = Consul::Node.find_by_address('127.0.0.1', 'datacenter')

      expect(node.id).to eq('ip-127-0-0-1.local')
      expect(node.address).to eq('127.0.0.1')
    end

    it 'raises an error if not found' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/nodes?dc=datacenter'
      response = Hashie::Mash.new(body: [].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      expect { Consul::Node.find_by_address('127.0.0.1', 'datacenter') }.to raise_error Consul::RecordNotFound
    end
  end

  describe '.all' do
    it 'calls Consul properly and returns an array of nodes' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/nodes?dc=datacenter'
      response = Hashie::Mash.new(body: [
        { 'Node' => 'ip-127-0-0-1.local', 'Address' => '127.0.0.1', 'Datacenter' => 'datacenter' },
        { 'Node' => 'ip-127-0-0-2.local', 'Address' => '127.0.0.2', 'Datacenter' => 'datacenter' }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)
      nodes = Consul::Node.all('datacenter')

      expect(nodes.map { |node| node.id }).to include('ip-127-0-0-1.local')
      expect(nodes.map { |node| node.address }).to include('127.0.0.1')
      expect(nodes.map { |node| node.dc }).to include('datacenter')
      expect(nodes.count).to be(2)
    end

    it 'calls Consul properly and returns an empty array of nodes when there are none' do
      expected_url = 'http://consul.example.com:8500/v1/catalog/nodes?dc=datacenter'
      response = Hashie::Mash.new(body: [].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      expect(Consul::Node.all('datacenter').count).to be(0)
    end
  end

  describe '.initialize' do
    it 'can set a DC' do
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1', 'datacenter')
      expect(node.dc).to eq 'datacenter'
    end
    it 'sets a default DC of empty string' do
      node = Consul::Node.new('ip-127-0-0-1.local', '127.0.0.1')
      expect(node.dc).to eq ''
    end
  end
end
