Bundler.require

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
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
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

get '/log' do
  protected!
  erb :log
end

def title
  'Site Maintenance'
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