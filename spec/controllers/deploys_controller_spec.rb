require 'spec_helper'

describe DeploysController, type: :controller do
  before do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    @request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApiController).to receive(:current_user).and_return(User.create)
  end

  describe 'GET /deploys/:id' do
    before do
      @deploy = FactoryGirl.create(:deploy)
    end

    it 'gets by id' do
      get :show, id: @deploy.id
      expect(parsed_response.data.id).to eq(@deploy.id.to_s)
    end
  end

  describe 'GET /deploys' do
    before do
      @deploy = FactoryGirl.create(:deploy)
    end

    it 'returns a status' do
      get :index
      expect(parsed_response.data).to be_a(Array)
    end

    it 'filters by app' do
      app_2 = FactoryGirl.create(:app)
      worker = FactoryGirl.create(:worker, app: app_2)
      deploy_2 = FactoryGirl.create(:deploy, app: app_2)
      get :index, app: app_2.name
      expect(parsed_response.data.first.id).to eq(deploy_2.id.to_s)
      expect(parsed_response.data.size).to eq(1)
    end

    it 'filters by environment' do
      environment_2 = FactoryGirl.create(:environment, name: 'al gore')
      worker = FactoryGirl.create(:worker, environment: environment_2)
      deploy_2 = FactoryGirl.create(:deploy, environment: environment_2)
      get :index, environment: environment_2.name
      expect(parsed_response.data.first.id).to eq(deploy_2.id.to_s)
      expect(parsed_response.data.size).to eq(1)
    end
  end

  describe "POST /deploys" do
    it "returns an error when it cannot find the specified app" do
      App.delete_all
      post :create, {app: "ryans-fun-service"}
      expect(response_code).to eq(422)
    end

    it 'returns an error if an rref is not passed' do
      app = FactoryGirl.create(:app)
      environment = FactoryGirl.create(:environment)
      post :create, app: app.name, environment: environment.name
      expect(response_code).to eq(422)
    end

    it "creates a deploy on the app with the specified environment and build specified by the reference" do
      app = FactoryGirl.create(:app, name: "ryans-fun-service")
      build = FactoryGirl.create(:build, app: app)
      environment = FactoryGirl.create(:environment)

      post :create, {app: "ryans-fun-service", rref: build.rref, environment: environment.name}

      expect(app.deploys.last.build).to eq(build)
      expect(app.deploys.last.environment).to eq(environment)
    end

    context "on success" do
      let(:app) { FactoryGirl.create(:app, name: "ryans-fun-service") }
      let(:build) { FactoryGirl.create(:build, app: app) }
      let(:environment) { FactoryGirl.create(:environment) }

      it "returns a 202" do
        post :create, {app: "ryans-fun-service", rref: build.rref, environment: environment.name}
        expect(response_code).to eq(202)
      end
    end

    context "on validation errors" do
      let(:app) { FactoryGirl.create(:app, name: "ryans-fun-service") }

      before do
        post :create, {app: app.name, rref: "12312", environment_name: "doesn't matter"}
      end

      it "returns a 422" do
        expect(response_code).to eq(422)
      end

      it "returns an error response json" do
        expect(parsed_response.error.code).to eq("unprocessable_entity")
      end
    end
  end
end
