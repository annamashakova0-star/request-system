-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1:3306
-- Время создания: Ноя 24 2026 г., 23:10
-- Версия сервера: 8.0.30
-- Версия PHP: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `request_system`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`%` PROCEDURE `change_request_status` (IN `p_request_id` INT, IN `p_user_id` INT, IN `p_new_status_id` INT, IN `p_comment` TEXT)   BEGIN
    DECLARE v_old_status_id INT;
    
    SELECT status_id INTO v_old_status_id FROM requests WHERE request_id = p_request_id;
    
    UPDATE requests 
    SET status_id = p_new_status_id, 
        status_changed_at = NOW()
    WHERE request_id = p_request_id;
    
    INSERT INTO request_history (request_id, changed_by_id, old_status_id, new_status_id, comment, changed_at)
    VALUES (p_request_id, p_user_id, v_old_status_id, p_new_status_id, p_comment, NOW());
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `write_off_consumable` (IN `p_request_id` INT, IN `p_consumable_id` INT, IN `p_quantity` INT)   BEGIN
    UPDATE consumables 
    SET stock_qty = stock_qty - p_quantity 
    WHERE consumable_id = p_consumable_id;
    
    IF (SELECT stock_qty FROM consumables WHERE consumable_id = p_consumable_id) < 
       (SELECT min_threshold FROM consumables WHERE consumable_id = p_consumable_id) THEN
        SELECT CONCAT('Внимание! Остаток ', p_consumable_id, ' ниже порога. Пора заказывать!') AS Alert;
    END IF;
END$$

--
-- Функции
--
CREATE DEFINER=`root`@`%` FUNCTION `check_stock` (`p_consumable_id` INT, `p_qty` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE v_stock INT;
    SELECT stock_qty INTO v_stock FROM consumables WHERE consumable_id = p_consumable_id;
    IF v_stock >= p_qty THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_avg_completion_time` (`p_days` INT) RETURNS DECIMAL(10,2) READS SQL DATA BEGIN
    DECLARE v_avg DECIMAL(10,2);
    SELECT AVG(TIMESTAMPDIFF(HOUR, r.created_at, r.status_changed_at)) 
    INTO v_avg
    FROM requests r
    WHERE r.status_id = 4
      AND r.created_at >= DATE_SUB(NOW(), INTERVAL p_days DAY);
    RETURN IFNULL(v_avg, 0);
END$$

CREATE DEFINER=`root`@`%` FUNCTION `get_completion_rate` (`p_days` INT) RETURNS DECIMAL(5,2) READS SQL DATA BEGIN
    DECLARE v_total INT;
    DECLARE v_completed INT;
    
    SELECT COUNT(*) INTO v_total FROM requests 
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL p_days DAY);
    
    SELECT COUNT(*) INTO v_completed FROM requests 
    WHERE status_id = 4 
      AND created_at >= DATE_SUB(NOW(), INTERVAL p_days DAY);
    
    IF v_total = 0 THEN RETURN 0; END IF;
    RETURN ROUND((v_completed * 100.0) / v_total, 2);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `branches`
--

CREATE TABLE `branches` (
  `branch_id` int NOT NULL,
  `branch_name` varchar(100) NOT NULL,
  `full_address` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `branches`
--

INSERT INTO `branches` (`branch_id`, `branch_name`, `full_address`) VALUES
(1, 'Головной офис', 'г. Череповец, ул. Ленина, д. 15'),
(2, 'Московский филиал', 'г. Москва, ул. Тверская, д. 8');

-- --------------------------------------------------------

--
-- Структура таблицы `comments`
--

CREATE TABLE `comments` (
  `comment_id` int NOT NULL,
  `request_id` int NOT NULL,
  `author_id` int NOT NULL,
  `status_id` int NOT NULL,
  `comment_text` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `comments`
--

INSERT INTO `comments` (`comment_id`, `request_id`, `author_id`, `status_id`, `comment_text`, `created_at`) VALUES
(1, 1, 1, 1, 'Очень нужна бумага, отчет горит!', '2026-11-21 19:05:46'),
(2, 2, 5, 2, 'Принял заявку, картридж есть на складе', '2026-11-23 19:05:46'),
(3, 2, 2, 2, 'Спасибо, жду!', '2026-11-23 23:05:46'),
(4, 3, 5, 3, 'Смотрю принтер, похоже замятие бумаги', '2026-11-23 19:05:46'),
(5, 3, 3, 3, 'Хорошо, буду ждать', '2026-11-23 23:05:46'),
(6, 4, 6, 4, 'Бумага выдана, заявка закрыта', '2026-11-21 19:05:46'),
(7, 5, 5, 4, 'Сканер починен, заменил шлейф', '2026-11-20 19:05:46'),
(8, 6, 5, 5, 'Мышки нет, заказали новую', '2026-11-21 19:05:46');

-- --------------------------------------------------------

--
-- Структура таблицы `consumables`
--

CREATE TABLE `consumables` (
  `consumable_id` int NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `unit_id` int NOT NULL,
  `stock_qty` int NOT NULL DEFAULT '0',
  `min_threshold` int NOT NULL DEFAULT '5'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `consumables`
--

INSERT INTO `consumables` (`consumable_id`, `item_name`, `unit_id`, `stock_qty`, `min_threshold`) VALUES
(1, 'Бумага А4', 2, 7, 5),
(2, 'Картридж HP Q2612A', 1, 5, 2);

-- --------------------------------------------------------

--
-- Структура таблицы `departments`
--

CREATE TABLE `departments` (
  `department_id` int NOT NULL,
  `department_name` varchar(100) NOT NULL,
  `location` varchar(100) NOT NULL,
  `branch_id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `departments`
--

INSERT INTO `departments` (`department_id`, `department_name`, `location`, `branch_id`) VALUES
(1, 'Отдел разработки', '3 этаж, каб. 301', 1),
(2, 'Бухгалтерия', '2 этаж, каб. 205', 1),
(3, 'IT-отдел', '4 этаж, каб. 410', 2);

-- --------------------------------------------------------

--
-- Структура таблицы `equipment`
--

CREATE TABLE `equipment` (
  `equipment_id` int NOT NULL,
  `equipment_type` varchar(30) NOT NULL,
  `model_name` varchar(100) NOT NULL,
  `inventory_number` varchar(50) NOT NULL,
  `cabinet` varchar(20) NOT NULL,
  `cartridge_yield` int DEFAULT '0',
  `status` varchar(30) NOT NULL DEFAULT 'В работе'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `equipment`
--

INSERT INTO `equipment` (`equipment_id`, `equipment_type`, `model_name`, `inventory_number`, `cabinet`, `cartridge_yield`, `status`) VALUES
(1, 'Принтер', 'HP LaserJet 1010', 'INV-001', '310', 2000, 'На ремонте'),
(2, 'Сканер', 'Canon CanoScan', 'INV-002', '214', 0, 'На ремонте');

-- --------------------------------------------------------

--
-- Структура таблицы `priorities`
--

CREATE TABLE `priorities` (
  `priority_id` int NOT NULL,
  `priority_name` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `priorities`
--

INSERT INTO `priorities` (`priority_id`, `priority_name`) VALUES
(1, 'Обычная'),
(2, 'Срочная');

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `report_1_sla`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `report_1_sla` (
`report_date` date
,`total_requests` bigint
,`avg_hours_to_accept` decimal(23,2)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `report_2_departments`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `report_2_departments` (
`department_name` varchar(100)
,`total_requests` bigint
,`repair_requests` decimal(23,0)
,`consumable_requests` decimal(23,0)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `report_3_statuses`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `report_3_statuses` (
`status_name` varchar(50)
,`request_count` bigint
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `report_4_equipment`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `report_4_equipment` (
`model_name` varchar(100)
,`inventory_number` varchar(50)
,`repair_count` bigint
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `report_5_consumables`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `report_5_consumables` (
`item_name` varchar(100)
,`total_consumed` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `report_6_low_stock`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `report_6_low_stock` (
`item_name` varchar(100)
,`stock_qty` int
,`min_threshold` int
,`unit_name` varchar(20)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `report_7_handlers`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `report_7_handlers` (
`handler_name` varchar(150)
,`processed_requests` bigint
,`avg_hours_per_request` decimal(23,2)
);

-- --------------------------------------------------------

--
-- Структура таблицы `requests`
--

CREATE TABLE `requests` (
  `request_id` int NOT NULL,
  `request_number` varchar(20) NOT NULL,
  `author_id` int NOT NULL,
  `type_id` int NOT NULL,
  `status_id` int NOT NULL,
  `priority_id` int NOT NULL,
  `equipment_id` int DEFAULT '0',
  `consumable_id` int DEFAULT '0',
  `quantity` int NOT NULL DEFAULT '0',
  `description` text,
  `reject_reason` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status_changed_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `requests`
--

INSERT INTO `requests` (`request_id`, `request_number`, `author_id`, `type_id`, `status_id`, `priority_id`, `equipment_id`, `consumable_id`, `quantity`, `description`, `reject_reason`, `created_at`, `status_changed_at`) VALUES
(1, 'REQ-001', 1, 1, 3, 1, NULL, 1, 2, 'Нужна бумага А4 для отчетов', NULL, '2026-11-20 07:00:00', '2026-11-24 19:36:56'),
(2, 'REQ-002', 2, 2, 2, 1, NULL, 2, 1, 'Картридж заканчивается', NULL, '2026-11-20 07:00:00', NULL),
(3, 'REQ-003', 3, 3, 3, 2, 1, NULL, 1, 'Принтер не печатает, мигает красный индикатор', NULL, '2026-11-20 07:00:00', NULL),
(4, 'REQ-004', 4, 1, 4, 1, NULL, 1, 3, 'Бумага для бухгалтерии', NULL, '2026-11-20 07:00:00', '2026-11-21 12:00:00'),
(5, 'REQ-005', 1, 4, 4, 1, 2, NULL, 1, 'Сканер не сканирует', NULL, '2026-11-20 07:00:00', '2026-11-21 12:00:00'),
(6, 'REQ-006', 2, 5, 5, 1, NULL, NULL, 1, 'Нужна новая мышка', NULL, '2026-11-20 07:00:00', NULL),
(7, 'REQ-007', 3, 2, 6, 1, NULL, 2, 1, 'Картридж для принтера в 310', NULL, '2026-11-20 07:00:00', NULL),
(8, 'REQ-008', 4, 3, 1, 2, 1, NULL, 1, 'СРОЧНО! Принтер зажевал бумагу', NULL, '2026-11-20 07:00:00', NULL);

--
-- Триггеры `requests`
--
DELIMITER $$
CREATE TRIGGER `trg_auto_write_off` AFTER UPDATE ON `requests` FOR EACH ROW BEGIN
    DECLARE v_status_name VARCHAR(50);
    DECLARE v_type_name VARCHAR(100);
    
    SELECT status_name INTO v_status_name FROM statuses WHERE status_id = NEW.status_id;
    SELECT type_name INTO v_type_name FROM request_types WHERE type_id = NEW.type_id;
    
    IF v_status_name = 'Выполнена' 
       AND v_type_name IN ('Бумага', 'Картридж') 
       AND NEW.consumable_id > 0 THEN
        
        UPDATE consumables 
        SET stock_qty = stock_qty - NEW.quantity 
        WHERE consumable_id = NEW.consumable_id;
        
        IF NEW.equipment_id > 0 THEN
            UPDATE equipment SET status = 'В работе' WHERE equipment_id = NEW.equipment_id;
        END IF;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_equipment_status_update` AFTER INSERT ON `requests` FOR EACH ROW BEGIN
    DECLARE v_type_name VARCHAR(100);
    SELECT type_name INTO v_type_name FROM request_types WHERE type_id = NEW.type_id;
    
    IF v_type_name LIKE 'Ремонт%' AND NEW.equipment_id > 0 THEN
        UPDATE equipment SET status = 'На ремонте' WHERE equipment_id = NEW.equipment_id;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_status_date` BEFORE UPDATE ON `requests` FOR EACH ROW BEGIN
    IF OLD.status_id <> NEW.status_id THEN
        SET NEW.status_changed_at = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `request_history`
--

CREATE TABLE `request_history` (
  `history_id` int NOT NULL,
  `request_id` int NOT NULL,
  `changed_by_id` int NOT NULL,
  `old_status_id` int DEFAULT NULL,
  `new_status_id` int NOT NULL,
  `comment` text,
  `changed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `request_history`
--

INSERT INTO `request_history` (`history_id`, `request_id`, `changed_by_id`, `old_status_id`, `new_status_id`, `comment`, `changed_at`) VALUES
(1, 2, 5, 1, 2, 'Взял в работу', '2026-11-23 19:05:46'),
(2, 3, 5, 1, 2, 'Принял заявку', '2026-11-23 19:05:46'),
(3, 3, 5, 2, 3, 'Взял в работу', '2026-11-23 19:05:46'),
(4, 4, 6, 1, 2, 'Принял', '2026-11-20 19:05:46'),
(5, 4, 6, 2, 3, 'В работе', '2026-11-20 19:05:46'),
(6, 4, 6, 3, 4, 'Выдал бумагу', '2026-11-21 19:05:46'),
(7, 5, 5, 1, 4, 'Починил сканер', '2026-11-20 19:05:46'),
(8, 6, 5, 1, 5, 'Нет на складе', '2026-11-21 19:05:46'),
(9, 1, 2, 1, 3, 'Взял в работу', '2026-11-24 19:36:56');

--
-- Триггеры `request_history`
--
DELIMITER $$
CREATE TRIGGER `trg_history_timestamp` BEFORE INSERT ON `request_history` FOR EACH ROW BEGIN
    IF NEW.changed_at IS NULL THEN
        SET NEW.changed_at = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `request_types`
--

CREATE TABLE `request_types` (
  `type_id` int NOT NULL,
  `type_name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `request_types`
--

INSERT INTO `request_types` (`type_id`, `type_name`) VALUES
(1, 'Бумага'),
(2, 'Картридж'),
(5, 'Прочее'),
(3, 'Ремонт принтера'),
(4, 'Ремонт сканера');

-- --------------------------------------------------------

--
-- Структура таблицы `roles`
--

CREATE TABLE `roles` (
  `role_id` int NOT NULL,
  `role_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `roles`
--

INSERT INTO `roles` (`role_id`, `role_name`) VALUES
(3, 'Администратор'),
(2, 'Обработчик'),
(1, 'Сотрудник');

-- --------------------------------------------------------

--
-- Структура таблицы `statuses`
--

CREATE TABLE `statuses` (
  `status_id` int NOT NULL,
  `status_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `statuses`
--

INSERT INTO `statuses` (`status_id`, `status_name`) VALUES
(3, 'В работе'),
(4, 'Выполнена'),
(1, 'Новая'),
(5, 'Отклонена'),
(6, 'Отменена'),
(2, 'Принята');

-- --------------------------------------------------------

--
-- Структура таблицы `units`
--

CREATE TABLE `units` (
  `unit_id` int NOT NULL,
  `unit_name` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `units`
--

INSERT INTO `units` (`unit_id`, `unit_name`) VALUES
(2, 'пачка'),
(3, 'упаковка'),
(1, 'штука');

-- --------------------------------------------------------

--
-- Структура таблицы `users`
--

CREATE TABLE `users` (
  `user_id` int NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `login` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role_id` int NOT NULL,
  `department_id` int NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `phone` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `users`
--

INSERT INTO `users` (`user_id`, `full_name`, `login`, `password_hash`, `role_id`, `department_id`, `is_active`, `created_at`, `phone`) VALUES
(1, 'Иванов Иван Иванович', 'ivanov', '$2y$10$8K1p/a0dL1LXMIgoEDFrwOfgqw2.wJ1Y.T.wJ1Y.T.wJ1Y.T.wJ1Y.T', 1, 1, 1, '2026-11-24 19:05:46', '+7 (999) 123-45-67'),
(2, 'Петрова Мария Сергеевна', 'petrova', '$2y$10$8K1p/a0dL1LXMIgoEDFrwOfgqw2.wJ1Y.T.wJ1Y.T.wJ1Y.T.wJ1Y.T', 1, 2, 1, '2026-11-24 19:05:46', '+7 (999) 234-56-78'),
(3, 'Сидоров Алексей Николаевич', 'sidorov', '$2y$10$8K1p/a0dL1LXMIgoEDFrwOfgqw2.wJ1Y.T.wJ1Y.T.wJ1Y.T.wJ1Y.T', 1, 1, 1, '2026-11-24 19:05:46', '+7 (999) 345-67-89'),
(4, 'Кузнецова Ольга Дмитриевна', 'kuznetsova', '$2y$10$8K1p/a0dL1LXMIgoEDFrwOfgqw2.wJ1Y.T.wJ1Y.T.wJ1Y.T.wJ1Y.T', 1, 3, 1, '2026-11-24 19:05:46', '+7 (999) 456-78-90'),
(5, 'Петров Петр Петрович', 'petrov', '$2y$10$8K1p/a0dL1LXMIgoEDFrwOfgqw2.wJ1Y.T.wJ1Y.T.wJ1Y.T.wJ1Y.T', 2, 3, 1, '2026-11-24 19:05:46', '+7 (999) 567-89-01'),
(6, 'Смирнов Дмитрий Андреевич', 'smirnov', '$2y$10$8K1p/a0dL1LXMIgoEDFrwOfgqw2.wJ1Y.T.wJ1Y.T.wJ1Y.T.wJ1Y.T', 2, 3, 1, '2026-11-24 19:05:46', '+7 (999) 678-90-12'),
(7, 'Сидорова Анна Викторовна', 'admin', '$2y$10$8K1p/a0dL1LXMIgoEDFrwOfgqw2.wJ1Y.T.wJ1Y.T.wJ1Y.T.wJ1Y.T', 3, 3, 1, '2026-11-24 19:05:46', '+7 (999) 789-01-23');

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_consumables_by_dept`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_consumables_by_dept` (
`department_name` varchar(100)
,`item_name` varchar(100)
,`total_consumed` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_full_requests`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_full_requests` (
`request_id` int
,`request_number` varchar(20)
,`author_name` varchar(150)
,`author_phone` varchar(20)
,`department_name` varchar(100)
,`branch_name` varchar(100)
,`request_type` varchar(100)
,`current_status` varchar(50)
,`priority_name` varchar(30)
,`quantity` int
,`description` text
,`created_at` timestamp
,`status_changed_at` timestamp
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_problem_equipment`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_problem_equipment` (
`equipment_id` int
,`model_name` varchar(100)
,`inventory_number` varchar(50)
,`cabinet` varchar(20)
,`repair_count` bigint
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sla_analytics`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sla_analytics` (
`request_id` int
,`created_at` timestamp
,`first_reaction_time` timestamp
,`hours_to_accept` bigint
);

-- --------------------------------------------------------

--
-- Структура для представления `report_1_sla`
--
DROP TABLE IF EXISTS `report_1_sla`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `report_1_sla`  AS SELECT cast(`r`.`created_at` as date) AS `report_date`, count(0) AS `total_requests`, round(avg(timestampdiff(HOUR,`r`.`created_at`,(select min(`request_history`.`changed_at`) from `request_history` where ((`request_history`.`request_id` = `r`.`request_id`) and (`request_history`.`new_status_id` = 2))))),2) AS `avg_hours_to_accept` FROM `requests` AS `r` WHERE (`r`.`created_at` >= (now() - interval 30 day)) GROUP BY cast(`r`.`created_at` as date) ORDER BY `report_date` AS `DESCdesc` ASC  ;

-- --------------------------------------------------------

--
-- Структура для представления `report_2_departments`
--
DROP TABLE IF EXISTS `report_2_departments`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `report_2_departments`  AS SELECT `d`.`department_name` AS `department_name`, count(`r`.`request_id`) AS `total_requests`, sum((case when (`t`.`type_name` like 'Ремонт%') then 1 else 0 end)) AS `repair_requests`, sum((case when (`t`.`type_name` in ('Бумага','Картридж')) then 1 else 0 end)) AS `consumable_requests` FROM (((`requests` `r` join `users` `u` on((`r`.`author_id` = `u`.`user_id`))) join `departments` `d` on((`u`.`department_id` = `d`.`department_id`))) join `request_types` `t` on((`r`.`type_id` = `t`.`type_id`))) GROUP BY `d`.`department_name` ORDER BY `total_requests` AS `DESCdesc` ASC  ;

-- --------------------------------------------------------

--
-- Структура для представления `report_3_statuses`
--
DROP TABLE IF EXISTS `report_3_statuses`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `report_3_statuses`  AS SELECT `s`.`status_name` AS `status_name`, count(`r`.`request_id`) AS `request_count` FROM (`requests` `r` join `statuses` `s` on((`r`.`status_id` = `s`.`status_id`))) GROUP BY `s`.`status_name` ORDER BY `request_count` AS `DESCdesc` ASC  ;

-- --------------------------------------------------------

--
-- Структура для представления `report_4_equipment`
--
DROP TABLE IF EXISTS `report_4_equipment`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `report_4_equipment`  AS SELECT `e`.`model_name` AS `model_name`, `e`.`inventory_number` AS `inventory_number`, count(`r`.`request_id`) AS `repair_count` FROM ((`equipment` `e` join `requests` `r` on((`e`.`equipment_id` = `r`.`equipment_id`))) join `request_types` `t` on((`r`.`type_id` = `t`.`type_id`))) WHERE (`t`.`type_name` like 'Ремонт%') GROUP BY `e`.`equipment_id`, `e`.`model_name`, `e`.`inventory_number` ORDER BY `repair_count` AS `DESCdesc` ASC  ;

-- --------------------------------------------------------

--
-- Структура для представления `report_5_consumables`
--
DROP TABLE IF EXISTS `report_5_consumables`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `report_5_consumables`  AS SELECT `c`.`item_name` AS `item_name`, sum(`r`.`quantity`) AS `total_consumed` FROM ((`requests` `r` join `consumables` `c` on((`r`.`consumable_id` = `c`.`consumable_id`))) join `statuses` `s` on((`r`.`status_id` = `s`.`status_id`))) WHERE (`s`.`status_name` = 'Выполнена') GROUP BY `c`.`item_name``item_name`  ;

-- --------------------------------------------------------

--
-- Структура для представления `report_6_low_stock`
--
DROP TABLE IF EXISTS `report_6_low_stock`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `report_6_low_stock`  AS SELECT `c`.`item_name` AS `item_name`, `c`.`stock_qty` AS `stock_qty`, `c`.`min_threshold` AS `min_threshold`, `u`.`unit_name` AS `unit_name` FROM (`consumables` `c` join `units` `u` on((`c`.`unit_id` = `u`.`unit_id`))) WHERE (`c`.`stock_qty` <= `c`.`min_threshold`)  ;

-- --------------------------------------------------------

--
-- Структура для представления `report_7_handlers`
--
DROP TABLE IF EXISTS `report_7_handlers`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `report_7_handlers`  AS SELECT `u`.`full_name` AS `handler_name`, count(distinct `rh`.`request_id`) AS `processed_requests`, round(avg(timestampdiff(HOUR,`r`.`created_at`,`rh`.`changed_at`)),2) AS `avg_hours_per_request` FROM ((`request_history` `rh` join `users` `u` on((`rh`.`changed_by_id` = `u`.`user_id`))) join `requests` `r` on((`rh`.`request_id` = `r`.`request_id`))) WHERE (`rh`.`new_status_id` = 4) GROUP BY `u`.`user_id`, `u`.`full_name` ORDER BY `processed_requests` AS `DESCdesc` ASC  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_consumables_by_dept`
--
DROP TABLE IF EXISTS `view_consumables_by_dept`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_consumables_by_dept`  AS SELECT `d`.`department_name` AS `department_name`, `c`.`item_name` AS `item_name`, sum(`r`.`quantity`) AS `total_consumed` FROM ((((`requests` `r` join `users` `u` on((`r`.`author_id` = `u`.`user_id`))) join `departments` `d` on((`u`.`department_id` = `d`.`department_id`))) join `consumables` `c` on((`r`.`consumable_id` = `c`.`consumable_id`))) join `statuses` `s` on((`r`.`status_id` = `s`.`status_id`))) WHERE (`s`.`status_name` = 'Выполнена') GROUP BY `d`.`department_name`, `c`.`item_name``item_name`  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_full_requests`
--
DROP TABLE IF EXISTS `view_full_requests`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_full_requests`  AS SELECT `r`.`request_id` AS `request_id`, `r`.`request_number` AS `request_number`, `u`.`full_name` AS `author_name`, `u`.`phone` AS `author_phone`, `d`.`department_name` AS `department_name`, `b`.`branch_name` AS `branch_name`, `t`.`type_name` AS `request_type`, `s`.`status_name` AS `current_status`, `p`.`priority_name` AS `priority_name`, `r`.`quantity` AS `quantity`, `r`.`description` AS `description`, `r`.`created_at` AS `created_at`, `r`.`status_changed_at` AS `status_changed_at` FROM ((((((`requests` `r` join `users` `u` on((`r`.`author_id` = `u`.`user_id`))) join `departments` `d` on((`u`.`department_id` = `d`.`department_id`))) join `branches` `b` on((`d`.`branch_id` = `b`.`branch_id`))) join `request_types` `t` on((`r`.`type_id` = `t`.`type_id`))) join `statuses` `s` on((`r`.`status_id` = `s`.`status_id`))) join `priorities` `p` on((`r`.`priority_id` = `p`.`priority_id`)))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_problem_equipment`
--
DROP TABLE IF EXISTS `view_problem_equipment`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_problem_equipment`  AS SELECT `e`.`equipment_id` AS `equipment_id`, `e`.`model_name` AS `model_name`, `e`.`inventory_number` AS `inventory_number`, `e`.`cabinet` AS `cabinet`, count(`r`.`request_id`) AS `repair_count` FROM ((`equipment` `e` join `requests` `r` on((`e`.`equipment_id` = `r`.`equipment_id`))) join `request_types` `t` on((`r`.`type_id` = `t`.`type_id`))) WHERE (`t`.`type_name` like 'Ремонт%') GROUP BY `e`.`equipment_id`, `e`.`model_name`, `e`.`inventory_number`, `e`.`cabinet` ORDER BY `repair_count` AS `DESCdesc` ASC  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sla_analytics`
--
DROP TABLE IF EXISTS `view_sla_analytics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sla_analytics`  AS SELECT `r`.`request_id` AS `request_id`, `r`.`created_at` AS `created_at`, min(`h`.`changed_at`) AS `first_reaction_time`, timestampdiff(HOUR,`r`.`created_at`,min(`h`.`changed_at`)) AS `hours_to_accept` FROM (`requests` `r` left join `request_history` `h` on(((`r`.`request_id` = `h`.`request_id`) and (`h`.`new_status_id` = 2)))) GROUP BY `r`.`request_id`, `r`.`created_at``created_at`  ;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `branches`
--
ALTER TABLE `branches`
  ADD PRIMARY KEY (`branch_id`);

--
-- Индексы таблицы `comments`
--
ALTER TABLE `comments`
  ADD PRIMARY KEY (`comment_id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `author_id` (`author_id`),
  ADD KEY `status_id` (`status_id`);

--
-- Индексы таблицы `consumables`
--
ALTER TABLE `consumables`
  ADD PRIMARY KEY (`consumable_id`),
  ADD UNIQUE KEY `item_name` (`item_name`),
  ADD KEY `unit_id` (`unit_id`);

--
-- Индексы таблицы `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`department_id`),
  ADD KEY `branch_id` (`branch_id`);

--
-- Индексы таблицы `equipment`
--
ALTER TABLE `equipment`
  ADD PRIMARY KEY (`equipment_id`),
  ADD UNIQUE KEY `inventory_number` (`inventory_number`);

--
-- Индексы таблицы `priorities`
--
ALTER TABLE `priorities`
  ADD PRIMARY KEY (`priority_id`),
  ADD UNIQUE KEY `priority_name` (`priority_name`);

--
-- Индексы таблицы `requests`
--
ALTER TABLE `requests`
  ADD PRIMARY KEY (`request_id`),
  ADD UNIQUE KEY `request_number` (`request_number`),
  ADD KEY `author_id` (`author_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `status_id` (`status_id`),
  ADD KEY `priority_id` (`priority_id`),
  ADD KEY `equipment_id` (`equipment_id`),
  ADD KEY `consumable_id` (`consumable_id`);

--
-- Индексы таблицы `request_history`
--
ALTER TABLE `request_history`
  ADD PRIMARY KEY (`history_id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `changed_by_id` (`changed_by_id`),
  ADD KEY `old_status_id` (`old_status_id`),
  ADD KEY `new_status_id` (`new_status_id`);

--
-- Индексы таблицы `request_types`
--
ALTER TABLE `request_types`
  ADD PRIMARY KEY (`type_id`),
  ADD UNIQUE KEY `type_name` (`type_name`);

--
-- Индексы таблицы `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`role_id`),
  ADD UNIQUE KEY `role_name` (`role_name`);

--
-- Индексы таблицы `statuses`
--
ALTER TABLE `statuses`
  ADD PRIMARY KEY (`status_id`),
  ADD UNIQUE KEY `status_name` (`status_name`);

--
-- Индексы таблицы `units`
--
ALTER TABLE `units`
  ADD PRIMARY KEY (`unit_id`),
  ADD UNIQUE KEY `unit_name` (`unit_name`);

--
-- Индексы таблицы `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `login` (`login`),
  ADD KEY `role_id` (`role_id`),
  ADD KEY `department_id` (`department_id`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `branches`
--
ALTER TABLE `branches`
  MODIFY `branch_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT для таблицы `comments`
--
ALTER TABLE `comments`
  MODIFY `comment_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `consumables`
--
ALTER TABLE `consumables`
  MODIFY `consumable_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT для таблицы `departments`
--
ALTER TABLE `departments`
  MODIFY `department_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `equipment`
--
ALTER TABLE `equipment`
  MODIFY `equipment_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT для таблицы `priorities`
--
ALTER TABLE `priorities`
  MODIFY `priority_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT для таблицы `requests`
--
ALTER TABLE `requests`
  MODIFY `request_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `request_history`
--
ALTER TABLE `request_history`
  MODIFY `history_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT для таблицы `request_types`
--
ALTER TABLE `request_types`
  MODIFY `type_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT для таблицы `roles`
--
ALTER TABLE `roles`
  MODIFY `role_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `statuses`
--
ALTER TABLE `statuses`
  MODIFY `status_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT для таблицы `units`
--
ALTER TABLE `units`
  MODIFY `unit_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `comments`
--
ALTER TABLE `comments`
  ADD CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `requests` (`request_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`author_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `comments_ibfk_3` FOREIGN KEY (`status_id`) REFERENCES `statuses` (`status_id`);

--
-- Ограничения внешнего ключа таблицы `consumables`
--
ALTER TABLE `consumables`
  ADD CONSTRAINT `consumables_ibfk_1` FOREIGN KEY (`unit_id`) REFERENCES `units` (`unit_id`);

--
-- Ограничения внешнего ключа таблицы `departments`
--
ALTER TABLE `departments`
  ADD CONSTRAINT `departments_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`branch_id`);

--
-- Ограничения внешнего ключа таблицы `requests`
--
ALTER TABLE `requests`
  ADD CONSTRAINT `requests_ibfk_1` FOREIGN KEY (`author_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `requests_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `request_types` (`type_id`),
  ADD CONSTRAINT `requests_ibfk_3` FOREIGN KEY (`status_id`) REFERENCES `statuses` (`status_id`),
  ADD CONSTRAINT `requests_ibfk_4` FOREIGN KEY (`priority_id`) REFERENCES `priorities` (`priority_id`),
  ADD CONSTRAINT `requests_ibfk_5` FOREIGN KEY (`equipment_id`) REFERENCES `equipment` (`equipment_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `requests_ibfk_6` FOREIGN KEY (`consumable_id`) REFERENCES `consumables` (`consumable_id`) ON DELETE SET NULL;

--
-- Ограничения внешнего ключа таблицы `request_history`
--
ALTER TABLE `request_history`
  ADD CONSTRAINT `request_history_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `requests` (`request_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `request_history_ibfk_2` FOREIGN KEY (`changed_by_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `request_history_ibfk_3` FOREIGN KEY (`old_status_id`) REFERENCES `statuses` (`status_id`),
  ADD CONSTRAINT `request_history_ibfk_4` FOREIGN KEY (`new_status_id`) REFERENCES `statuses` (`status_id`);

--
-- Ограничения внешнего ключа таблицы `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`),
  ADD CONSTRAINT `users_ibfk_2` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
