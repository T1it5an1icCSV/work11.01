-- =====================================================
-- SQL скрипт для создания базы данных spring666DB
-- Интернет магазин по продаже спортивного оборудования
-- =====================================================

-- Создание базы данных (выполнить отдельно, если БД еще не создана)
-- CREATE DATABASE spring666DB;

-- Подключение к базе данных
-- \c spring666DB;

-- =====================================================
-- 1. Таблица ролей пользователей
-- =====================================================
CREATE TABLE IF NOT EXISTS user_roles (
    id_role BIGSERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    permissions JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_roles IS 'Роли пользователей системы';
COMMENT ON COLUMN user_roles.role_name IS 'Название роли (ADMIN, MANAGER, CUSTOMER)';
COMMENT ON COLUMN user_roles.permissions IS 'Права доступа в формате JSON';

-- =====================================================
-- 2. Таблица пользователей системы
-- =====================================================
CREATE TABLE IF NOT EXISTS system_users (
    id_user BIGSERIAL PRIMARY KEY,
    user_name VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    role_id BIGINT,
    email_verified BOOLEAN DEFAULT FALSE,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    last_login TIMESTAMP,
    password_changed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (role_id) REFERENCES user_roles(id_role) ON DELETE SET NULL
);

COMMENT ON TABLE system_users IS 'Пользователи системы';
COMMENT ON COLUMN system_users.password_hash IS 'Хеш пароля пользователя';
COMMENT ON COLUMN system_users.role_id IS 'Ссылка на роль пользователя';

-- Создание индексов для таблицы пользователей
CREATE INDEX IF NOT EXISTS idx_system_users_role_id ON system_users(role_id);
CREATE INDEX IF NOT EXISTS idx_system_users_email ON system_users(email);
CREATE INDEX IF NOT EXISTS idx_system_users_user_name ON system_users(user_name);

-- =====================================================
-- 3. Таблица категорий товаров
-- =====================================================
CREATE TABLE IF NOT EXISTS product_categories (
    id_product_categories BIGSERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    category_description TEXT,
    parent_category_id BIGINT,
    category_slug VARCHAR(100) UNIQUE,
    display_order INTEGER DEFAULT 0,
    product_categories_is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES product_categories(id_product_categories) ON DELETE SET NULL
);

COMMENT ON TABLE product_categories IS 'Категории товаров';
COMMENT ON COLUMN product_categories.parent_category_id IS 'Ссылка на родительскую категорию для иерархии';

-- Создание индексов для таблицы категорий
CREATE INDEX IF NOT EXISTS idx_product_categories_parent ON product_categories(parent_category_id);

-- =====================================================
-- 4. Таблица брендов товаров
-- =====================================================
CREATE TABLE IF NOT EXISTS product_brands (
    id_product_brands BIGSERIAL PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    brand_description TEXT,
    country_of_origin VARCHAR(50),
    website_url VARCHAR(255),
    logo_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE product_brands IS 'Бренды товаров';

-- =====================================================
-- 5. Таблица товаров
-- =====================================================
CREATE TABLE IF NOT EXISTS inventory_products (
    id_inventory_products BIGSERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    product_description TEXT,
    base_price NUMERIC(10, 2) NOT NULL,
    current_stock INTEGER NOT NULL DEFAULT 0,
    min_stock_level INTEGER DEFAULT 5,
    category_id BIGINT,
    brand_id BIGINT,
    product_sku VARCHAR(100) NOT NULL UNIQUE,
    weight_kg NUMERIC(8, 3),
    dimensions_cm VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES product_categories(id_product_categories) ON DELETE SET NULL,
    FOREIGN KEY (brand_id) REFERENCES product_brands(id_product_brands) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES system_users(id_user) ON DELETE SET NULL
);

COMMENT ON TABLE inventory_products IS 'Товары в каталоге';
COMMENT ON COLUMN inventory_products.base_price IS 'Базовая цена товара';
COMMENT ON COLUMN inventory_products.current_stock IS 'Текущее количество товара на складе';
COMMENT ON COLUMN inventory_products.min_stock_level IS 'Минимальный уровень запаса';

-- Создание индексов для таблицы товаров
CREATE INDEX IF NOT EXISTS idx_inventory_products_category ON inventory_products(category_id);
CREATE INDEX IF NOT EXISTS idx_inventory_products_brand ON inventory_products(brand_id);
CREATE INDEX IF NOT EXISTS idx_inventory_products_sku ON inventory_products(product_sku);
CREATE INDEX IF NOT EXISTS idx_inventory_products_active ON inventory_products(is_active);

-- =====================================================
-- 6. Таблица медиафайлов товаров
-- =====================================================
CREATE TABLE IF NOT EXISTS product_media (
    id_product_media BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    media_url VARCHAR(500) NOT NULL,
    media_type VARCHAR(20) DEFAULT 'image',
    alt_text VARCHAR(200),
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES inventory_products(id_inventory_products) ON DELETE CASCADE
);

COMMENT ON TABLE product_media IS 'Медиафайлы товаров (изображения, видео)';
COMMENT ON COLUMN product_media.is_primary IS 'Флаг основного изображения товара';

-- Создание индексов для таблицы медиафайлов
CREATE INDEX IF NOT EXISTS idx_product_media_product ON product_media(product_id);
CREATE INDEX IF NOT EXISTS idx_product_media_primary ON product_media(is_primary);

-- =====================================================
-- 7. Таблица заказов
-- =====================================================
CREATE TABLE IF NOT EXISTS customer_orders (
    id_customer_orders BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    total_amount NUMERIC(10, 2) NOT NULL,
    order_status VARCHAR(20) DEFAULT 'pending',
    shipping_address JSONB NOT NULL,
    billing_address JSONB,
    payment_method VARCHAR(50),
    payment_status VARCHAR(20) DEFAULT 'pending',
    payment_reference VARCHAR(100),
    tracking_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES system_users(id_user) ON DELETE RESTRICT
);

COMMENT ON TABLE customer_orders IS 'Заказы клиентов';
COMMENT ON COLUMN customer_orders.order_status IS 'Статус заказа: pending, confirmed, processing, shipped, delivered, cancelled, refunded';
COMMENT ON COLUMN customer_orders.payment_status IS 'Статус оплаты: pending, paid, failed, refunded';
COMMENT ON COLUMN customer_orders.shipping_address IS 'Адрес доставки в формате JSON';
COMMENT ON COLUMN customer_orders.billing_address IS 'Адрес оплаты в формате JSON';
COMMENT ON COLUMN customer_orders.notes IS 'Комментарии к заказу (клиента и менеджера)';

-- Создание индексов для таблицы заказов
CREATE INDEX IF NOT EXISTS idx_customer_orders_customer ON customer_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_orders_number ON customer_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_customer_orders_status ON customer_orders(order_status);

-- =====================================================
-- 8. Таблица позиций заказов
-- =====================================================
CREATE TABLE IF NOT EXISTS order_line_items (
    id_order_line_items BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity_ordered INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    line_total NUMERIC(10, 2) NOT NULL,
    discount_percentage NUMERIC(5, 2) DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES customer_orders(id_customer_orders) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES inventory_products(id_inventory_products) ON DELETE RESTRICT
);

COMMENT ON TABLE order_line_items IS 'Позиции заказов';
COMMENT ON COLUMN order_line_items.line_total IS 'Общая сумма позиции (quantity * unit_price - discount)';

-- Создание индексов для таблицы позиций заказов
CREATE INDEX IF NOT EXISTS idx_order_line_items_order ON order_line_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_line_items_product ON order_line_items(product_id);

-- =====================================================
-- 9. Таблица корзины покупок
-- =====================================================
CREATE TABLE IF NOT EXISTS shopping_cart (
    id_shopping_cart BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES system_users(id_user) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES inventory_products(id_inventory_products) ON DELETE CASCADE,
    UNIQUE(user_id, product_id)
);

COMMENT ON TABLE shopping_cart IS 'Корзина покупок пользователей';

-- Создание индексов для таблицы корзины
CREATE INDEX IF NOT EXISTS idx_shopping_cart_user ON shopping_cart(user_id);
CREATE INDEX IF NOT EXISTS idx_shopping_cart_product ON shopping_cart(product_id);

-- =====================================================
-- 10. Таблица избранных товаров
-- =====================================================
CREATE TABLE IF NOT EXISTS product_favorites (
    id_product_favorites BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES system_users(id_user) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES inventory_products(id_inventory_products) ON DELETE CASCADE,
    UNIQUE(user_id, product_id)
);

COMMENT ON TABLE product_favorites IS 'Избранные товары пользователей';

-- Создание индексов для таблицы избранного
CREATE INDEX IF NOT EXISTS idx_product_favorites_user ON product_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_product_favorites_product ON product_favorites(product_id);

-- =====================================================
-- 11. Таблица отзывов на товары
-- =====================================================
CREATE TABLE IF NOT EXISTS product_reviews (
    id_product_reviews BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_verified_purchase BOOLEAN NOT NULL DEFAULT FALSE,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES system_users(id_user) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES inventory_products(id_inventory_products) ON DELETE CASCADE,
    UNIQUE(user_id, product_id)
);

COMMENT ON TABLE product_reviews IS 'Отзывы и рейтинги товаров';
COMMENT ON COLUMN product_reviews.rating IS 'Рейтинг от 1 до 5 звезд';
COMMENT ON COLUMN product_reviews.is_verified_purchase IS 'Флаг подтвержденной покупки';
COMMENT ON COLUMN product_reviews.is_approved IS 'Флаг одобрения отзыва модератором';

-- Создание индексов для таблицы отзывов
CREATE INDEX IF NOT EXISTS idx_product_reviews_user ON product_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_product ON product_reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_approved ON product_reviews(is_approved);

-- =====================================================
-- 12. Таблица логов аудита пользователей
-- =====================================================
CREATE TABLE IF NOT EXISTS user_audit_log (
    id_user_audit_log BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50),
    record_id BIGINT,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES system_users(id_user) ON DELETE SET NULL
);

COMMENT ON TABLE user_audit_log IS 'Логи аудита действий пользователей';
COMMENT ON COLUMN user_audit_log.action_type IS 'Тип действия: CREATE, UPDATE, DELETE, LOGIN, LOGOUT';
COMMENT ON COLUMN user_audit_log.old_values IS 'Старые значения в формате JSON';
COMMENT ON COLUMN user_audit_log.new_values IS 'Новые значения в формате JSON';

-- Создание индексов для таблицы логов аудита
CREATE INDEX IF NOT EXISTS idx_user_audit_log_user ON user_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_user_audit_log_action ON user_audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_user_audit_log_table ON user_audit_log(table_name);
CREATE INDEX IF NOT EXISTS idx_user_audit_log_created ON user_audit_log(created_at);

-- =====================================================
-- Вставка начальных данных
-- =====================================================

-- Вставка ролей пользователей
INSERT INTO user_roles (role_name, role_description, permissions) VALUES
('ADMIN', 'Администратор системы', '{"all": true}'::jsonb)
ON CONFLICT (role_name) DO NOTHING;

INSERT INTO user_roles (role_name, role_description, permissions) VALUES
('MANAGER', 'Менеджер заказов', '{"orders": true, "products": true}'::jsonb)
ON CONFLICT (role_name) DO NOTHING;

INSERT INTO user_roles (role_name, role_description, permissions) VALUES
('CUSTOMER', 'Клиент магазина', '{"orders": true, "cart": true, "favorites": true}'::jsonb)
ON CONFLICT (role_name) DO NOTHING;

-- =====================================================
-- Конец скрипта
-- =====================================================
