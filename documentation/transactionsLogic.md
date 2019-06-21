# Описание логики транзакций для модели данных
Подразумевается, что уровень изоляции у нас стоит READ COMMITTED, база данных - PostgreSql
## Обновление каталога
Подразумевается, что обновление каталога (категории, атрибуты категорий, товары, товарные предложения) происходит посредством загрузки и парсинга файлов различных форматов. 
Во время обновления каталога магазин закрыт на "переучёт" и купить ничего нельзя. 
## Оплата заказа  
_Фазы_: 
1. Пользователь нажимает "купить". 
2. Старт транзакции. 
2. Проверка баланса. Если не достаточно средств - откат. 
2. Проверка доступного количества товара. Если недостаточно, то откат
3. Заполнение таблицы order_transactions новой строкой со статусом "in_progress", 
5. Уменьшение доступного количества товара  
6. Уменьшение баланса пользователя на сумму равную сумме заказа. 
7. Изменение статуса заказа на "оплачен". 
8. Обновление статуса в order_transactions на "completed"
9. Коммит транзакции

_Вероятные проблемы_: 
1. Ситуация при которой один и тот же товар одновременно захотят купить больше 1 пользователя.    
2. Сутация, при которой одна и та же учётка юзера будет использована двумя разными людьми и они одновременно захотят 
что-то купить, что повлечёт на одновременное изменение баланса пользователя
3. Ситуация, при котрой одна и та же учётка юзера будет использована двумя разными людьми и один захочет оплатить заказ, 
а другой удалить. 
4. Ситуация, при котрой одна и та же учётка юзера будет использована двумя разными людьми и один захочет оплатить заказ, 
а другой оплатить другой заказ, при этом денег только на один заказ.

_SQL_:  
```sql
Start transaction;

Select * from orders where id = 'order_id' for update
Select * from product offers where id in (select product_offer_id from order_lists where order_id = 'order_id') for update
Select balance from clients where id = 'clientId' for update;
Insert into order_transactions (order_id, sum, status, date_created) values ('order_id', 'sum', 'in_progress', NOW());
Update product_offers set available_count = available_count - 'count_from_order_lists_for_this_offer' where id = 'product_offer_id_from_order_lists';
Update clients set balance = balance - 'order_sum' where id = 'client_id';
Update orders set status = 'payed' where id = 'order_id';
Update order_transactions set status = 'completed', date_accepted = NOW() where id = transaction_id;

Commit transaction;
```
 



## Пополнение счёта
_Фазы_: 
1. Польователь вводит сумму пополения и нажимает "пополнить"
2. Старт транзакции
3. Вставка записи в таблицу транзакций пополений recharge_transactions в статусе 'in_progress'
4. Увеличение баланса пользователя на сумму транзакции
5. Изменение статуса транзакции пополнения в таблице recharge_transactions на статус 'completed'
6. Коммит транзакции

_Вероятные проблемы_ 
1. Ситуация, при которой одна и та же учётка используется разными людьми и оба пополняют счёт
2. Ситуация, при которой одна и та же учётка используется разными людьми и один пополянет счёт, а второй оплачивает заказ


_SQL_
```sql
Start transaction; 

Select balance from clients where id = 'client_id' for update;
Insert into  recharge_transactions (client_id, sum,status, date_created) values ('client_id', 'sum', 'in_progress', NOW());
Update balance set balance = balance + sum where client_id = 'client_id'; 

Commit transaction ;

```

## Поступление товаров на склад
_Фазы_: 
1. Оператор загружает файл, распарсив который можно получить соответствие между id-ами товаров и кол-ом, пришедшим на склад
2. Старт транзакции
3. Увеличение доступного для покупки кол-ва товаров на величину из файла
4. Коммит транзакции

_Вероятные проблемы_ 
1. Ситуация, при которой одновременно будут происходить покупка и увеличение кол-ва


_SQL_
```sql
Start transaction; 

Select *  from product_offers where id in  ('ids list') for update;
Update product_offers set available_count = 'new_available_count' where id = 'id_from_file'; 

Commit transaction ;

```


