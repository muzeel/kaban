class Task < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :creator, class_name: 'User'
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :column, optional: true
  
  has_many :comments, dependent: :destroy
  has_many :task_labels, dependent: :destroy
  has_many :labels, through: :task_labels
  has_many_attached :attachments
  
  # Validations
  validates :title, 
            presence: true, 
            length: { minimum: 3, maximum: 200 }
  
  validates :description, 
            length: { maximum: 5000 }
  
  validates :status, 
            presence: true,
            inclusion: { in: %w[backlog todo in_progress review done] }
  
  validates :priority, 
            presence: true,
            inclusion: { in: %w[low medium high critical] }
  
  validates :position, 
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  validates :due_date, 
            presence: true
  
  validate :due_date_cannot_be_in_past, on: :create
  validate :due_date_cannot_be_too_far, on: :create
  
  # Enums
  enum status: { backlog: 0, todo: 1, in_progress: 2, review: 3, done: 4 }
  enum priority: { low: 0, medium: 1, high: 2, critical: 3 }
  
  # Callbacks
  before_validation :set_default_position, on: :create
  before_create :generate_task_number
  after_create :notify_assignee
  after_update :log_status_change
  
  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :assigned_to, ->(user) { where(assignee_id: user.id) }
  scope :overdue, -> { where('due_date < ? AND status != ?', Date.current, 'done') }
  scope :upcoming, -> { where('due_date BETWEEN ? AND ?', Date.current, 7.days.from_now) }
  
  # Methods
  def display_id
    "TASK-#{task_number}"
  end
  
  def overdue?
    due_date.past? && !done?
  end
  
  def days_remaining
    return 0 if done?
    (due_date - Date.current).to_i
  end
  
  def add_label(label_name, color = '#007bff')
    label = Label.find_or_create_by(name: label_name.downcase) do |l|
      l.color = color
    end
    labels << label unless labels.include?(label)
  end
  
  def remove_label(label_name)
    label = Label.find_by(name: label_name.downcase)
    labels.delete(label) if label
  end
  
  def move_to_status(new_status, user)
    update(status: new_status, status_changed_at: Time.current, status_changed_by: user.id)
  end
  
  private
  
  def set_default_position
    self.position ||= project.tasks.maximum(:position).to_i + 1
  end
  
  def generate_task_number
    last_number = project.tasks.maximum(:task_number) || 0
    self.task_number = last_number + 1
  end
  
  def due_date_cannot_be_in_past
    return unless due_date.present? && due_date < Date.current
    errors.add(:due_date, "не может быть в прошлом")
  end
  
  def due_date_cannot_be_too_far
    return unless due_date.present? && due_date > 1.year.from_now
    errors.add(:due_date, "не может быть больше чем через год")
  end
  
  def notify_assignee
    return unless assignee.present?
    
    Notification.create(
      user: assignee,
      title: "Новая задача назначена",
      message: "Вам назначена задача: #{title}",
      link: Rails.application.routes.url_helpers.project_task_path(project, self)
    )
  end
  
  def log_status_change
    return unless saved_change_to_status?
    
    Comment.create(
      task: self,
      user: User.find(status_changed_by),
      content: "Изменил статус задачи с #{status_before_last_save} на #{status}",
      system_message: true
    )
  end
end
