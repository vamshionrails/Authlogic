class IndexController < ApplicationController
  
  before_filter :require_user, :only => [:dashboard]
  def index
  end
  def dashboard
  end
end
