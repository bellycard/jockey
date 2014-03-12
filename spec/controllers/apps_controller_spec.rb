require 'rails_helper'

RSpec.describe AppsController, type: :controller do
  before do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    @request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApiController).to receive(:current_user).and_return(User.create)
  end

  describe 'POST /apps' do
    it 'creates an app object' do
      FactoryGirl.create(:stack, name: 'api')
      post :create, name: 'Test App', repo: 'bellycard/test', subscribe_to_github_webhook: false
      expect(App.count).to eq(1)
      expect(App.first.name).to eq('Test App')
      expect(App.first.repo).to eq('bellycard/test')
      expect(App.first.subscribe_to_github_webhook).to eq(false)
    end
  end

  describe 'GET /apps/:id' do
    before do
      @app = FactoryGirl.create(:app, name: 'rose', repo: 'foo/bar', subscribe_to_github_webhook: false)
    end

    it 'gets by id' do
      get :show, id: @app.id
      expect(parsed_response.data.name).to eq('rose')
    end

    it 'gets by name' do
      get :show, id: @app.name
      expect(parsed_response.data.name).to eq('rose')
    end
  end

  describe 'GET /apps' do
    it 'returns an array of apps' do
      get :index
      expect(parsed_response.data).to be_a(Array)
    end
  end
end
