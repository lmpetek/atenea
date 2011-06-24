require 'gcal4ruby'

class ApplicationController < ActionController::Base
  include GCal4Ruby
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def authenticate
    if not session[:username] or not session[:password]
      redirect_to :action => :login and return
    end
    @account = Service.new()
    @account.debug = true
    @account.authenticate(session[:username], session[:password])
  end
end
