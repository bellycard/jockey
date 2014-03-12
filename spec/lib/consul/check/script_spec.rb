require 'spec_helper'

describe Consul::Check::Script do
  it 'raises error unless a script name and interval are passed' do
    expect { Consul::Check::Script.new() }.to raise_error
  end

  it 'raises error if interval is not numeric' do
    expect { Consul::Check::Script.new('check.rb', '60') }.to raise_error
  end

  it 'raises no error if given a valid script and interval' do
    expect { Consul::Check::Script.new('script.sh', 60) }.to_not raise_error
  end
end
