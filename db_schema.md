Схема БД:
+ users (id, email, password_digest, name, role)
+ projects (id, name, description, owner_id)
+ memberships (id, user_id, project_id, role_in_project) # Для связи пользователей с проектами
+ tasks (id, title, description, status, position, due_date, project_id, assignee_id)
+ comments (id, content, task_id, user_id)
+ labels (id, name, color)
+ task_labels (id, task_id, label_id) # many-to-many
