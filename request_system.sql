-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1:3306
-- Время создания: Ноя 09 2026 г., 23:08
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
(1, 'Бумага А4', 2, 20, 5),
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
  `cartridge_yield` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `equipment`
--

INSERT INTO `equipment` (`equipment_id`, `equipment_type`, `model_name`, `inventory_number`, `cabinet`, `cartridge_yield`) VALUES
(1, 'Принтер', 'HP LaserJet 1010', 'INV-001', '310', 2000),
(2, 'Сканер', 'Canon CanoScan', 'INV-002', '214', 0);

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
-- Структура таблицы `requests`
--

CREATE TABLE `requests` (
  `request_id` int NOT NULL,
  `request_number` varchar(20) NOT NULL,
  `author_id` int NOT NULL,
  `type_id` int NOT NULL,
  `status_id` int NOT NULL,
  `priority_id` int NOT NULL,
  `equipment_id` int DEFAULT NULL,
  `consumable_id` int DEFAULT NULL,
  `quantity` int NOT NULL,
  `comment` text,
  `reject_reason` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
  MODIFY `comment_id` int NOT NULL AUTO_INCREMENT;

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
  MODIFY `request_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `request_history`
--
ALTER TABLE `request_history`
  MODIFY `history_id` int NOT NULL AUTO_INCREMENT;

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
  MODIFY `user_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

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
