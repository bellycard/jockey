HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

module GithubSignature
  def self.verify(app_id, body, sig)
    secret = App.find(app_id).github_webhook_secret
    calculated_sig = OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, body)

    sig == "sha1=#{calculated_sig}"
  end
end
