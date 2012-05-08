require 'rack/pagespeed'
require './app'

use Rack::PageSpeed, :public => 'static' do
  store :disk => 'static'
  inline_css :max_size => 10000000
  inline_javascripts :max_size => 10000000
end
run Sinatra::Application
