module Errors
  class ApiError < StandardError
    attr_reader :error_hash, :status_code
    def initialize(error_hash = {}, status_code = 500)
      @error_hash = error_hash
      @status_code = status_code
    end
  end
end
