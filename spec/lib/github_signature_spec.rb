require 'spec_helper'
include GithubSignature

describe GithubSignature do
  describe '.verify' do
    before do
      @app = FactoryGirl.create(:app,
                                name: 'rose',
                                repo: 'foo/bar',
                                subscribe_to_github_webhook: false,
                                github_webhook_secret: 'secret')
    end

    it 'returns true on valid signature' do
      test_body = '{}'
      expected_sig = 'sha1=5d61605c3feea9799210ddcb71307d4ba264225f'
      expect(GithubSignature.verify(@app.id, test_body, expected_sig)).to eq(true)
    end

    it 'returns false on invalid signature' do
      test_body = '{}'
      expected_sig = 'sha1=0000000000000000000000000000000000000000'
      expect(GithubSignature.verify(@app.id, test_body, expected_sig)).to eq(false)
    end
  end
end
