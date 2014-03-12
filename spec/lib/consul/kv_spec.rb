require 'spec_helper'

describe Consul::Kv do
  describe 'save!' do
    it 'calls Consul to save a k/v pair' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc=datacenter'
      expected_value = 'bar'
      response = Hashie::Mash.new('body' => 'true')

      expect(Faraday).to receive(:put).with(expected_url, expected_value).and_return(response)

      kv = Consul::Kv.new('foo', 'bar', 'datacenter')
      kv.save!
    end

    it 'supports default datacenter' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc='
      expected_value = 'bar'
      response = Hashie::Mash.new('body' => 'true')

      expect(Faraday).to receive(:put).with(expected_url, expected_value).and_return(response)

      kv = Consul::Kv.new('foo', 'bar')
      kv.save!
    end
  end

  describe 'delete!' do
    it 'calls Consul to delete a key from the k/v store' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc=datacenter'
      response = Hashie::Mash.new('status' => 200)

      expect(Faraday).to receive(:delete).with(expected_url).and_return(response)

      kv = Consul::Kv.new('foo', 'bar', 'datacenter')
      kv.delete!
    end

    it 'supports default datacenter' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc='
      response = Hashie::Mash.new('status' => 200)

      expect(Faraday).to receive(:delete).with(expected_url).and_return(response)

      kv = Consul::Kv.new('foo', 'bar')
      kv.delete!
    end
  end

  describe '.find' do
    it 'calls Consul properly and returns the expected object' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc=datacenter'
      response = Hashie::Mash.new(status: 200, body: [ { 'Key' => 'foo', 'Value' => Base64.encode64('bar') } ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      kv = Consul::Kv.find('foo', 'datacenter')
      expect(kv.value).to eq('bar')
    end

    it 'raises an error if not found' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc=datacenter'
      response = Hashie::Mash.new(status: 404)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      expect { Consul::Kv.find('foo', 'datacenter') }.to raise_error Consul::RecordNotFound
    end

    it 'supports default datacenter' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc='
      response = Hashie::Mash.new(status: 200, body: [ { 'Key' => 'foo', 'Value' => Base64.encode64('bar') } ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      kv = Consul::Kv.find('foo')
      expect(kv.value).to eq('bar')
    end
  end

  describe '.search_by_prefix' do
    it 'calls Consul and returns an array of K/V pairs that begin with search term' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc=datacenter&recurse'
      response = Hashie::Mash.new(status: 200, body: [
        { 'Key' => 'food', 'Value' => Base64.encode64('bar') },
        { 'Key' => 'foo/fighter', 'Value' => Base64.encode64('freshpots') }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      search = Consul::Kv.search_by_prefix('foo', 'datacenter')
      expect(search.count).to eq(2)
      expect(search.map { |kv| kv.value }).to_not include('grohl')
    end

    it 'supports default datacenter' do
      expected_url = 'http://consul.example.com:8500/v1/kv/foo?dc=&recurse'
      response = Hashie::Mash.new(status: 200, body: [
        { 'Key' => 'food', 'Value' => Base64.encode64('bar') },
        { 'Key' => 'foo/fighter', 'Value' => Base64.encode64('freshpots') }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      search = Consul::Kv.search_by_prefix('foo')
      expect(search.count).to eq(2)
      expect(search.map { |kv| kv.value }).to_not include('grohl')
    end
  end

  describe '.all' do
    it 'calls Consul and returns an array of K/V pairs' do
      expected_url = 'http://consul.example.com:8500/v1/kv/?dc=datacenter&recurse'
      response = Hashie::Mash.new(status: 200, body: [
        { 'Key' => 'foo', 'Value' => Base64.encode64('bar') },
        { 'Key' => 'foo/fighter', 'Value' => Base64.encode64('freshpots') }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      expect(Consul::Kv.all('datacenter').map { |kv| kv.value }).to include('freshpots')
    end

    it 'supports default datacenter' do
      expected_url = 'http://consul.example.com:8500/v1/kv/?dc=&recurse'
      response = Hashie::Mash.new(status: 200, body: [
        { 'Key' => 'foo', 'Value' => Base64.encode64('bar') },
        { 'Key' => 'foo/fighter', 'Value' => Base64.encode64('freshpots') }
      ].to_json)
      expect(Faraday).to receive(:get).with(expected_url).and_return(response)

      expect(Consul::Kv.all.map { |kv| kv.value }).to include('freshpots')
    end
  end

  describe '.initialize' do
    it 'can set a DC' do
      kv = Consul::Kv.new('set', 'forget', 'datacenter')
      expect(kv.instance_variable_get(:@dc)).to eq 'datacenter'
    end

    it 'sets a default DC of empty string' do
      kv = Consul::Kv.new('foo', 'bar')
      expect(kv.instance_variable_get(:@dc)).to eq ''
    end
  end
end
