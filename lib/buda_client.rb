require 'httparty'
require 'json'

class BudaClient
  BASE_URL = 'https://www.buda.com/api/v2'

  def get_markets
    response = HTTParty.get("#{BASE_URL}/markets")

    if response.success?
      JSON.parse(response.body)['markets']
    else
      handle_api_error(response)
    end
  end

  def get_trades(market_id)
    response = HTTParty.get("#{BASE_URL}/markets/#{market_id}/trades")

    if response.success?
      JSON.parse(response.body)['trades']
    else
      handle_api_error(response)
    end
  end

  private

  def handle_api_error(response)
    error_body = begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      { 'message' => 'Invalid JSON response' }
    end

    error_message = error_body['message'] || 'Unknown error'

    case response.code
    when 400
      raise "Bad Request: #{error_message}"
    when 401
      raise "Unauthorized: #{error_message}"
    when 403
      raise "Forbidden: #{error_message}"
    when 404
      raise "Not Found: #{error_message}"
    when 429
      raise "Rate Limit Exceeded: #{error_message}"
    else
      raise "API Error (#{response.code}): #{error_message}"
    end
  end
end
