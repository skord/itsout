Bundler.require
require 'json'

enable :sessions

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end
  
  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV['ADMIN_USER'], ENV['ADMIN_PASSWORD']]
  end

  def faye_path
    "#{request.scheme}://#{request.host}:9001/faye"
  end
  
  def faye_js_path
    faye_path + '.js'
  end

  def severity_classes(severity)
    {major: 'alert alert-error', minor: 'alert', good: 'alert alert-success', info: 'alert alert-info' }[severity.to_sym]
  end
  
  def timeago(time)
    "<time class='timeago' datetime=#{time.iso8601}>#{time}</time>"
  end
  
  def nicetime(time_obj)
    time_obj.strftime('%A %b %-d, %Y %l:%k%p')
  end
end

get '/' do
  @maintenance_events = MaintenanceEvent.all(:order => [:created_at.desc])
  @updates = Update.all(:order => [:created_at.desc])
  erb :index
end

get '/update/:id' do 
  @update = Update.get(params[:id])
  erb :update, :layout => false, :locals => {:update => @update}
end

get '/maintenance_events' do
  protected!
  @maintenance_events = MaintenanceEvent.all(:order => [:created_at.desc]) 
  erb :admin
end

post '/maintenance_events' do
 protected!
 @maintenance_event =  MaintenanceEvent.new(params[:maintenance_event])
 if @maintenance_event.save
  flash[:notice] = "Save Successful"
  redirect to('/maintenance_events')
 else
  flash[:notice] = "You had an error in your form, try again."
  redirect to('/maintenance_events')
 end
end

get '/maintenance_events/:id/close' do
  protected!
  @maintenance_event = MaintenanceEvent.get(params[:id])
  @maintenance_event.closed_at = Time.now
  if @maintenance_event.save
    flash[:notice] = "Issue closed"
    redirect to('/maintenance_events')
  else
    flash[:notice] = "Couldn't close the issue"
    redirect to('/maintenance_events')
  end
end

get '/maintenance_events/:id/open' do
  protected!
  @maintenance_event = MaintenanceEvent.get(params[:id])
  @maintenance_event.closed_at = nil
  if @maintenance_event.save
    flash[:notice] = "Issue re-opened!"
    redirect to('/maintenance_events')
  else
    flash[:notice] = "Couldn't re-open the issue"
    redirect to('/maintenance_events')
  end
end

post '/maintenance_events/:id/updates/new' do
  protected!
  @maintenance_event = MaintenanceEvent.get(params[:id])
  @update = @maintenance_event.updates.create(params[:update])
  if @update.save
    flash[:notice] = "Live Update Created"
    broadcast(@update.id)
    redirect to('/maintenance_events')
  else
    flash[:notice] = "Couldn't Create Live Update"
    redirect to('/maintenance_events')
  end
end

get '/log' do
  protected!
  erb :log
end

def title
  'Site Maintenance'
end

def escape_javascript(html_content)
  return '' unless html_content
  javascript_mapping = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n' }
  javascript_mapping.merge("\r" => '\n', '"' => '\\"', "'" => "\\'")
  escaped_string = html_content.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { javascript_mapping[$1] }
  "\"#{escaped_string}\""
end

def broadcast(update_id)
  update = Update.get(update_id)
  update_message = {:channel => '/messages/new', :data => "$.get('/update/#{update.id}', function(data){ $('#updates').prepend(data);$('#update-#{update.id}').fadeOut().fadeIn().fadeOut().fadeIn();});"}
  uri = URI.parse("http://localhost:9001/faye")
  Net::HTTP.post_form(uri, :message => update_message.to_json)
end

DataMapper.setup(:default, 'sqlite:project.db')

class Update
  include DataMapper::Resource
  SEVERITIES = ['major', 'minor', 'good', "info"]

  property :id,   Serial
  property :title, String
  property :created_at, DateTime
  property :updated_at, DateTime
  property :text, Text
  property :severity, String

  belongs_to :maintenance_event
  
  validates_within :severity, :set => SEVERITIES
  validates_presence_of :title
  validates_presence_of :text
  
  def open?
    self.maintenance_event.closed_at.nil?
  end

end

class MaintenanceEvent
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :text, Text
  property :created_at, DateTime
  property :updated_at, DateTime
  property :closed_at, DateTime
  has n, :updates
  validates_presence_of :title
  validates_presence_of :text
end

DataMapper.auto_upgrade!