require 'spec_helper'

describe EnvironmentsController, type: :controller do
  before do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    @request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApiController).to receive(:current_user).and_return(User.create)
  end

  describe 'POST /environments' do
    it 'creates an environment object' do
      post :create, name: 'test'
      expect(Environment.count).to eq(1)
      expect(Environment.first.name).to eq('test')
    end
  end

  describe 'GET /environments/:id' do
    before do
      @env = Environment.create!(name: 'foo')
    end

    it 'gets by id' do
      get :show, id: @env.id
      expect(parsed_response.data.name).to eq(@env.name)
    end

    it 'gets by name' do
      get :show, id: @env.name
      expect(parsed_response.data.name).to eq(@env.name)
    end
  end

  describe 'GET /environments' do
    it 'returns an array of environments' do
      get :index
      expect(parsed_response.data).to be_a(Array)
    end
  end
end
