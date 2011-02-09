 
class User < ActiveRecord::Base

  acts_as_authentic do |user_model|
    user_model.validates_length_of_password_field_options = {:minimum => 6, :on => :update, :if => :has_no_credentials? }
     
  end
  has_many :user_roles, :dependent => :destroy
    has_many :roles, :through => :user_roles
      
       
    scope :active, :conditions => {:active => true}
    scope :inactive, :conditions => {:active => false}
  
  
    has_many :friends, :through => :friendships, :conditions => "status = 'accepted'"
    has_many :requested_friends, :through => :friendships, :source => :friend, :conditions => "status = 'requested'", :order => :created_at
    has_many :pending_friends, :through => :friendships, :source => :friend, :conditions => "status = 'pending'", :order => :created_at
    has_many :friendships, :dependent => :destroy
  #delegate :name, :to => :profile

  attr_accessible :login, :email, :password, :password_confirmation


  def count_online_users
      User.count(:conditions => ["last_request_at > ?", 30.minutes.ago])
    end
    
    def self.find_by_slug!(slug, options = {})
      with_scope(:find => { :conditions => ["LOWER(login) = ?", slug.to_s.downcase] }) do
        first(options) || raise(ActiveRecord::RecordNotFound)
      end
    end
    


  # returns true if the user has the "admin" role, false if not.


  def admin?
    has_role?("admin")
  end

  # returns true if the specified role is associated with the user.
  #
  #  user.has_role("admin")
  def has_role?(role)
    self.roles.count(:conditions => ["name = ?", role]) > 0
  end

  # Adds a role to the user by name
  #
  # user.add_role("admin")
  def add_role(role)
    return if self.has_role?(role)
    self.roles << Role.find_by_name(role)
  end

  def remove_role(role)
    return false unless self.has_role?(role)
    role = Role.find_by_name(role)
    self.roles.delete(role)
  end

  def make_admin
    add_role("admin")
  end

  def remove_admin
    remove_role("admin")
  end

  # User creation/activation
  # Sets the login and email and then
  # creates the account in the database,
  # sending the activation.
  def signup!(params)
    self.login = params[:user][:login]
    self.email = params[:user][:email]
    save_without_session_maintenance
  end

  # Activates a user, sets their password, and
  # creates a blank profile record associated
  # with the user.
  def activate!(params)
    self.active = true
    self.password = params[:user][:password]
    self.password_confirmation = params[:user][:password_confirmation]
    #save_and_create_profile
    self.save
  end

   # an active account - passed activation
   # Returns true if the user's active flag is set, false if not
   def active?
     active == true
   end

   # Returns true if the password field in the database is blank
   def has_no_credentials?
     self.crypted_password.blank?# && self.openid_identifier.blank?
   end

   # Email notifications

# Email notifications

   # Resets the token and sends the password reset instructions via Notifier
   def deliver_password_reset_instructions!
     reset_perishable_token!
     Notifier.deliver_password_reset_instructions(self)
   end

   # Resets the token and sends the activation instructions via Notifier
   def deliver_activation_instructions!
     reset_perishable_token!
     #Notifier.activation_instructions.deliver
    Notifier.deliver_activation_instructions(self)
    # Notifier.send_at(1.minutes.from_now, :deliver_activation_instructions, self)
   end

   # Resets the token and sends the activation confirmatio via Notifier
   def deliver_activation_confirmation!
     reset_perishable_token!
     Notifier.deliver_activation_confirmation(self)
   end

   # Creates a blank profile, associates it with the user,
   # and saves the user
   # def save_and_create_profile
   #   self.profile = Profile.new
   #   self.save
   # end

end
