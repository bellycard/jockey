require 'spec_helper'

describe ConfigSetsController, type: :controller do
  before do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    @request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApiController).to receive(:current_user).and_return(User.create)
  end

  describe 'POST /config_sets' do
    before do
      @app = FactoryGirl.create(:app,
                                name: 'config_set_test_app',
                                repo: 'bellycard/test',
                                subscribe_to_github_webhook: false)
      @env = Environment.create!(name: 'config_set_test_env')
      @config = { foo: 'bar' }
    end

    it 'creates an config_set object' do
      post :create, config: @config, app: @app.name, environment: @env.name
      expect(ConfigSet.count).to eq(1)
      expect(parsed_response.data.app.name).to eq(@app.name)
      expect(parsed_response.data.environment.name).to eq(@env.name)
      expect(parsed_response.data.config.foo).to eq('bar')
    end

    it 'errors if passing in an unknown app' do
      post :create, config: @config, app: 'not_a_real_app', environment: @env.name
      expect(response_code).to eq(404)
    end

    it 'errors if passing in an unknown environment' do
      post :create, config: @config, app: @app.name, environment: 'not_a_real_env'
      expect(response_code).to eq(404)
    end
  end

  describe 'PUT /config_sets' do
    before do
      @app = FactoryGirl.create(:app,
                                name: 'config_set_test_app2',
                                repo: 'bellycard/test',
                                subscribe_to_github_webhook: false)
      @env = Environment.create!(name: 'config_set_test_env')
      @config = { foo: 'bar' }
      @config_set = ConfigSet.create!(config: @config, app: @app, environment: @env)
    end

    it 'updates an config_set object' do
      put :update, id: @config_set.id, config: { foo: 'anything_but_bar' }, app: @app.name, environment: @env.name
      expect(ConfigSet.count).to eq(1)
      expect(parsed_response.data.app.name).to eq(@app.name)
      expect(parsed_response.data.environment.name).to eq(@env.name)
      expect(parsed_response.data.config.foo).to eq('anything_but_bar')
    end

    it 'updates an config_set object with a new key' do
      put :update, id: @config_set.id, config: { bar: 'anything_but_bar' }, app: @app.name, environment: @env.name
      expect(ConfigSet.count).to eq(1)
      expect(parsed_response.data.app.name).to eq(@app.name)
      expect(parsed_response.data.environment.name).to eq(@env.name)
      expect(parsed_response.data.config.foo).to eq('bar')
      expect(parsed_response.data.config.bar).to eq('anything_but_bar')
    end

    it 'does not delete an undefined key' do
      put :update, id: @config_set.id, config: @config, app: @app.name, environment: @env.name
    end

  end

  describe 'GET /config_sets/:id' do
    before do
      @app = FactoryGirl.create(:app,
                                name: 'config_set_test_app2',
                                repo: 'bellycard/test',
                                subscribe_to_github_webhook: false)
      @env = Environment.create!(name: 'config_set_test_env')
      @config = { foo: 'bar' }
      @config_set = ConfigSet.create!(config: @config, app: @app, environment: @env)
    end

    it 'gets by id' do
      get :show, id: @config_set.id
      expect(parsed_response.data.id).to eq(@config_set.id.to_s)
      expect(parsed_response.data.config.foo).to eq('bar')
    end
  end

  describe 'GET /config_sets' do
    it 'returns an array of config_sets' do
      get :index
      expect(parsed_response.data).to be_a(Array)
    end

    it 'filters on app_name' do
      app_two = FactoryGirl.create(:app,
                                   name: 'foobar',
                                   repo: 'bellycard/test',
                                   subscribe_to_github_webhook: false)
      FactoryGirl.create(:config_set, app: app_two)

      get :index, app: 'foobar'
      expect(parsed_response.data.size).to eq(1)
    end

    it 'returns an array of config_sets' do
      env_two = Environment.create!(name: 'foobar')
      FactoryGirl.create(:config_set, environment: env_two)
      get :index, environment: 'foobar'
      expect(parsed_response.data.size).to eq(1)
    end

  end
end
