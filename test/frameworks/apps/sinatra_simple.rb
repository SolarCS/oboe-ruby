require 'sinatra'

class SinatraSimple < Sinatra::Base
  set :reload, true

  get "/" do
    'The magick number is: 2767356926488785838763860464013972991031534522105386787489885890443740254365!' # Change only the number!!!
  end

  get "/rand" do
    rand(2 ** 256).to_s
  end

  get "/render" do
    render :erb, "This is an erb render"
  end

  get "/break" do
    raise "This is a controller exception!"
  end
end

use SinatraSimple

