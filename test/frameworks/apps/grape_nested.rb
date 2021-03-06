require 'grape'

class Wrapper < Grape::API
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

    get "/error" do
      error!("This is a error with 'error'!")
    end

    get "/breakstring" do
      raise "This should have http status code 500!"
    end
  end
end

class GrapeNested < Grape::API
  mount Wrapper::GrapeSimple
end

