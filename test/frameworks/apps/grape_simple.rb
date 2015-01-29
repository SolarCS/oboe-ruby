require 'grape'

class GrapeSimple < Grape::API
  rescue_from :all do |e|
    error_response({ message: "rescued from #{e.class.name}" })
  end

  get '/json_endpoint' do
    present({ :test => true })
  end

  get "/break" do
    raise Exception.new("This should have http status code 500!")
  end

  get "/breakstring" do
    raise "This should have http status code 500!"
  end
end

