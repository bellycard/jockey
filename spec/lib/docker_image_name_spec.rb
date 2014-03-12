require 'spec_helper'

describe DockerImageName do
  describe '.image_parts' do
    it 'works with a tagged remote image' do
      parts = DockerImageName.image_parts('aws-east1-docker-registry01.bellycard.com:4046/campaign-service:7d790648e')
      expect(parts[:repo]).to eq('aws-east1-docker-registry01.bellycard.com:4046')
      expect(parts[:name]).to eq('campaign-service')
      expect(parts[:tag]).to eq('7d790648e')
    end
  end
end
