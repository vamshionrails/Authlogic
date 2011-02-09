class UsersController < ApplicationController

  LOGIN_PATTERN = 'w[w.+-_@]+'

  
 before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:delete, :edit, :update]
  before_filter :redirect_if_not_record_owner, :only =>[:edit, :update]


  def show
   # @user = User.find(params[:id])
   @users = User.all 
  @user = User.find_by_slug!(params[:id])
    respond_to do |format|
      format.html
      format.xml {render :xml=>@user.to_xml}
    end
  end

  def new
      @user = User.new
  end

  def create
    @user = User.new
    if @user.signup!(params)
      @user.deliver_activation_instructions!
      flash[:notice] = "Your account has been created. Please check your e-mail for your account activation instructions!"
      redirect_to root_url
    else
      render :action => :new
    end
  end

  def edit
    @user = current_user
  end
   
   
  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      redirect_to dashboard_url
    else
      render :action => "edit"
    end
  end

  private

  def redirect_if_not_record_owner
    unless params[:id].to_i == current_user.id
      flash[:notice] = "You don't have access to that record"
      redirect_to dashboard_url
    end
  end


end