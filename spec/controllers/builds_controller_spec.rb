require 'rails_helper'

describe BuildsController, type: :controller do
  before do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    @request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApiController).to receive(:current_user).and_return(User.create)
  end

  describe 'POST /builds' do
    before do
      @app = FactoryGirl.create(:app,
                                name: 'build_test_app',
                                repo: 'bellycard/test',
                                subscribe_to_github_webhook: false)
    end

    it 'creates a build object' do
      post :create, app: @app.name, ref: 'HEAD'
      expect(parsed_response.data.app.name).to eq(@app.name)
      expect(Build.count).to eq(1)
    end

    xit 'adds job to build queue' do
      expect { post :create, app: @app.name, ref: 'HEAD' }.to change(BuildWorker.jobs, :size).by(1)
    end

    it 'errors if passing in an unknown app' do
      post :create, app: 'not_a_real_app', ref: 'HEAD'
      expect(response_code).to eq(404)
    end
  end

  describe 'GET /builds/:id' do
    before do
      @app = FactoryGirl.create(:app,
                                name: 'build_test_app',
                                repo: 'bellycard/test',
                                subscribe_to_github_webhook: false)
      @build = Build.create!(app: @app, ref: 'HEAD')
    end

    it 'gets by id' do
      get :show, id: @build.id
      expect(parsed_response.data.id).to eq(@build.id.to_s)
      expect(parsed_response.data.ref).to eq(@build.ref)
    end
  end

  describe 'GET /builds' do
    before do
      @app = FactoryGirl.create(:app,
                                name: 'build_test_app',
                                repo: 'bellycard/test',
                                subscribe_to_github_webhook: false)
      (0..100).each { |i| Build.create(app_id: @app.id, ref: 'some_ref' + i.to_s, state: 'completed') }
    end

    it 'returns an array of builds' do
      get :index
      expect(parsed_response.data).to be_a(Array)
    end

    it 'paginates if more then 25 results are returned' do
      get :index
      expect(parsed_response.data.length).to eq(25)
      expect(parsed_response.pagination).to be_a(Hash)
      expect(parsed_response.pagination.per_page).to eq(25)
    end

    it 'orders by a key that is passed in' do
      get :index, sort_by: :ref
      expect(parsed_response.data[0].id).to eq(Build.find_by_ref('some_ref0').id.to_s)
    end

    it 'sorts in the order passed in' do
      get :index, sort_by: :ref, sort_order: :desc
      expect(parsed_response.data[0].id).to eq(Build.find_by_ref('some_ref99').id.to_s)
    end

    it 'filters by app name' do
      build = FactoryGirl.create(:build)
      get :index, app: build.app.name
      expect(parsed_response.data.length).to eq(1)
      expect(parsed_response.data.first.id).to eq(build.id.to_s)
    end

    it 'filters by state' do
      build = FactoryGirl.create(:build, state: 'in_progress')
      get :index, state: build.state
      expect(parsed_response.data.length).to eq(1)
      expect(parsed_response.data.first.id).to eq(build.id.to_s)
    end

    it 'filters by rref' do
      build = FactoryGirl.create(:build, rref: 'ffffff')
      get :index, rref: build.rref
      expect(parsed_response.data.length).to eq(1)
      expect(parsed_response.data.first.id).to eq(build.id.to_s)
    end

  end
end
