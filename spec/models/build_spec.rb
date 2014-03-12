require 'spec_helper'

describe Build do
  let(:app) { FactoryGirl.create(:app) }
  let(:environment) { FactoryGirl.create(:environment) }
  let(:build) { FactoryGirl.create(:build, app: app) }

  it 'sets an initial state' do
    Build.create.state.should eq('in_progress')
  end

  # TODO: Move these specs to the Deploy model. They are testing Deploy predicate methods.
  describe "updating active deploys" do
    # TODO
    xit "updates the state of deploys when the build starts" do
      build = FactoryGirl.create(:build)
      deploy = FactoryGirl.create(:deploy, app: build.app, build: build)

      build.update_attributes(state: 'in_progress')
      expect(Deploy.find(deploy.id)).to be_building
    end

    # TODO
    xit "updates the state of deploys when the build fails" do
      build = FactoryGirl.create(:build, state: "in_progress")
      deploy = FactoryGirl.create(:deploy, app: build.app, build: build)

      build.update_attributes(state: :failed)
      expect(Deploy.find(deploy.id)).to be_failed
    end

    # TODO
    xit "updates the state of deploys when the build completes" do
      build = FactoryGirl.create(:build, state: "in_progress")
      deploy = FactoryGirl.create(:deploy, app: build.app, build: build, state: "building")

      build.update_attributes(state: :completed)
      expect(Deploy.find(deploy.id)).to be_deploying
    end

    it "does not update deploys at rest" do
      build = FactoryGirl.create(:build, state: "in_progress")
      deploy = FactoryGirl.create(:deploy, app: build.app, build: build, state: "stopped")

      build.update_attributes(state: :failed)
      expect(Deploy.find(deploy.id)).not_to be_failed
    end
  end

  describe "#repo" do
    let(:git_stub) { double(Git) }

    subject { build.repo }

    before do
      allow(Git).to receive(:clone).and_return(git_stub)
    end

    it "clones the repo" do
      expect(Git).to receive(:clone).with(/https:\/\/.*@github\.com\/#{build.app.repo}.git/, app.name, path: build.dir)
      build.repo
    end

    it "memoizes the repo" do
      build.repo
      expect(Git).not_to receive(:clone)
      build.repo
    end
  end

  describe "#run!" do
    let(:git_repo) {
      repo = Git::Repository.new('foo', false)
      allow(repo).to receive(:object).and_return(Hashie::Mash.new(sha: 'abs123'))
      allow(repo).to receive(:checkout)
      repo
    }

    let(:image) { double(Docker::Image).as_null_object }

    let(:build) { create(:build) }

    before do
      allow(build).to receive(:mod_git_time).and_return nil
      allow(Git).to receive(:clone).and_return(git_repo)
      allow_any_instance_of(NodeSelection).to receive(:next_available_nodes).and_return([fake_node])
      allow(FileUtils).to receive(:cp)
      allow(File).to receive(:exist?).and_return(true)
      allow(Docker::Image).to receive(:build_from_dir).and_return(image)
    end

    it 'sets the rref to the sha of the git ref supplied' do
      allow(build).to receive(:update)
      expect(build).to receive(:update).with(rref: 'abs123').at_least(:once).and_return(build)
      build.run!
    end

    it 'works correctly' do
      expect(image).to receive(:push).twice
      expect(image).to receive(:tag).twice

      expect(build).to receive(:save).exactly(3).times
      build.run!
    end

    # TODO
    xit 'sets the state of the build to failed when it cannot build' do
      expect(File).to receive(:exist?).and_return(false)
      build.run!
      expect(build.reload.state).to eq('failed')
      expect(build.reload.failure_reason).to include('No such file or directory')
    end

    xit 'fails when it would be duplicating an in progress build' do
      build # instantiate the build record now

      # create a build in progress that matches the stubbed out data for this build
      create(:build, rref: 'abs123', app: build.app, state: :in_progress)

      build.run!
      expect(build.reload.state).to eq('failed')
      expect(build.reload.failure_reason).to include('already building this SHA')
    end

    describe 'calling the associated callback' do
      it 'posts to the callback url of the app' do
        create(:webhook, app: build.app, url: 'https://foo.bar.com')
        expect(Faraday).to receive(:post) { |url, attributes|
          expect(url).to eq('https://foo.bar.com')
          expect(attributes[:message]).to include(build.app.name)
        }.and_return(Hashie::Mash.new(state: 'fake'))

        build.run!
      end

      it 'posts to the callback of the build' do
        build = create(:build, callback_url: 'https://foo.bar.com/')

        expect_any_instance_of(Faraday::Connection).to receive(:post) { |req|
          expect(req.url_prefix.to_s).to eq('https://foo.bar.com/')
        }.and_return(Hashie::Mash.new(status: 'fake'))

        build.run!
      end
    end
  end
end
