class Label < ApplicationRecord
  # Associations
  has_many :task_labels, dependent: :destroy
  has_many :tasks, through: :task_labels
  
  # Validations
  validates :name, 
            presence: true, 
            uniqueness: true,
            length: { minimum: 2, maximum: 50 }
  
  validates :color, 
            presence: true,
            format: { with: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/ }
  
  # Callbacks
  before_validation :normalize_name
  
  # Scopes
  scope :most_used, ->(limit = 10) { 
    left_joins(:task_labels)
      .group('labels.id')
      .order('COUNT(task_labels.id) DESC')
      .limit(limit) 
  }
  
  scope :for_project, ->(project_id) {
    joins(:tasks).where(tasks: { project_id: project_id }).distinct
  }
  
  # Methods
  def usage_count
    tasks.count
  end
  
  def light_color?
    # Определяем, является ли цвет светлым (для выбора цвета текста)
    hex = color.gsub('#', '')
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) }
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    luminance > 0.5
  end
  
  def text_color
    light_color? ? '#000000' : '#FFFFFF'
  end
  
  private
  
  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
