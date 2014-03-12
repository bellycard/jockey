require 'spec_helper'

describe Consul::Check::Ttl do
  describe '#initialize' do
    it 'raises error if no interval is passed' do
      expect { Consul::Check::Ttl.new() }.to raise_error
    end

    it 'raises error if ttl is not a number' do
      expect { Consul::Check::Ttl.new('60') }.to raise_error
    end

    it 'raises no error if given a valid ttl' do
      expect { Consul::Check::Ttl.new(60) }.to_not raise_error
    end
  end
end
