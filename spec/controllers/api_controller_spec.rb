require 'rails_helper'

RSpec.describe ApiController, type: :controller do
  before do
    @request.env['HTTP_ACCEPT'] = 'application/json'
    @request.env['CONTENT_TYPE'] = 'application/json'
  end

  # use an anonymous controller based extending ApiController
  controller(ApiController) do
    before_filter :ensure_user!
    def index
      {}
    end
  end

  it 'fails with grace if not authable by github', :vcr do
    get :index
    expect(parsed_response.error.code).to eq('not_authenticated')
  end
end
