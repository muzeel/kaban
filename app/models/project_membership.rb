class ProjectMembership < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :user
  
  # Validations
  validates :user_id, 
            uniqueness: { scope: :project_id, message: "уже является участником проекта" }
  
  validates :role, 
            presence: true,
            inclusion: { in: %w[member admin] }
  
  # Enums
  enum role: { member: 0, admin: 1 }
  
  # Callbacks
  after_create :send_welcome_notification
  after_destroy :cleanup_user_data
  
  # Methods
  def can_edit_project?
    admin? || project.owner == user
  end
  
  def can_manage_tasks?
    true # Все участники могут управлять задачами в проекте
  end
  
  def can_invite_users?
    admin? || project.owner == user
  end
  
  private
  
  def send_welcome_notification
    Notification.create(
      user: user,
      title: "Добро пожаловать в проект!",
      message: "Вас добавили в проект: #{project.name}",
      link: Rails.application.routes.url_helpers.project_path(project)
    )
  end
  
  def cleanup_user_data
    # Отменить все назначения пользователя на задачи проекта
    project.tasks.where(assignee_id: user.id).update_all(assignee_id: nil)
  end
end
