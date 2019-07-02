CREATE EXTENSION pgcrypto;

create table categories
(
	id uuid default gen_random_uuid() not null
		constraint categories_pk
			unique,
	name varchar(150),
	parent_id uuid
		constraint categories__category_parent_fk
			references categories (id)
);

comment on table categories is 'Категории товаров. Имеется индекс по parent_id для быстрого поиска детей.';

comment on column categories.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column categories.name is 'Название категории. 150 символов на всякий случай, для длинных имён';

comment on column categories.parent_id is 'Id родительской категории, ссылается на эту же таблицу';

alter table categories owner to shop;

create index parent_id_categories__index
	on categories (parent_id);

create table manufacturers
(
	id uuid default gen_random_uuid() not null
		constraint manufacturers_pk
			primary key,
	name varchar(150)
);

comment on table manufacturers is 'Производители. Индекс по имени для упрощения выборок';

comment on column manufacturers.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column manufacturers.name is 'Наименование производителя. 150 символов для уверенности, что длинные имена влезут.';

alter table manufacturers owner to shop;

create table products
(
	id uuid default gen_random_uuid() not null
		constraint goods_pk
			unique,
	name varchar(150),
	category_id uuid
		constraint goods_category_fk
			references categories (id),
	manufacturer_id uuid
		constraint products_manufacturer_fk
			references manufacturers
);

comment on table products is 'Товары. индекс по category_id для быстрого поиска товаров в категории. индексты по имени производителя и имени товара для поиска';

comment on column products.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column products.name is 'Наименование товара. 150 символов зарезервировано для товаров с длинным названием';

comment on column products.category_id is 'Ссылка на категорию';

comment on column products.manufacturer_id is 'ссылка на производителя';

alter table products owner to shop;

create index products_category_id_index
	on products (category_id);

create index products_name_index
	on products (name);

create index products_manufacturer_index
	on products (manufacturer_id);

create index manufacturers_name_index
	on manufacturers (name);

create table suppliers
(
	id uuid default gen_random_uuid() not null
		constraint suppliers_pk
			primary key,
	name varchar(150)
);

comment on table suppliers is 'Поставщики. индекс по name для быстрого поиска по имени';

comment on column suppliers.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column suppliers.name is 'Наименование поставщика. 150 символов зарезервированы для длинных имён';

alter table suppliers owner to shop;

create index suppliers_name_index
	on suppliers (name);

create table category_attributes
(
	id uuid default gen_random_uuid() not null
		constraint category_attributes_pk
			primary key,
	name varchar(150),
	type varchar(10) not null,
	category_id uuid
		constraint category_attributes_category_fk
			references categories (id)
);

comment on table category_attributes is 'Атрибуты категорий. Имеется индекс по category_id для быстрой выборки атрибутов категории';

comment on column category_attributes.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column category_attributes.name is 'Имя атрибута. 150 символов на всякий зарезервировано для длинных имён';

comment on column category_attributes.type is 'Тип данных, которые может принимать данная характеристика. Число, несколько значений и т.д.
Тип должен уместиться не более чем в 10 символов. Выбрал varchar, а не int, чтобы можно было глядя на сырые данные сразу понять, что за тип,
 а не лезть в код. Это преимущество выигрывает у преимуществ инта в данном случае';

comment on column category_attributes.category_id is 'Вторичный клюс на таблицу categories';

alter table category_attributes owner to shop;

create index category_attributes_category_id_index
	on category_attributes (category_id);

create table product_offers
(
	id uuid default gen_random_uuid() not null
		constraint product_offers_pk
			primary key,
	product_id uuid
		constraint product_offers_products_fk
			references products (id),
	price numeric(10,2)
		constraint product_offers_price_check
			check (price >= (0)::numeric),
	supplier_id uuid
		constraint product_offers_supplier_fk
			references suppliers,
	available_count integer
);

comment on table product_offers is 'Товарные предложения. индекс по  product_id для джойна и по price для быстрого поиска товарных предложений с определённой ценой';

comment on column product_offers.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column product_offers.product_id is 'Ссылка на таблицу products';

comment on column product_offers.price is 'Тип данных выбрал, как рекомендумый документацией для денежных операций. Подразумевается, что 8 знаков до и 2 знака после хватит';

comment on column product_offers.supplier_id is 'Ссылка на таблицу suppliers';

comment on column product_offers.available_count is 'Доступное количество товара. Подразумевается, что число всегда целое.';

alter table product_offers owner to shop;

create index product_offers_price_index
	on product_offers (price);

create index product_offers_product_index
	on product_offers (product_id);

create table product_offer_attributes
(
	id uuid default gen_random_uuid() not null
		constraint product_offer_attributes_pk
			primary key,
	offer_id uuid
		constraint product_offer_attributes_offer_fk
			references product_offers,
	category_attribute_id uuid,
	category_attribute_value jsonb
);

comment on table product_offer_attributes is 'Значения атрибутов для конкретных товарных предложений. индекс по offer_id для быстрой выборки атрибутов товара. Составной индекс по category_attribute_id и category_attribute_value для поиска по атрибутам';

comment on column product_offer_attributes.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column product_offer_attributes.offer_id is 'Ссылка на таблицу product_offers';

comment on column product_offer_attributes.category_attribute_id is 'Ссылка на таблцу category_attributes';

comment on column product_offer_attributes.category_attribute_value is 'Значение атрибута. Jsonb выбрал, потому что значение может быть любым, плюс, jsonb можно делать индексируемым, да и сами postgres его рекомендуют больше чем json';

alter table product_offer_attributes owner to shop;

create index product_offer_attributes_category_value_index
	on product_offer_attributes (category_attribute_id, category_attribute_value);

create index product_offer_attributes_offer_id_index
	on product_offer_attributes (offer_id);

create table clients
(
	id uuid default gen_random_uuid() not null
		constraint clients_pk
			primary key,
	name varchar(150),
	balance numeric(10,2)
		constraint clients_balance_check
			check (balance >= (0)::numeric)
);

comment on table clients is 'Клиенты магазина. Индекес по имени для упрощения поиска';

comment on column clients.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column clients.name is 'Имя клиента. Зарезервировал 150 символов для длинных имён';

comment on column clients.balance is 'Баланс клиента. Тип данных выбрал, как рекомендумый документацией для денежных операций. Подразумевается, что 8 знаков до и 2 знака после хватит';

alter table clients owner to shop;

create index clients_name_index
	on clients (name);

create table recharge_transactions
(
	id uuid default gen_random_uuid() not null
		constraint recharge_transactions_pk
			primary key,
	client_id uuid
		constraint recharge_transactions_client_fk
			references clients,
	sum numeric(10,2)
		constraint recharge_transactions_sum_check
			check (sum > (0)::numeric),
	status integer,
	date_created timestamp with time zone,
	date_accepted timestamp with time zone
);

comment on table recharge_transactions is 'Транзакции пополнения баланаса. индекс по client_id для быстрого поиска транзакций пополнения для клиента. Индекс по date_created и status для поиска транзакций по дате с определынным статусом';

comment on column recharge_transactions.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column recharge_transactions.client_id is 'ссылка на таблицу clients';

comment on column recharge_transactions.sum is 'Тип данных выбрал, как рекомендумый документацией для денежных операций. Подразумевается, что 8 знаков до и 2 знака после хватит';

comment on column recharge_transactions.status is 'Статус транзакции. Выбрал int из-за перевешивающих преимуществ в данном случае в сравнении с enum';

comment on column recharge_transactions.date_created is 'Дата создания транзакции. Timestamp а не date, т.к. важно именно точное время.';

comment on column recharge_transactions.date_accepted is 'Дата одобрения транзакции. Timestamp а не date, т.к. важно именно точное время.';

alter table recharge_transactions owner to shop;

create index recharge_transactions_client_id_index
	on recharge_transactions (client_id);

create index recharge_transactions_date_created_status_index
	on recharge_transactions (date_created, status);

create table orders
(
	id uuid default gen_random_uuid() not null
		constraint orders_pk
			primary key,
	client_id uuid
		constraint orders_client_fk
			references clients,
	date_created timestamp with time zone,
	status integer,
	date_paid timestamp with time zone,
	date_cancelled timestamp
);

comment on table orders is 'Заказы. Индекс по client_id для быстрой выборки заказов клиента. Индекс по date_created и status для отображения заказов определенного статуса за период';

comment on column orders.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column orders.client_id is 'Ссылка на таблицу clients';

comment on column orders.date_created is 'Дата создания заказа. Timestamp а не date, т.к. важно именно точное время.';

comment on column orders.status is 'Статус заказа. int, а не enum, потому что преимущества int в данном случае перевешивают преимущества enum';

comment on column orders.date_paid is 'Дата, когда заказ полностью оплачен. Timestamp а не date, т.к. важно именно точное время.';

comment on column orders.date_cancelled is 'Дата отмена заказа. Timestamp а не date, т.к. важно именно точное время.';

alter table orders owner to shop;

create index orders_client_id_index
	on orders (client_id);

create index orders_status_date_created_index
	on orders (date_created, status);

create table order_lists
(
	id uuid default gen_random_uuid() not null
		constraint order_lists_pk
			primary key,
	order_id uuid
		constraint order_lists_order__fk
			references orders,
	product_offer_id uuid
		constraint order_lists_product_offer_fk
			references product_offers,
	count integer,
	actual_unit_price numeric(10,2)
);

comment on table order_lists is 'Состав заказа. Индекс по id заказа для быстрой выборки товаров в заказе';

comment on column order_lists.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column order_lists.order_id is 'Ссылка на таблицу orders';

comment on column order_lists.product_offer_id is 'Ссылка на таблицу product_offers';

comment on column order_lists.count is 'Количество товара в заказе. Всегда целое число.';

comment on column order_lists.actual_unit_price is 'Цена за единицу на момент покупки. Тип данных выбрал, как рекомендумый документацией для денежных операций. Подразумевается, что 8 знаков до и 2 знака после хватит';

alter table order_lists owner to shop;

create index order_lists_order_id_index
	on order_lists (order_id);

create table order_transactions
(
	id uuid default gen_random_uuid() not null
		constraint order_transactions_pk
			primary key,
	order_id uuid
		constraint order_transactions_order_fk
			references orders,
	sum numeric(10,2)
		constraint order_transactions_sum_check
			check (sum > (0)::numeric),
	status integer,
	date_created timestamp with time zone,
	date_accepted timestamp with time zone,
	date_canceled timestamp with time zone
);

comment on table order_transactions is 'Транзакции, относящиеся к оплате заказов. Соаставной индекс по статусу и дате добавления для выборок транзакций определнного статуса по датам. Индекс по номеру заказа для быстрого получения транзакций в рамках заказа';

comment on column order_transactions.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column order_transactions.order_id is 'Ссылка на таблицу orders';

comment on column order_transactions.sum is 'Сумма транзакции. Тип данных выбрал, как рекомендумый документацией для денежных операций. Подразумевается, что 8 знаков до и 2 знака после хватит';

comment on column order_transactions.status is 'Выбрал integer, а не enum из-за преимуществ в сортировке, меньшем месте и т.д.';

comment on column order_transactions.date_created is 'Дата создания. Дата одобрения транзакции. Timestamp а не date, т.к. важно именно точное время.';

comment on column order_transactions.date_accepted is 'Дата одобрения транзакции. Timestamp а не date, т.к. важно именно точное время.';

comment on column order_transactions.date_canceled is 'Дата отмены транзакции. Timestamp а не date, т.к. важно именно точное время.';

alter table order_transactions owner to shop;

create index order_transactions_order_index
	on order_transactions (order_id);

create index order_transactions_date_created_status_index
	on order_transactions (date_created, status);

create table prices_history
(
	id uuid default gen_random_uuid() not null
		constraint prices_history_pk
			primary key,
	product_offer_id uuid
		constraint prices_history_product_offer_fk
			references product_offers,
	date_start timestamp with time zone,
	date_end timestamp with time zone,
	status integer,
	price numeric(10,2)
);

comment on table prices_history is 'История изменения цен. Индекс по product_offer_id для быстрой выборки истории цен по товару';

comment on column prices_history.id is 'uuid, а не int, потому что подразумевается,
что проблемы с сортировкой и размером менее важны чем уникальность и защищённость от атак подбором';

comment on column prices_history.product_offer_id is 'Ссылка на таблицу  product_offers';

comment on column prices_history.date_start is 'Дата начала действия. Timestamp а не date, т.к. важно именно точное время.';

comment on column prices_history.date_end is 'Дата конца действия. Timestamp а не date, т.к. важно именно точное время.';

comment on column prices_history.status is 'Статус - активна, не активна и т.д.';

comment on column prices_history.price is 'Цена на этот момент. Тип данных выбрал, как рекомендумый документацией для денежных операций. Подразумевается, что 8 знаков до и 2 знака после хватит';

alter table prices_history owner to shop;

create index prices_history_product_offer_index
	on prices_history (product_offer_id);

