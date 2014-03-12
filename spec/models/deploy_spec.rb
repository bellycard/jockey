require 'spec_helper'

describe Deploy do

  def fake_node_two
    Hashie::Mash.new(
       'Node' => 'second_node',
       'Address' => '192.168.59.103',
       'ServiceID' => 'consul-8400',
       'ServiceName' => 'consul-8400',
       'ServiceTags' => %w(master v1),
       'ServicePort' => 8400

    )
  end

  def fake_services_on_node
    Hashie::Mash.new(
       'Node' => {
         'Services' => {
           '3905d42e1d85d1cad8d321cbdbeff6e152e785e7acd7723801b834c55b168908' => {
             'ID' => '3905d42e1d85d1cad8d321cbdbeff6e152e785e7acd7723801b834c55b168908',
             'Service' => 'business-service-foo',
             'Tags' => [
               'tag:', 'repo:',
               "command:[\"/bin/sh\", \"-c\", \"/start web\"]",
               'environment:development'
             ],
             'Port' => 49155
           },
           '58d1ed1ca4d907b5caf66b9575e5f45152672ece352d18cd9dc348d12555e949' => {
             'ID' => '58d1ed1ca4d907b5caf66b9575e5f45152672ece352d18cd9dc348d12555e949',
             'Service' => 'business-service-foo',
             'Tags' => [
               'tag:', 'repo:',
               "command:[\"/bin/sh\", \"-c\", \"/start web\"]",
               'environment:development'
             ],
             'Port' => 49157
           },
           'consul' => {
             'ID' => 'consul',
             'Service' => 'consul',
             'Tags' => nil,
             'Port' => 8300
           },
           'consul-8400' => {
             'ID' => 'consul-8400',
             'Service' => 'consul-8400',
             'Tags' => %w(master v1),
             'Port' => 8400
           }
         }
       }

    )
  end

  let(:rref) { SecureRandom.hex }
  let(:environment) { FactoryGirl.create(:environment) }
  let(:app) { FactoryGirl.create(:app) }
  let(:worker) { FactoryGirl.create(:worker, app: app, environment: environment, scale: 3)}
  let(:build) { FactoryGirl.create(:build, app: app, ref: '123abc') }
  let(:deploy) { Deploy.new(app: app, environment: environment, build: build)}

  describe "#run!" do
    before do
      allow(deploy).to receive(:wait_for_boot)
      allow(deploy).to receive(:update_github_tag)
      allow(deploy).to receive(:stop_containers)
      allow(Consul::Node).to receive(:find).and_return(fake_node)
      allow_any_instance_of(NodeSelection).to receive(:next_available_nodes).and_return([fake_node, fake_node, fake_node])
      allow_any_instance_of(Git).to receive(:object).with('123abc').and_return(rref)
    end

    it "spawns a container for each worker" do
      expect(deploy).to receive(:create_container_for_worker).with(worker.id, String).at_least(3).times
      deploy.run!
    end
  end

  describe 'deploy' do
    before do
      @app = FactoryGirl.create(:app)
      @environment = FactoryGirl.create(:environment)
      @worker = FactoryGirl.create(:worker, app: @app, environment: @environment, scale: 1)
      @deploy = FactoryGirl.create(:deploy, app: @app, environment: @environment)
    end

    xit 'starts a container', :vcr, match_requests_on: [:method] do
      allow(Consul::Node).to receive(:find).and_return(fake_node)
      allow_any_instance_of(NodeSelection).to receive(:next_available_nodes).and_return([fake_node])
      allow_any_instance_of(DeployVerificationWorker).to receive(:perform)
      allow_any_instance_of(GithubTagWorker).to receive(:perform)
      expect(Container).to receive(:start_worker)
    end

    it 'can set a GitHub tag based on environment' do
      allow(Consul::Node).to receive(:find).and_return(fake_node)
      allow_any_instance_of(NodeSelection).to receive(:next_available_nodes).and_return([fake_node])
      expect_any_instance_of(Octokit::Client).to receive(:update_ref).
                                                  with(@deploy.app.repo, "tags/#{@deploy.environment.name}", @deploy.build.rref, false).
                                                  and_return(true) # TODO: realistic hash-y response
      @deploy.update_github_tag
    end

    xit 'updates a GitHub tag during the deploy process asynchronously' do
      allow(Consul::Node).to receive(:find).and_return(fake_node)
      allow_any_instance_of(NodeSelection).to receive(:next_available_nodes).and_return([fake_node])
      expect(GithubTagWorker).to receive(:perform_async).with(@deploy.id, false).and_return(true)
      @deploy.deploy!
    end
  end

  describe "setting the reference" do
    it "sets the build with the specified rref" do
      app = FactoryGirl.create(:app)
      build = FactoryGirl.create(:build, app: app, rref: "9999999")

      deploy = Deploy.new(app: app)
      deploy.rref = build.rref
      expect(deploy.build.id).to eq(build.id)
    end

    it "sets the build with the most recent rref" do
      app = FactoryGirl.create(:app)
      build1 = FactoryGirl.create(:build, app: app, rref: "9999999")
      build2 = FactoryGirl.create(:build, app: app, rref: "9999999", created_at: 1.day.from_now)

      deploy = Deploy.new(app: app)
      deploy.rref = build1.rref
      expect(deploy.build.id).to eq(build2.id)
    end

    context "when the build rref cannot be found" do
      it "creates a new build for the rref" do
        builds_double = double("app.builds", latest_for_rref: nil)
        app_double = double(App, builds: builds_double)
        deploy = Deploy.new
        allow(deploy).to receive(:app).and_return(app_double)

        expect(builds_double).to receive(:build).with(ref: "123")

        deploy.rref = "123"
      end
    end
  end

  describe "setting the environment name" do
    it "sets the environment with the matching environment name" do
      environment = FactoryGirl.create(:environment, name: "ryans-env")

      deploy = Deploy.new
      deploy.environment = Environment.lookup("ryans-env")
      expect(deploy.environment.id).to eq(environment.id)
    end
  end
end
