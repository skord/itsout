require 'faye'

faye_server = Faye::RackAdapter.new(:mount => '/faye', :timeout => 30, :port => 9001)
Faye::WebSocket.load_adapter('thin')
run faye_server