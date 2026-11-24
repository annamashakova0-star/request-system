-- РАЗДЕЛ 1. АВТОРИЗАЦИЯ

-- 1.1. Проверка пользователя при входе (поиск по логину)
-- Возвращает: user_id, password_hash, role_id, department_id
SELECT user_id, password_hash, role_id, department_id 
FROM users 
WHERE login = :login AND is_active = 1;

-- 1.2. Получение данных пользователя после входа
-- Возвращает: ФИО, роль, отдел, филиал
SELECT 
    u.user_id,
    u.full_name,
    u.phone,
    r.role_name,
    d.department_name,
    d.location,
    b.branch_name,
    b.full_address
FROM users u
JOIN roles r ON u.role_id = r.role_id
JOIN departments d ON u.department_id = d.department_id
JOIN branches b ON d.branch_id = b.branch_id
WHERE u.user_id = :user_id;


-- РАЗДЕЛ 2. ЗАПРОСЫ ДЛЯ СОТРУДНИКА

-- 2.1. Просмотр своих заявок (с названиями статусов и типов)
SELECT 
    r.request_id,
    r.request_number,
    t.type_name AS request_type,
    s.status_name AS current_status,
    p.priority_name,
    r.quantity,
    r.description,
    r.created_at,
    r.status_changed_at
FROM requests r
JOIN request_types t ON r.type_id = t.type_id
JOIN statuses s ON r.status_id = s.status_id
JOIN priorities p ON r.priority_id = p.priority_id
WHERE r.author_id = :user_id
ORDER BY r.created_at DESC;

-- 2.2. Создание новой заявки
INSERT INTO requests (
    request_number, author_id, type_id, status_id, priority_id, 
    equipment_id, consumable_id, quantity, description, created_at
) VALUES (
    :request_number, :author_id, :type_id, 1, :priority_id,
    :equipment_id, :consumable_id, :quantity, :description, NOW()
);

-- 2.3. Отмена заявки (только если статус "Новая" и автор — текущий сотрудник)
UPDATE requests 
SET status_id = 6, status_changed_at = NOW()
WHERE request_id = :request_id 
  AND author_id = :user_id 
  AND status_id = 1;

-- 2.4. Просмотр истории своей заявки
SELECT 
    rh.history_id,
    rh.changed_at,
    u.full_name AS changed_by,
    old_s.status_name AS old_status,
    new_s.status_name AS new_status,
    rh.comment
FROM request_history rh
JOIN users u ON rh.changed_by_id = u.user_id
JOIN statuses old_s ON rh.old_status_id = old_s.status_id
JOIN statuses new_s ON rh.new_status_id = new_s.status_id
WHERE rh.request_id = :request_id
ORDER BY rh.changed_at ASC;

-- 2.5. Просмотр комментариев к заявке
SELECT 
    c.comment_id,
    c.comment_text,
    c.created_at,
    u.full_name AS author_name,
    r.role_name AS author_role,
    s.status_name AS status_at_moment
FROM comments c
JOIN users u ON c.author_id = u.user_id
JOIN roles r ON u.role_id = r.role_id
JOIN statuses s ON c.status_id = s.status_id
WHERE c.request_id = :request_id
ORDER BY c.created_at ASC;

-- 2.6. Добавление комментария к заявке
INSERT INTO comments (request_id, author_id, status_id, comment_text, created_at)
VALUES (
    :request_id, 
    :author_id, 
    (SELECT status_id FROM requests WHERE request_id = :request_id),
    :comment_text, 
    NOW()
);

-- 2.7. Получение списка типов заявок (для выпадающего списка)
SELECT type_id, type_name FROM request_types ORDER BY type_id;

-- 2.8. Получение списка техники (только активная)
SELECT equipment_id, equipment_type, model_name, inventory_number, cabinet 
FROM equipment 
WHERE status = 'В работе'
ORDER BY model_name;

-- 2.9. Получение списка расходников (для выпадающего списка)
SELECT consumable_id, item_name, stock_qty, min_threshold
FROM consumables
ORDER BY item_name;

-- 2.10. Получение списка приоритетов
SELECT priority_id, priority_name FROM priorities ORDER BY priority_id;

-- РАЗДЕЛ 3. ЗАПРОСЫ ДЛЯ ОБРАБОТЧИКА

-- 3.1. Просмотр всех заявок (с именем автора, отделом, статусом)
SELECT 
    r.request_id,
    r.request_number,
    u.full_name AS author_name,
    u.phone AS author_phone,
    d.department_name,
    t.type_name AS request_type,
    s.status_name AS current_status,
    p.priority_name,
    r.quantity,
    r.description,
    r.created_at,
    r.status_changed_at
FROM requests r
JOIN users u ON r.author_id = u.user_id
JOIN departments d ON u.department_id = d.department_id
JOIN request_types t ON r.type_id = t.type_id
JOIN statuses s ON r.status_id = s.status_id
JOIN priorities p ON r.priority_id = p.priority_id
ORDER BY p.priority_id DESC, r.created_at DESC;

-- 3.2. Фильтрация заявок по статусу
SELECT * FROM view_full_requests WHERE current_status = :status_name;

-- 3.3. Фильтрация заявок по отделу
SELECT * FROM view_full_requests WHERE department_name = :department_name;

-- 3.4. Фильтрация заявок по типу
SELECT * FROM view_full_requests WHERE request_type = :type_name;

-- 3.5. Фильтрация по срочности
SELECT * FROM view_full_requests WHERE priority_name = 'Срочная';

-- 3.6. Поиск заявки по номеру
SELECT * FROM view_full_requests WHERE request_number = :request_number;

-- 3.7. Смена статуса заявки (через процедуру)
CALL change_request_status(:request_id, :user_id, :new_status_id, :comment);

-- 3.8. Отклонение заявки (с причиной)
UPDATE requests 
SET status_id = 5, 
    reject_reason = :reject_reason, 
    status_changed_at = NOW()
WHERE request_id = :request_id;

-- 3.9. Списание со склада (через процедуру)
CALL write_off_consumable(:request_id, :consumable_id, :quantity);

-- 3.10. Просмотр остатков на складе
SELECT 
    c.consumable_id,
    c.item_name,
    c.stock_qty,
    c.min_threshold,
    u.unit_name
FROM consumables c
JOIN units u ON c.unit_id = u.unit_id
ORDER BY c.item_name;

-- 3.11. Добавление прихода на склад
UPDATE consumables 
SET stock_qty = stock_qty + :quantity 
WHERE consumable_id = :consumable_id;

-- 3.12. Добавление новой техники
INSERT INTO equipment (equipment_type, model_name, inventory_number, cabinet, cartridge_yield, status)
VALUES (:equipment_type, :model_name, :inventory_number, :cabinet, :cartridge_yield, 'В работе');

-- 3.13. Изменение статуса техники (в ремонт / в работу / на складе)
UPDATE equipment SET status = :status WHERE equipment_id = :equipment_id;

-- 3.14. Просмотр всех комментариев по заявке
SELECT 
    c.comment_id,
    c.comment_text,
    c.created_at,
    u.full_name AS author_name,
    s.status_name AS status_at_moment
FROM comments c
JOIN users u ON c.author_id = u.user_id
JOIN statuses s ON c.status_id = s.status_id
WHERE c.request_id = :request_id
ORDER BY c.created_at ASC;

-- РАЗДЕЛ 4. ЗАПРОСЫ ДЛЯ АДМИНИСТРАТОРА

-- 4.1. Просмотр всех пользователей с ролями и отделами
SELECT 
    u.user_id,
    u.full_name,
    u.login,
    u.phone,
    r.role_name,
    d.department_name,
    u.is_active,
    u.created_at
FROM users u
JOIN roles r ON u.role_id = r.role_id
JOIN departments d ON u.department_id = d.department_id
ORDER BY u.full_name;

-- 4.2. Создание нового пользователя
INSERT INTO users (full_name, login, password_hash, phone, role_id, department_id, is_active)
VALUES (:full_name, :login, :password_hash, :phone, :role_id, :department_id, 1);

-- 4.3. Блокировка пользователя
UPDATE users SET is_active = 0 WHERE user_id = :user_id;

-- 4.4. Разблокировка пользователя
UPDATE users SET is_active = 1 WHERE user_id = :user_id;

-- 4.5. Смена роли пользователя
UPDATE users SET role_id = :new_role_id WHERE user_id = :user_id;

-- 4.6. Просмотр журнала действий (история заявок)
SELECT 
    rh.history_id,
    rh.changed_at,
    u.full_name AS changed_by,
    r.request_number,
    old_s.status_name AS old_status,
    new_s.status_name AS new_status,
    rh.comment
FROM request_history rh
JOIN users u ON rh.changed_by_id = u.user_id
JOIN requests r ON rh.request_id = r.request_id
JOIN statuses old_s ON rh.old_status_id = old_s.status_id
JOIN statuses new_s ON rh.new_status_id = new_s.status_id
ORDER BY rh.changed_at DESC
LIMIT 100;

-- 4.7. Просмотр всех справочников
SELECT * FROM roles;
SELECT * FROM branches;
SELECT * FROM departments;
SELECT * FROM request_types;
SELECT * FROM statuses;
SELECT * FROM priorities;
SELECT * FROM units;


-- РАЗДЕЛ 5. ЗАПРОСЫ ДЛЯ УВЕДОМЛЕНИЙ

-- 5.1. Уведомления для сотрудника (изменения статусов за 2 дня)
SELECT 
    r.request_number,
    s.status_name AS new_status,
    rh.changed_at,
    CONCAT('Ваша заявка №', r.request_number, ' перешла в статус "', s.status_name, '"') AS notification_text
FROM request_history rh
JOIN requests r ON rh.request_id = r.request_id
JOIN statuses s ON rh.new_status_id = s.status_id
WHERE r.author_id = :user_id
  AND rh.changed_at >= DATE_SUB(NOW(), INTERVAL 2 DAY)
ORDER BY rh.changed_at DESC;

-- 5.2. Уведомления для сотрудника (новые комментарии от обработчика)
SELECT 
    r.request_number,
    u.full_name AS author_name,
    c.comment_text,
    c.created_at,
    CONCAT(u.full_name, ' написал комментарий к заявке №', r.request_number) AS notification_text
FROM comments c
JOIN requests r ON c.request_id = r.request_id
JOIN users u ON c.author_id = u.user_id
WHERE r.author_id = :user_id
  AND c.author_id <> :user_id
  AND c.created_at >= DATE_SUB(NOW(), INTERVAL 2 DAY)
ORDER BY c.created_at DESC;

-- 5.3. Уведомления для сотрудника (отклоненные заявки с причиной)
SELECT 
    r.request_number,
    r.reject_reason,
    r.status_changed_at,
    CONCAT('Заявка №', r.request_number, ' отклонена. Причина: ', IFNULL(r.reject_reason, 'не указана')) AS notification_text
FROM requests r
JOIN statuses s ON r.status_id = s.status_id
WHERE r.author_id = :user_id
  AND s.status_name = 'Отклонена'
  AND r.status_changed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY r.status_changed_at DESC;

-- 5.4. Счетчик уведомлений для сотрудника
SELECT (
    SELECT COUNT(*) FROM request_history rh
    JOIN requests r ON rh.request_id = r.request_id
    WHERE r.author_id = :user_id AND rh.changed_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
) + (
    SELECT COUNT(*) FROM comments c
    JOIN requests r ON c.request_id = r.request_id
    WHERE r.author_id = :user_id AND c.author_id <> :user_id 
      AND c.created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
) AS total_notifications;

-- 5.5. Уведомления для обработчика (новые заявки)
SELECT 
    r.request_number,
    u.full_name AS author_name,
    d.department_name,
    t.type_name AS request_type,
    p.priority_name,
    r.created_at,
    CONCAT(u.full_name, ' создал заявку №', r.request_number, ' (', t.type_name, ')') AS notification_text
FROM requests r
JOIN users u ON r.author_id = u.user_id
JOIN departments d ON u.department_id = d.department_id
JOIN request_types t ON r.type_id = t.type_id
JOIN priorities p ON r.priority_id = p.priority_id
JOIN statuses s ON r.status_id = s.status_id
WHERE s.status_name = 'Новая'
ORDER BY p.priority_id DESC, r.created_at ASC;

-- 5.6. Уведомления для обработчика (срочные заявки)
SELECT 
    r.request_number,
    u.full_name AS author_name,
    t.type_name AS request_type,
    r.created_at,
    CONCAT('СРОЧНО: ', u.full_name, ' ждет выполнения заявки №', r.request_number) AS notification_text
FROM requests r
JOIN users u ON r.author_id = u.user_id
JOIN request_types t ON r.type_id = t.type_id
JOIN statuses s ON r.status_id = s.status_id
WHERE r.priority_id = 2
  AND s.status_name IN ('Новая', 'Принята', 'В работе')
ORDER BY r.created_at ASC;

-- 5.7. Уведомления для обработчика (низкий остаток на складе)
SELECT 
    c.item_name,
    c.stock_qty,
    c.min_threshold,
    u.unit_name,
    CONCAT('Внимание: ', c.item_name, ' осталось ', c.stock_qty, ' ', u.unit_name, 
           '. Минимальный порог: ', c.min_threshold) AS notification_text
FROM consumables c
JOIN units u ON c.unit_id = u.unit_id
WHERE c.stock_qty <= c.min_threshold
ORDER BY c.stock_qty ASC;

-- 5.8. Уведомления для обработчика (просроченные заявки > 24 часов)
SELECT 
    r.request_number,
    u.full_name AS author_name,
    r.created_at,
    TIMESTAMPDIFF(HOUR, r.created_at, NOW()) AS hours_pending,
    CONCAT('Просрочено: заявка №', r.request_number, ' висит ', 
           TIMESTAMPDIFF(HOUR, r.created_at, NOW()), ' часов без реакции') AS notification_text
FROM requests r
JOIN users u ON r.author_id = u.user_id
JOIN statuses s ON r.status_id = s.status_id
WHERE s.status_name = 'Новая'
  AND TIMESTAMPDIFF(HOUR, r.created_at, NOW()) > 24
ORDER BY r.created_at ASC;

-- 5.9. Счетчик уведомлений для обработчика
SELECT (
    SELECT COUNT(*) FROM requests r
    JOIN statuses s ON r.status_id = s.status_id
    WHERE s.status_name = 'Новая'
) + (
    SELECT COUNT(*) FROM consumables
    WHERE stock_qty <= min_threshold
) AS total_notifications;










