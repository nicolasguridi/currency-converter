require 'sinatra'
require 'json'
require_relative 'lib/buda_client'

class BudaConverter < Sinatra::Base
  SUPPORTED_CURRENCIES = ['CLP', 'PEN', 'COP'].freeze

  class InvalidCurrencyError < StandardError; end
  class MissingParameterError < StandardError; end
  class ConversionError < StandardError; end

  get '/convert' do
    content_type :json

    begin
      from_currency, to_currency, amount = format_params
      validate_params(from_currency, to_currency, amount)
      result, crypto = find_best_conversion(from_currency, to_currency, amount)

      if result && crypto
        build_success_response(from_currency, to_currency, amount, result, crypto)
      else
        handle_conversion_failure
      end

    rescue MissingParameterError, InvalidCurrencyError => e
      handle_validation_error(e)
    rescue ConversionError => e
      handle_conversion_error(e)
    rescue JSON::ParserError => e
      handle_json_error(e)
    rescue StandardError => e
      handle_unexpected_error(e)
    end
  end

  private

  def format_params
    [
      params['from_currency']&.upcase,
      params['to_currency']&.upcase,
      params['amount']&.to_f
    ]
  end

  def validate_params(from_currency, to_currency, amount)
    validate_required_params(from_currency, to_currency, amount)
    validate_currency_support(from_currency, to_currency)
  end

  def validate_required_params(from_currency, to_currency, amount)
    return if from_currency && to_currency && amount

    raise MissingParameterError,
          "Missing required parameters: from_currency, to_currency, and amount are required"
  end

  def validate_currency_support(from_currency, to_currency)
    return if SUPPORTED_CURRENCIES.include?(from_currency) &&
             SUPPORTED_CURRENCIES.include?(to_currency)

    raise InvalidCurrencyError,
          "Invalid currency. Only #{SUPPORTED_CURRENCIES.join(', ')} are supported."
  end

  def buda_client
    @buda_client ||= BudaClient.new
  end

  def find_best_conversion(from_currency, to_currency, amount)
    markets = buda_client.get_markets
    return [nil, nil] unless markets

    crypto_intermediaries = find_available_crypto_intermediaries(markets, from_currency, to_currency)
    find_best_conversion_path(markets, crypto_intermediaries, from_currency, to_currency, amount)
  end

  def find_available_crypto_intermediaries(markets, from_currency, to_currency)
    markets.map { |m| [m['base_currency'], m['quote_currency']] }
          .flatten
          .uniq
          .reject { |c| [from_currency, to_currency].include?(c) }
  end

  def find_best_conversion_path(markets, crypto_intermediaries, from_currency, to_currency, amount)
    best_result = nil
    best_crypto = nil

    crypto_intermediaries.each do |crypto|
      result, crypto = try_conversion_path(markets, crypto, from_currency, to_currency, amount)
      if result && (best_result.nil? || result > best_result)
        best_result = result
        best_crypto = crypto
      end
    end

    [best_result, best_crypto]
  end

  def try_conversion_path(markets, crypto, from_currency, to_currency, amount)
    first_market = find_market(markets, crypto, from_currency)
    second_market = find_market(markets, crypto, to_currency)
    return [nil, nil] unless first_market && second_market

    crypto_amount = calculate_conversion("#{crypto}-#{from_currency}", amount, true)
    return [nil, nil] unless crypto_amount

    final_amount = calculate_conversion("#{crypto}-#{to_currency}", crypto_amount, false)
    return [nil, nil] unless final_amount

    [final_amount, crypto]
  end

  def find_market(markets, base_currency, quote_currency)
    markets.find do |m|
      m['base_currency'] == base_currency && m['quote_currency'] == quote_currency
    end
  end

  def calculate_conversion(market_id, amount, is_buying)
    trades = buda_client.get_trades(market_id)
    return nil unless trades && trades['entries'] && !trades['entries'].empty?

    last_trade = trades['entries'].first
    last_price = last_trade[2].to_f

    if is_buying
      amount / last_price
    else
      amount * last_price
    end
  end

  def build_success_response(from_currency, to_currency, amount, result, crypto)
    {
      success: true,
      from_currency: from_currency,
      to_currency: to_currency,
      original_amount: amount,
      converted_amount: result,
      intermediary_crypto: crypto
    }.to_json
  end

  def handle_conversion_failure
    status 422
    {
      success: false,
      error: "No valid conversion path found"
    }.to_json
  end

  def handle_validation_error(error)
    status 400
    {
      success: false,
      error: error.message
    }.to_json
  end

  def handle_conversion_error(error)
    status 422
    {
      success: false,
      error: error.message
    }.to_json
  end

  def handle_json_error(error)
    status 400
    {
      success: false,
      error: "Invalid JSON payload"
    }.to_json
  end

  def handle_unexpected_error(error)
    status 500
    {
      success: false,
      error: "An unexpected error occurred: #{error.message}"
    }.to_json
  end
end

if __FILE__ == $0
  BudaConverter.run!
end
