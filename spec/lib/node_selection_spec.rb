require 'spec_helper'

describe NodeSelection do
  describe '#next_available_nodes' do
    it 'returns an array of nodes ordered by service_count' do
      node1 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-1.local', 'address' => '127.0.0.1' })
      node2 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-2.local', 'address' => '127.0.0.2' })
      node3 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-3.local', 'address' => '127.0.0.3' })
      expected_nodes = { node1 => 1, node2 => 2, node3 => 30 }

      ns = NodeSelection.new
      expect(ns).to receive(:nodes_with_service_count).and_return(expected_nodes)
      expect(ns.next_available_nodes(4)).to eq([node1, node2, node1, node1])
    end

    it 'raises an error when no node available' do
      ns = NodeSelection.new
      expect(ns).to receive(:nodes_with_service_count).and_return({ })
      expect { ns.next_available_nodes }.to raise_error
    end
  end

  describe '#nodes_with_least_running_containers' do
    it 'returns sorted hashmap of node=>service_count' do
      node1 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-1.local', 'address' => '127.0.0.1' })
      node2 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-2.local', 'address' => '127.0.0.2' })
      node3 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-3.local', 'address' => '127.0.0.3' })
      expected_nodes = { node1 => 10, node2 => 2, node3 => 30 }

      ns = NodeSelection.new
      expect(ns).to receive(:nodes_with_service_count).and_return(expected_nodes)
      nodes = ns.nodes_with_least_running_containers

      expect(nodes.length).to be(3)
      expect(nodes.map { |node, count| count }).to eq([2, 10, 30])
      expect(nodes.map { |node, count| count }).not_to eq([10, 2, 30])
    end
  end

  describe '#nodes_with_service_count' do
    it 'returns hashmap of node=>service_count' do
      node1 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-1.local', 'address' => '127.0.0.1', 'instances' => { 'count' => 1 } })
      node2 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-2.local', 'address' => '127.0.0.2', 'instances' => { 'count' => 2 } })

      ns = NodeSelection.new
      expect(ns).to receive(:available_nodes).and_return([node1, node2])
      nodes = ns.nodes_with_service_count

      expect(nodes.length).to be(2)
      expect(nodes.map { |node, count| node.address }).to include('127.0.0.1')
    end
  end

  describe '#available_nodes' do
    it 'queries Consul for nodes to deploy to' do
      worker = Hashie::Mash.new({ 'name' => 'web', 'app' => { 'stack' => { 'name' => 'api' } }, 'environment' => { 'name' => 'testing' } })
      expected_service = Consul::Service.new(worker.consul_service_name)
      node1 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-1.local', 'address' => '127.0.0.1', 'instances' => { 'count' => 1 } })
      node2 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-2.local', 'address' => '127.0.0.2', 'instances' => { 'count' => 2 } })

      expect(Consul::Service).to receive(:find).with('jockey-api-testing').and_return(expected_service)
      expect(expected_service).to receive(:nodes).and_return([node1, node2])

      nodes = NodeSelection.new(worker: worker).available_nodes

      expect(nodes.length).to be(2)
      expect(nodes.map { |node| node.address }).to include('127.0.0.1')
    end
  end

  describe '#nodes_running_service' do
    it 'returns an array of nodes running a service' do
      worker = Hashie::Mash.new({ 'consul_service_name' => 'foo-web' })
      expected_service = Consul::Service.new('foo-web')
      node1 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-1.local', 'address' => '127.0.0.1' })
      node2 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-2.local', 'address' => '127.0.0.2' })

      expect(Consul::Service).to receive(:find).with('foo-web').and_return(expected_service)
      expect(expected_service).to receive(:nodes).and_return([node1, node2])

      nodes = NodeSelection.new(worker: worker).nodes_running_service
      expect(nodes.length).to be(2)
      expect(nodes.map { |node| node.address }).to include('127.0.0.1')
    end

    it 'returns [] if no nodes are running a service' do
      worker = Hashie::Mash.new({ 'consul_service_name' => 'foo-web' })
      expect(Consul::Service).to receive(:find).with('foo-web').and_raise(Consul::RecordNotFound)

      nodes = NodeSelection.new(worker: worker).nodes_running_service
      expect(nodes).to eq([])
    end
  end

  describe '#node_running_service?' do
    it 'returns true if specified node is running a service' do
      ns = NodeSelection.new
      node1 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-1.local', 'address' => '127.0.0.1' })
      node2 = Hashie::Mash.new({ 'id' => 'ip-127-0-0-2.local', 'address' => '127.0.0.2' })
      this_node = Hashie::Mash.new({ 'id' => 'ip-127-0-0-1.local', 'address' => '127.0.0.1' })

      expect(ns).to receive(:nodes_running_service).and_return([node1, node2])
      expect(ns.node_running_service?(this_node)).to be(true)
    end

    it 'returns false if specified node is not running a service' do
      ns = NodeSelection.new
      this_node = Hashie::Mash.new({ 'id' => 'ip-127-0-0-1.local', 'address' => '127.0.0.1' })

      expect(ns).to receive(:nodes_running_service).and_return([])
      expect(ns.node_running_service?(this_node)).to be(false)
    end
  end
end
