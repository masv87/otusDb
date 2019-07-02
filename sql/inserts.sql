START TRANSACTION;

insert into clients (name, balance) values ('Client1', 0), ('Client2', 0), ('Client3', 0);
insert into manufacturers (name) values ('Manufacturer1'), ('Manufacturer2'), ('Manufacturer3');
insert into suppliers (name) values ('Supplier1'), ('Supplier2'), ('Supplier3');

insert into categories (name) values ('Main Parent');
insert into categories (name, parent_id) values ('Sub Parent', (select id from categories where name = 'Main Parent') );
insert into categories (name, parent_id) values ('Child', (select id from categories where name = 'Sub Parent') );

insert into products (name, category_id, manufacturer_id) values
    ('Product1', (select id from categories where name = 'Child'), (select id from manufacturers where  name = 'Manufacturer1')),
    ('Product2', (select id from categories where name = 'Child'), (select id from manufacturers where  name = 'Manufacturer2')),
    ('Product3', (select id from categories where name = 'Child'), (select id from manufacturers where  name = 'Manufacturer3'));

with attribute_info as (
    select  'Color' as name, 'string' as type, id as category_id  from categories where name ='Child' union
    select  'Length' as name, 'number' as type, id as category_id  from categories where name ='Child'union
    select  'With box' as name, 'bool' as type, id as category_id  from categories where name ='Child'
    )
insert into category_attributes (name, type, category_id)  select *  from attribute_info;

with product_offers_template as  (select products.id pid, random() * 1000 + 1, suppliers.id sid, floor(random()*101) from products, suppliers)
insert into product_offers (product_id, price, supplier_id, available_count) select  * from product_offers_template;

with offer_attributes_info as (select ca.id as caid, ca.name as name,  po.id as poid from category_attributes ca, product_offers po )
insert into product_offer_attributes (offer_id, category_attribute_id, category_attribute_value)
select poid, caid, to_jsonb('green'::varchar) from offer_attributes_info where name = 'Color' union
select poid, caid, to_jsonb(123::integer) from offer_attributes_info where name = 'Length' union
select poid, caid, to_jsonb('t'::boolean) from offer_attributes_info where name = 'With box';

insert into recharge_transactions (client_id, sum, status, date_accepted, date_created)  select id, random() * 100 + 1, 5, now(), now() from clients;
insert into recharge_transactions (client_id, sum, status, date_accepted, date_created)  select id, random() * 100 + 1, 5, now(), now() from clients;
insert into recharge_transactions (client_id, sum, status, date_accepted, date_created)  select id, random() * 100 + 1, 5, now(), now() from clients;
insert into recharge_transactions (client_id, sum, status, date_accepted, date_created)  select id, random() * 100 + 1, 5, now(), now() from clients;
insert into recharge_transactions (client_id, sum, status, date_accepted, date_created)  select id, random() * 100 + 1, 5, now(), now() from clients;

with client_balance as (select client_id, SUM(sum) as balance from recharge_transactions group by client_id)
update clients  set balance = client_balance.balance from client_balance where id = client_id;



COMMIT TRANSACTION;