require 'spec_helper'
require_relative '../api'
require_relative '../lib/buda_client'

RSpec.describe BudaConverter do
  include Rack::Test::Methods

  def app
    BudaConverter
  end

  let(:markets_data) do
    [
      {
        'id' => "BTC-CLP",
        'base_currency' => "BTC",
        'quote_currency' => "CLP"
      },
      {
        'id' => "BTC-PEN",
        'base_currency' => "BTC",
        'quote_currency' => "PEN"
      },
      {
        'id' => "ETH-CLP",
        'base_currency' => "ETH",
        'quote_currency' => "CLP"
      },
      {
        'id' => "ETH-PEN",
        'base_currency' => "ETH",
        'quote_currency' => "PEN"
      }
    ]
  end

  let(:trades_data) do
    {
      'BTC-CLP' => {
        'market_id' => "BTC-CLP",
        'entries' => [
          ["1476905551687", "0.00984662", "81600000.0", "buy"]
        ]
      },
      'BTC-PEN' => {
        'market_id' => "BTC-PEN",
        'entries' => [
          ["1476905551687", "0.00984662", "305642.93", "buy"]
        ]
      },
      'ETH-CLP' => {
        'market_id' => "ETH-CLP",
        'entries' => [
          ["1476905551687", "0.00984662", "1780184.0", "buy"]
        ]
      },
      'ETH-PEN' => {
        'market_id' => "ETH-PEN",
        'entries' => [
          ["1476905551687", "0.00984662", "6526.69", "buy"]
        ]
      }
    }
  end

  def perform_request(params)
    get "/convert", params
  end

  let(:buda_client) { instance_double(BudaClient) }

  before do
    allow(BudaClient).to receive(:new).and_return(buda_client)

    allow(buda_client).to receive(:get_markets).and_return(markets_data)

    allow(buda_client).to receive(:get_trades).with("BTC-CLP").and_return(trades_data['BTC-CLP'])
    allow(buda_client).to receive(:get_trades).with("BTC-PEN").and_return(trades_data['BTC-PEN'])
    allow(buda_client).to receive(:get_trades).with("ETH-CLP").and_return(trades_data['ETH-CLP'])
    allow(buda_client).to receive(:get_trades).with("ETH-PEN").and_return(trades_data['ETH-PEN'])
  end

  describe "GET /convert" do
    context "when there is a valid conversion path" do
      before do
        perform_request({
          from_currency: "CLP",
          to_currency: "PEN",
          amount: 10000
        })
      end

      it "returns a successful response" do
        expect(last_response.status).to eq(200)
      end

      it "returns the converted amount and intermediary crypto" do
        response = JSON.parse(last_response.body)
        expect(response).to include({
          "success" => true,
          "from_currency" => "CLP",
          "to_currency" => "PEN",
          "original_amount" => 10000,
          "converted_amount" => 37.45624142156863,
          "intermediary_crypto" => "BTC"
        })
      end
    end

    context "when no intermediate crypto is found" do
      before do
        allow(buda_client).to receive(:get_markets).and_return([])
        perform_request({
          from_currency: "CLP",
          to_currency: "PEN",
          amount: 10000
        })
      end

      it "returns unprocessable entity error" do
        expect(last_response.status).to eq(422)
      end

      it "returns a response with the error message" do
        response = JSON.parse(last_response.body)
        expect(response).to include({
          "success" => false,
          "error" => "No valid conversion path found"
        })
      end
    end

    context "where there are no trades" do
      before do
        allow(buda_client).to receive(:get_trades).and_return({
          'timestamp' => "1476905551698",
          'last_timestamp' => nil,
          'market_id' => "BTC-CLP",
          'entries' => []
        })
        perform_request({
          from_currency: "CLP",
          to_currency: "PEN",
          amount: 10000
        })
      end

      it "returns unprocessable entity error" do
        expect(last_response.status).to eq(422)
      end

      it "returns a response with the error message" do
        response = JSON.parse(last_response.body)
        expect(response).to include({
          "success" => false,
          "error" => "No valid conversion path found"
        })
      end
    end

    context "when a currency is not supported" do
      before do
        perform_request({
          from_currency: "USD",
          to_currency: "PEN",
          amount: 10000
        })
      end

      it "returns bad request error" do
        expect(last_response.status).to eq(400)
      end

      it "returns a response with the error message" do
        response = JSON.parse(last_response.body)
        expect(response).to include({
          "success" => false,
          "error" => "Invalid currency. Only CLP, PEN, COP are supported."
        })
      end
    end
  end
end
