class Project < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'User'
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :tasks, dependent: :destroy
  has_many :invitations, dependent: :destroy
  
  # Validations
  validates :name, 
            presence: true, 
            length: { minimum: 3, maximum: 100 },
            uniqueness: { scope: :owner_id }
  
  validates :description, 
            length: { maximum: 1000 }
  
  validates :slug, 
            presence: true, 
            uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/ }
  
  validates :status, 
            presence: true,
            inclusion: { in: %w[active archived completed] }
  
  # Enums
  enum status: { active: 0, archived: 1, completed: 2 }
  
  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && slug.blank? }
  before_create :add_owner_as_member
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(status: :active) }
  scope :for_user, ->(user) { joins(:project_memberships).where(project_memberships: { user_id: user.id }) }
  
  # Methods
  def to_param
    slug
  end
  
  def members_count
    members.count
  end
  
  def tasks_count_by_status
    tasks.group(:status).count
  end
  
  def overdue_tasks
    tasks.where('due_date < ? AND status != ?', Date.current, 'done')
  end
  
  def progress_percentage
    total_tasks = tasks.count
    return 0 if total_tasks.zero?
    
    completed_tasks = tasks.where(status: 'done').count
    (completed_tasks.to_f / total_tasks * 100).round
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize
    counter = 1
    while Project.exists?(slug: slug)
      self.slug = "#{name.parameterize}-#{counter}"
      counter += 1
    end
  end
  
  def add_owner_as_member
    project_memberships.build(user: owner, role: 'admin')
  end
end
