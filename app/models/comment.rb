class Comment < ApplicationRecord
  # Associations
  belongs_to :task
  belongs_to :user
  has_many_attached :files
  
  # Validations
  validates :content, 
            presence: true, 
            length: { minimum: 1, maximum: 2000 }
  
  validates :task_id, :user_id, 
            presence: true
  
  # Callbacks
  before_create :set_initial_position
  after_create :notify_task_assignee
  after_create :increment_comments_count
  after_destroy :decrement_comments_count
  
  # Scopes
  scope :recent, -> { order(position: :asc, created_at: :desc) }
  scope :with_files, -> { joins(:active_storage_attachments).distinct }
  
  # Methods
  def mentioned_users
    content.scan(/@([a-zA-Z0-9_]+)/).flatten.map do |username|
      User.find_by(username: username)
    end.compact
  end
  
  def notify_mentions
    mentioned_users.each do |mentioned_user|
      next if mentioned_user == user
      
      Notification.create(
        user: mentioned_user,
        title: "Вас упомянули в комментарии",
        message: "#{user.username} упомянул вас в задаче: #{task.title}",
        link: Rails.application.routes.url_helpers.project_task_path(task.project, task)
      )
    end
  end
  
  def can_edit?(current_user)
    current_user == user || current_user.admin? || task.project.owner == current_user
  end
  
  def can_delete?(current_user)
    can_edit?(current_user)
  end
  
  private
  
  def set_initial_position
    last_comment = task.comments.order(position: :desc).first
    self.position = last_comment ? last_comment.position + 1 : 1
  end
  
  def notify_task_assignee
    return if system_message? || task.assignee.nil? || task.assignee == user
    
    Notification.create(
      user: task.assignee,
      title: "Новый комментарий к вашей задаче",
      message: "#{user.username} прокомментировал задачу: #{task.title}",
      link: Rails.application.routes.url_helpers.project_task_path(task.project, task, anchor: "comment-#{id}")
    )
  end
  
  def increment_comments_count
    task.increment!(:comments_count)
  end
  
  def decrement_comments_count
    task.decrement!(:comments_count)
  end
end
