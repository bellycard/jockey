class StatusController < ApiController
  def sanity
    status = SanityStatus.new
    render json: {data: status.to_json}, status: status.healthy? ? 200 : 500
  end
end
