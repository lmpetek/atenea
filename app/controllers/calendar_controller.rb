class CalendarController < ApplicationController
  before_filter :authenticate, :except => [:login, :verify]
  
  def login
    @username = ''
    @password = ''
  end
  
  def index
    @account.check_public = false
    @calendars = @account.calendars.select{|member| member == 'consultorio'}
    @events = @account.events
    @account.check_public = true
  end
  
  def events
    @calendar = Calendar.find(@account, {:id => params[:calendar_id]})
    @calendars = []
    @events = @calendar.events
  end
  
  def view
    @event = Event.find(@account, {:id => params[:event_id]})
    @minutes = 5.upto(200).collect{|m| [m.to_s] }
  end
  
  def edit
    @event = Event.find(@account, {:id => params[:event_id]})
  end
  
  def new
    @event = Event.new(@account)
  end
  
  def save
    @event = (params[:event_id] and params[:event_id] != '') ? Event.find(@account, {:id => params[:event_id]}) : Event.new(@account)
    if not @event.calendar
      @event.calendar = Calendar.find(@account, {:id => params[:calendar_id]})
    end
    if params[:recurrence] == '1'
      @event.recurrence = Recurrence.new
      @event.recurrence.start_time = Time.parse(params[:recurrence_start])
      @event.recurrence.end_time = Time.parse(params[:recurrence_end])
      @event.recurrence.frequency = {params[:recurrence_freq] => [params[:recurrence_on]]}
      @event.recurrence.repeat_until = (Date.parse(params[:recurrence_until]))
    end
    params[:event].each do |key, value|
      @event.send("#{key}=", value)
    end
    if @event.save
      flash[:notice] = "Evento actualizado"
    else
      flash[:warning] = "No es posible actualizar el evento"
    end
    redirect_to :action => :view, :event_id => @event.id
  end
  
  def delete_event
    @event = Event.find(@account, {:id => params[:event_id]})
    if @event.delete
      flash[:notice] = 'Evento borrado satisfactoriamente'
    else 
      flash[:warning] = 'No es posible borrar el evento!'
    end
    redirect_to request.referer
  end
  
  def remove_reminder
    @event = Event.find(@account, {:id => params[:event_id]})
    @event.reminder.delete_if do |r|
      if r[:method] == params[:method]
        if r[:method] == 'none' or r[:minutes] == params[:minutes]
          true
        else
          false
        end
      end
    end
    if @event.save
      flash[:notice] = 'Recordatorio borrado'
    else
      flash[:warning] = 'No es posible borrar el recordatorio'
    end
    redirect_to :action => :view, :event_id => @event.id
  end
  
  def add_recurrence
    @event = Event.find(@account, {:id => params[:event_id]})
    @event.reminder << if params[:method] != 'none'
      {:method => params[:method], :minutes => params[:minutes]}
    else
      {:method => 'none'}
    end
    if @event.save
      flash[:notice] = 'Recordatorio adicionado'
    else
      flash[:warning] = 'No es posible agregar el recordatorio'
    end
    redirect_to :action => :view, :event_id => @event.id
  end
  
  def remove_attendee
    @event = Event.find(@account, {:id => params[:event_id]})
    @event.attendees.delete_if do |a|
      if a[:email] == params[:email]
        logger.info 'deleting attendee'
        true
      else
        logger.info "dont delete attendee #{a[:email]} != #{params[:email]}"
        false
      end
    end
    if @event.save
      flash[:notice] = 'Attendee deleted'
    else
      flash[:warning] = 'Could not delete attendee'
    end
    redirect_to :action => :view, :event_id => @event.id
  end
  
  def add_attendee
    @event = Event.find(@account, {:id => params[:event_id]})
    @event.attendees << {:email => params[:email], :name => params[:name]}
    if @event.save
      flash[:notice] = 'Attendee added'
    else
      flash[:warning] = 'Could not add attendee'
    end
    redirect_to :action => :view, :event_id => @event.id
  end
  
  def save_calendar
    cal = Calendar.new(@account, {:title => params[:title]})
    if cal.save
      flash[:notice] = 'Calendario guardado!'
    else
      flash[:warning] = 'No es posible grabar el calendario!'
    end
    redirect_to :action => :index
  end
  
  def delete_calendar
    @calendar = Calendar.find(@account, {:id => params[:calendar_id]})
    if @calendar.delete
      flash[:notice] = 'Calendario Borrado'
    else
      flash[:warning] = 'No es posible borrar el calendario'
    end
    redirect_to request.referer
  end
  
  def search
    if params[:search]
      @account.check_public = false
      @events = []
      args = {}
      args['start-min'] = Time.parse(params[:start]).utc.xmlschema if params[:start] and params[:start] != ''
      args['start-max'] = Time.parse(params[:end]).utc.xmlschema if params[:end] and params[:end] != ''
      args[:calendar] = params[:calendar_id] if params[:calendar_id] != 'All'
      @events = Event.find(@account, params[:term], args)
      @account.check_public = true
      render :action => :search_results and return
    else
      @account.check_public = false
      @calendars = @account.calendars
      @account.check_public = true
    end
  end
  
  def iframe_test
    @calendar = @account.calendars.first
  end
  
  def verify
    @username = params[:username]
    @password = params[:password]
    if params[:username].empty? or params[:password].empty?
      flash[:warning] = 'Ud debe ingresar usuario y clave.'
      render :action => :login and return 
    end
    begin
      service = Service.new
      service.authenticate(params[:username], params[:password])
    rescue AuthenticationFailed
      flash[:warning] = 'Usuario y/o clave son incorrectos!'
      render :action => :login and return
    end
    session[:username] = params[:username]
    session[:password] = params[:password]
    redirect_to :action => :index
  end
  
  def logout
    session[:username] = nil
    session[:password] = nil
    flash[:notice] = 'Ud esta fuera del sistema.'
    redirect_to :action => :login
  end
end
