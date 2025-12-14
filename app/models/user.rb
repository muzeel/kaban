class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable
  
  # Associations
  has_many :owned_projects, class_name: 'Project', foreign_key: 'owner_id', dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :assigned_tasks, class_name: 'Task', foreign_key: 'assignee_id', dependent: :nullify
  has_many :created_tasks, class_name: 'Task', foreign_key: 'creator_id', dependent: :nullify
  has_many :comments, dependent: :destroy
  has_many :notifications, dependent: :destroy
  
  # Validations
  validates :email, 
            presence: true, 
            uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  
  validates :username, 
            presence: true, 
            uniqueness: true, 
            length: { minimum: 3, maximum: 50 },
            format: { with: /\A[a-zA-Z0-9_]+\z/ }
  
  validates :first_name, :last_name, 
            presence: true, 
            length: { minimum: 2, maximum: 50 }
  
  validates :role, 
            presence: true, 
            inclusion: { in: %w[user admin] }
  
  # Enums
  enum role: { user: 0, admin: 1 }
  
  # Callbacks
  before_save :downcase_email
  before_create :set_default_role
  
  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end
  
  def active_for_authentication?
    super && !banned?
  end
  
  def ban!
    update(banned: true, banned_at: Time.current)
  end
  
  def unban!
    update(banned: false, banned_at: nil)
  end
  
  def can_edit_project?(project)
    admin? || project.owner == self || project.project_memberships.where(user: self, role: 'admin').exists?
  end
  
  private
  
  def downcase_email
    self.email = email.downcase
  end
  
  def set_default_role
    self.role ||= 'user'
  end
end
