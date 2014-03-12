require 'spec_helper'

describe WorkersController, type: :controller do
  before do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    @request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApiController).to receive(:current_user).and_return(User.create)
  end

  describe 'GET /workers/:id' do
    before do
      @worker = FactoryGirl.create(:worker)
    end

    it 'gets by id' do
      get :show, id: @worker.id
      expect(parsed_response.data.id).to eq(@worker.id.to_s)
      expect(parsed_response.data.name).to eq(@worker.name)
    end
  end

  describe 'GET /workers' do
    before do
      @worker = FactoryGirl.create(:worker)
    end

    it 'returns an array of workers' do
      get :index
      expect(parsed_response.data).to be_a(Array)
    end

    it 'filters on app_name' do
      app_two = FactoryGirl.create(:app, name: 'foobar', repo: 'bellycard/test', subscribe_to_github_webhook: false)
      FactoryGirl.create(:worker, app: app_two)

      get :index, app: 'foobar'
      expect(parsed_response.data.size).to eq(1)
    end

    it 'filters on worker name' do
      FactoryGirl.create(:worker, name: 'second_worker')

      get :index, worker: 'second_worker'
      expect(parsed_response.data.size).to eq(1)
    end
  end

  describe 'PUT /workers/:id' do
    it 'sets the scale and name correctly' do
      worker = FactoryGirl.create(:worker)
      put :update, id: worker.id, name: 'foo', scale: 6
      worker.reload
      expect(worker.scale).to eq(6)
      expect(worker.name).to eq('foo')
    end
  end

  describe 'GET /workers/:id/deploys' do
    before do
      @worker = FactoryGirl.create(:worker)
    end

    it 'gets deployed works from Consul' do
      service = Consul::Service.new('foo-web')
      instance = Hashie::Mash.new(
        'id' => 'e9157098933e9dafaff01be7a2772fe29a9b211ffcedb5647b2d32b96eed0666',
        'node' => {
          'id' => 'ip-127-0-0-1.local',
          'address' => '127.0.0.1'
        },
        'service' => { 'id' => 'foo-web' },
        'port' => 50000,
        'tags' => [
          'tag:43938385488c9d9d278639bc9817c60d677bbeba',
          'rref:43938385488c9d9d278639bc9817c60d677bbeba',
          'repo:registry.example.com',
          'command:["/start", "web"]'
        ]
      )

      allow(Consul::Service).to receive(:find).and_return(service)
      allow(service).to receive(:instances).and_return([instance])

      get :deploys, id: @worker.id
      expect(parsed_response.data.instances.size).to eq(1)
      expect(parsed_response.data.id).to eq(@worker.id.to_s)
      expect(parsed_response.data.name).to eq(@worker.consul_service_name)
      expect(parsed_response.data.instances.first.node.address).to eq('127.0.0.1')
      expect(parsed_response.data.instances.first.service.id).to eq('foo-web')
      expect(parsed_response.data.instances.first.port).to eq(50000)
      expect(parsed_response.data.instances.first.tags).to include('tag:43938385488c9d9d278639bc9817c60d677bbeba')
      expect(parsed_response.data.instances.first.tags).to include('rref:43938385488c9d9d278639bc9817c60d677bbeba')
      expect(parsed_response.data.instances.first.tags).to include('repo:registry.example.com')
      expect(parsed_response.data.instances.first.tags).to include('command:["/start", "web"]')
    end
  end

  describe 'PUT /workers/:id/restart' do
    before do
      @worker = FactoryGirl.create(:worker)
      @fake_instance_1 = fake_instance
      @fake_instance_2 = fake_instance
      allow(Container).to receive(:restart)
      allow_any_instance_of(Worker).to receive(:instances).and_return([@fake_instance_1, @fake_instance_2])
      allow(@fake_instance_1).to receive(:healthy?).and_return(true)
      allow(@fake_instance_2).to receive(:healthy?).and_return(false)
    end

    it 'returns a 404 if the worker is not found' do
      put :restart_member, id: @worker.id + 1
      expect(response_code).to be 404
    end

    it 'returns a 200 if the restarts are successful' do
      put :restart_member, id: @worker.id
      expect(response_code).to be 200
    end

    it 'restarts all of the containers' do
      put :restart_member, id: @worker.id
      expect(Container).to have_received(:restart).twice
    end

    it 'restarts only healthy containers' do
      put :restart_member, id: @worker.id, healthy: 'true'
      expect(Container).to have_received(:restart).once
    end

    it 'restarts only failing containers' do
      put :restart_member, id: @worker.id, healthy: 'false'
      expect(Container).to have_received(:restart).once
    end
  end

  describe 'PUT /workers/restart' do
    before do
      @environment_1 = FactoryGirl.create(:environment, name: 'foo')
      @environment_2 = FactoryGirl.create(:environment, name: 'bar')
      @worker_1 = FactoryGirl.create(:worker, environment: @environment_1, name: 'web')
      @worker_2 = FactoryGirl.create(:worker, app: @worker_1.app, environment: @environment_1, name: 'rabbit')
      @worker_3 = FactoryGirl.create(:worker, environment: @environment_2, name: 'sidekiq')
      @fake_instance_1 = fake_instance
      @fake_instance_2 = fake_instance
      allow(Container).to receive(:restart)
      allow_any_instance_of(Worker).to receive(:instances).and_return([@fake_instance_1, @fake_instance_2])
      allow(@fake_instance_1).to receive(:healthy?).and_return(true)
      allow(@fake_instance_2).to receive(:healthy?).and_return(false)
    end

    it 'returns a 404 if the worker is not found' do
      put :restart_collection, app: 'feawfew', environment: 'baz', name: 'blah'
      expect(response_code).to be 404
    end

    it 'returns a 400 if the required params are not sent' do
      put :restart_collection, app: @worker_1.app.name
      expect(response_code).to be 400
    end

    it 'returns a 200 if the restarts are successful' do
      put :restart_collection, app: @worker_1.app.name, environment: @environment_1.name
      expect(response_code).to be 200
    end

    it 'restarts containers for an app & environment, filtered by name' do
      put :restart_collection, app: @worker_1.app.name, environment: @environment_1.name, worker: 'rabbit'
      expect(Container).to have_received(:restart).twice
    end

    it 'restarts all of the containers for an app & environment' do
      put :restart_collection, app: @worker_1.app.name, environment: @environment_1.name
      expect(Container).to have_received(:restart).exactly(4).times
    end

    it 'restarts only failing containers for an app & environment' do
      put :restart_collection, app: @worker_1.app.name, environment: @environment_1.name, healthy: 'true'
      expect(Container).to have_received(:restart).twice
    end

    it 'restarts only healthy containers for an app & environment' do
      put :restart_collection, app: @worker_1.app.name, environment: @environment_1.name, healthy: 'false'
      expect(Container).to have_received(:restart).twice
    end
  end

  describe 'PUT /workers/rescale' do
    before do
      @worker = FactoryGirl.create(:worker, scale: 1)
    end

    it 'returns an error if the required params are not sent' do
      params = { app: 'sample', environment: 'production', name: 'rabbit', scale: 5 }
      params.each do |key, val|
        params_except_one = params.except(key)
        put :rescale, params_except_one
        expect(parsed_response.error).to_not be_nil
      end
    end

    it 'returns a 404 if the worker is not found' do
      put :rescale, app: @worker.app, environment: @worker.environment, name: 'foobarbaz', scale: 5
      expect(response_code).to eq 404
    end

    it 'returns a 422 if the scale param is invalid' do
      put :rescale, app: @worker.app, environment: @worker.environment, name: @worker.name, scale: 'foobarbaz'
      expect(response_code).to eq 422
    end

    it 'rescales the worker to the specified scale' do
      put :rescale, app: @worker.app, environment: @worker.environment, name: @worker.name, scale: 5
      expect(parsed_response.data.scale).to eq 5
    end
  end
end
