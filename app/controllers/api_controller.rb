# use for API spefic helpers
class ApiController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  include NapaPagination::GrapeHelpers
  include Napa::GrapeHelpers
  around_filter :error_catcher
  skip_before_filter :verify_authenticity_token

  private

  # use in an around filter to allow raising error directly and return immediately
  def error_catcher
    yield
  rescue Errors::ApiError => e
    logger.info e.backtrace.first(5).join("\n")
    render json: e.error_hash, status: e.status_code
  end

  # use to return immediately and output an error
  def error!(error_hash = {}, status_code = 500)
    raise Errors::ApiError.new(error_hash, status_code)
  end

  def current_user
    @current_user if @current_user
    begin
      user = Rails.cache.fetch("jockey|token_#{github_access_token}", expires_in: 8.hours) do
        @current_user = User.from_github_access_token(github_access_token)
      end
      return user
    rescue => e
      # we weren't able to authenticate. Log and return nil
      logger.info e.backtrace.first(5).join("\n")
      return nil
    end
  end

  def github_access_token
    params[:github_access_token]
  end

  def ensure_user!
    error!(present_error(:not_authenticated, 'could not authenticate your token'), 403) unless current_user
  end

  def mash_params
    Hashie::Mash.new(params)
  end

  def not_found(e)
    render json: { error: { code: :not_found, message: e.message } }, status: 404
  end

  def record_invalid(e)
    render json: { error: { code: :record_invalid, message: e.message } }, status: 422
  end

  def bad_request(message)
    error!(present_error(:bad_request, message), 400)
  end

  def represent_and_render(data, with: nil, **args)
    if data.respond_to?(:to_a)
      render json: { data: data.map { |item| with.new(item).to_hash(args) } }
    else
      render json: { data: with.new(data).to_hash(args) }
    end
  end

  def bool_coerce(str)
    return true if str == 'true'
    return false if str == 'false'
    nil
  end

  def paginate_with_mash(data, with: nil, **args)
    paginate(data, with, args)
  end
end
