class User < ActiveRecord::Base
  acts_as_paranoid
  def self.from_omniauth(auth)
    # ensure the that auth'd user has access to bellycard
    github_client = Octokit::Client.new(access_token: auth['credentials']['token'])
    from_github_client(github_client)
  end

  def self.from_github_access_token(token)
    github_client = Octokit::Client.new(access_token: token)
    from_github_client(github_client)
  end

  def self.from_github_client(github_client)
    raise "#{github_client.user.login} is not a member of the required github team" unless github_client.team_member?(
      ENV['GITHUB_TEAM_ID'], github_client.user.login
    )
    user_data = github_client.user
    find_or_create_by(provider: 'github', uid: user_data.id) do |user|
      user.name = user_data.name
    end
  end
end
