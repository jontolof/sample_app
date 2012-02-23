# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime
#  updated_at :datetime
#
require 'digest'

class User < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :name, :email, :password, :password_confirmation
  
  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  validates :name,  :presence => true,
                    :length   => { :maximum => 50 }
  validates :email, :presence => true,
                    :format   => { :with => email_regex },
                    :uniqueness => { :case_sensitive => false }
                    
  # Automatically creates the virtual attribute 'password_confirmation' (?)
  validates :password,  :presence     => true,
                        :confirmation => true,
                        :length       => { :within => 6..40 }
  
  before_save :encrypt_password
  
  # Return true if the user's password matches the submitted password.
  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end

  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end

  def self.authenticate(email, submitted_password)
    user = find_by_email(email)
    return nil if user.nil?
    return user if user.has_password?(submitted_password)
  end
  
  # Why does this alternative implementation work?
  # ---------------- >
  #def User.authenticate(email, submitted_password)
  #    user = find_by_email(email)
  #    return nil  if user.nil?
  #    return user if user.has_password?(submitted_password)
  #end
  # ---------------- >
  # Answer: The only difference to the first implementation is
  # that 'self' is exchanged with 'User'. But 'self' in a 
  # method definition defines a class method in Ruby, so exchanging
  # 'self' with 'User' is litterarly the same thing.
  
  # What is so fuzzy about this method?
  # ---------------- >
  #def self.authenticate(email, submitted_password)
  #    user = find_by_email(email)
  #    return nil  if user.nil?
  #    return user if user.has_password?(submitted_password)
  #    return nil
  #end
  # ---------------- >
  # Answer: By default the original implementation returns nil (since
  # no return value is defined). This last line might be good for clairification
  # but is utterly redundant and therefor can be ommited
  
  #def self.authenticate(email, submitted_password)
  #  user = find_by_email(email)
  #  if user.nil?
  #    nil
  #  elsif user.has_password?(submitted_password)
  #    user
  #  else
  #    nil
  #  end
  #end
  
  # Comment: Same this as above, but omitting a default nil return value
  #def self.authenticate(email, submitted_password)
  #  user = find_by_email(email)
  #  if user.nil?
  #    nil
  #  elsif user.has_password?(submitted_password)
  #    user
  #  end
  #end
  
  # Comment: One line if statement with to cases required as YES
  #def self.authenticate(email, submitted_password)
  #  user = find_by_email(email)
  #  user && user.has_password?(submitted_password) ? user : nil
  #end
  
  private
    def encrypt_password
      self.salt = make_salt unless has_password?(password)
      self.encrypted_password = encrypt(password)
    end
    
    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end
    
    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end
    
    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end
end
