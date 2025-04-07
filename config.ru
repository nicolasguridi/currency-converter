require './api'

ENV['RACK_ENV'] = ENV['RACK_ENV'] || 'development'

BudaConverter.configure do
  set :bind, '0.0.0.0'
  set :port, 4567
end

run BudaConverter
