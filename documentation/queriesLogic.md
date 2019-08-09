# Описание самых популярных select запросов

## Пользователь  
### Список категорий
Предполагается, что категории выводятся в виде списка, сначала самые верхние. Кликнув на верхнюю, можно провалиться ниже и т.д.
Индекс по parent_id имеется. 

_SQL_:  
```sql
select id, name from categories where parent_id is null ;
```

_SQL_:  
```sql
select id, name from categories where parent_id = {'parent_id'} ;
```
  
### Просмотр товаров по категориям:

_SQL_:  
```sql
Select po.id, po.price, po.available_count, s.name, m.name,  p.name from product_offers po 
left join products p on (po.product_id = p.id)
left join suppliers s on (po.supplier_id = s.id)
left join manufacturers m on (p.manufacturer_id = m.id)
where p.category_id = '{category_id}';
```
_Вероятные  фильтры_: 
1. Наименование товара, полнотекстовый поиск (to_tsvector('english', name) @@ to_tsquery('english', %search_phrase%)). Индекс имеется - products.products_name_index. 
2. По производителю. Подразумевается, что пользователь выбрал производителя из списка, поэтому испльзуем id
 (m.id = '{id}'). Индекс имеется - products_manufacturer_index
3. По цене (po.price >= '{price_from}' and po.price <='{price_to'}). Индекс имеется  - product_offers.product_offers_price_index 
4. По атрибутам. Вероятно, понадобится подзапрос: 
_SQL_:  
```sql
and po.id in (select offer_id from product_offer_attributes poa where  
 poa.category_attribute_id = {'category_attribute_id'} and 
 poa.category_attribute_value={'category_attribute_vale'}) ;
```
Условие в подзапросе будет сложнее, если поиск по нескольким атрибутам. Составной индекс по id атрибута категории и value имеется

### Просмотр списка своих заказов
_SQL_:  
```sql
Select o.id, o.date_created, o.status, o.date_paid, sum(count*actual_unit_price) 
from order_lists ol
left join orders o on (ol.order_id = o.id) group by o.id   
where status != '{template}' and client_id = '{current_client}'  
```
_Вероятные  фильтры_: 
1. Фильтр по дате (o.date_created >= '{date_from'} and o.date_crated <= '{date_to}'). Составной индекс по дате создания 
и статусу имеется orders.orders_status_date_created_index 
2. Фильтр по статусу - он имеется по умолчанию, т.к. заказы со статусом 'template' это как бы корзины. 
Это позволяет пользователю иметь несколько корзин одновременно. 

### Просмотр транзакций оплаты заказа
_SQL_:  
```sql
select date_created, status, sum from order_transactions ot 
where   order_id = '{order_id}'
```
_Вероятные  фильтры_: 
1. Фильтр по дате и статусу, если нужно 
(ot.date_created >= '{date_from'} and ot.date_crated <= '{date_to}' and ot.status='{status}'). Составной индекс по дате создания 
и статусу имеется order_transactions.order_transactions_date_created_status_index 

### Просмотр транзакций пополнения лицевого счёта
_SQL_:  
```sql
select date_created, status, sum from recharge_transactions rt 
where   client_id = '{current_client}'
```
_Вероятные  фильтры_: 
1. Фильтр по дате и статусу, если нужно 
(rt.date_created >= '{date_from'} and rt.date_crated <= '{date_to}' and rt.status='{status}'). Составной индекс по дате создания 
и статусу имеется  

### Просмотр списка товаров заказа
_SQL_:  
```sql
select p.name, ol.count, ol.actual_unit_price,  from order_lists ol
left join product_offers po on ol.product_offer_id = po.id
left join products p on po.product_id = p.id
where   order_id = '{order_id}'
```

## Оператор
### Просмотр списка заказов
_SQL_:  
```sql
Select o.id, o.date_created, o.status, o.date_paid, sum(count*actual_unit_price) 
from order_lists ol
left join orders o on (ol.order_id = o.id) group by o.id   
where status != '{template}'  
```
_Вероятные  фильтры_: 
1. Фильтр по дате (o.date_created >= '{date_from'} and o.date_crated <= '{date_to}'). Составной индекс по дате создания 
и статусу имеется orders.orders_status_date_created_index 
2. Фильтр по статусу - он имеется по умолчанию, т.к. заказы со статусом 'template' это как бы корзины. Но можно выбрать, 
например все отменённые или наоборот, все в статусе "черновк", т.е. как бы корзины, для аналитики, рекламной рассылки 
или побуждения пользователя купить

### Просмотр транзакций оплаты заказов
_SQL_:  
```sql
select date_created, status, sum from order_transactions ot 
```
_SQL_:  
```sql
select sum(sum) from order_transactions ot 
```
_Вероятные  фильтры_: 
1. Фильтр по дате и статусу, если нужно 
(ot.date_created >= '{date_from'} and ot.date_crated <= '{date_to}' and ot.status='{status}'). Составной индекс по дате создания 
и статусу имеется order_transactions.order_transactions_date_created_status_index 

### Просмотр транзакций пополнения лицевого счёта
_SQL_:  
```sql
select date_created, status, sum from recharge_transactions rt 

```

_SQL_:  
```sql
select sum(sum) from recharge_transactions rt 

```
_Вероятные  фильтры_: 
1. Фильтр по дате и статусу, если нужно 
(rt.date_created >= '{date_from'} and ot.date_crated <= '{date_to}' and rt.status='{status}'). Составной индекс по дате создания 
и статусу имеется  
