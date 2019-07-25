-- 1. Выберите id и имя оператора из таблицы операторов; пронумеруйте записи по названию оператора, так чтобы при изменении буквы алфавита нумерация начиналась заново
-- Также добавьте в выборку:
-- - общее количество операторов
-- - общее количество операторов в зависимости от первой буквы названия оператора
-- - следующий ид оператора
-- - предыдущий ид оператора
-- - название оператора 2 строки назад
select id, opername, ROW_NUMBER () OVER firstLetter,
       count(*) over () as total_operatos_count,
       count(*) over firstLetter as the_same_first_letter_operatos_count,
       lead(id, 1) over () as next_operator_id,
       lag(id, 1) over () as previous_operator_id,
       lag(opername, 2) over () as previous_operator_id
from operators
     window firstLetter as  (PARTITION BY left(opername, 1) ORDER BY left(opername, 1))
order by left(opername, 1)


-- 2. Гос дума выпустила новый закон, по которому все компании занимающиеся телефонией должны подписать с операторами, с которыми есть взаимодействие, дополнительное соглашение о конфиденциальности.
-- У нас всего 3 менеджера, помогите сформировать 3 группы операторов, чтобы каждый мог связаться с оператором оперативно.
-- В результатах должен быть номер группы, ид оператора, его название, название организации и телефон (вероятно это поле tels)
select id, opername, orgname, tels,
       NTILE(3) over (order by id desc)
from operators
order by id desc

-- 3. По каждому оператору выберите 2 самых больших платежа
-- в запросе должно быть ид оператора, название, сумма платежа, дата платежа, является ли он самым большим для этого оператора.
-- Этот запрос нужно сделать в 2х вариантах - без аналитических функций и с ними.
create view call_price as select
                              cid,
                              DST_NUMBER_BILL,
                              elapsed_time,
                              r_dst.price,
                              r_dst.price * elapsed_time as cost,
                              bill_date,
                              o.opername,
                              o.id as operator_id
                          FROM
                              (SELECT
                                   cid,
                                   DST_NUMBER_BILL,
                                   src_number_bill,
                                   DST_IP,
                                   src_ip,
                                   BILL_DATE,
                                   BILL_TIME,
                                   elapsed_time
                               FROM CDR) CDR_CTE
--         делаем по два джойна на таблицы, чтобы выгрести входящий и исходящий тарифы
                                  INNER JOIN oper_ip_tmp ip_dst ON (ip_dst.IP_OP=DST_IP)
                                  INNER JOIN SITE  s_dst ON s_dst.ID=ip_dst.OP_ID
                                  inner join operators o on (s_dst.oper_id = o.id)
                                  INNER JOIN RATES r_dst ON r_dst.RATE_ID=s_dst.rate_t AND r_dst.RATE_DATE < BILL_DATE AND r_dst.stop_DATE>BILL_DATE

                          WHERE
                              ip_dst.ID IS NOT NULL
                            AND r_dst.ID = (
                              SELECT r2.ID
                              FROM DEST_CODE dc2,
                                   RATES r2
                              WHERE dc2.DEST_ID = r2.CODE_ID
                                AND r2.RATE_ID = s_dst.rate_t
                                AND r2.RATE_DATE < BILL_DATE
                                AND r2.stop_DATE > BILL_DATE
                                AND dc2.CODE
                                  IN (
                                      SUBSTRING(CDR_CTE.DST_NUMBER_BILL, 1, 1),
                                      SUBSTRING(CDR_CTE.DST_NUMBER_BILL, 1, 2),
                                      SUBSTRING(CDR_CTE.DST_NUMBER_BILL, 1, 3),
                                      SUBSTRING(CDR_CTE.DST_NUMBER_BILL, 1, 4),
                                      SUBSTRING(CDR_CTE.DST_NUMBER_BILL, 1, 5),
                                      SUBSTRING(CDR_CTE.DST_NUMBER_BILL, 1, 6)

                                        )
                              ORDER BY dc2.CODE DESC
                              LIMIT 1
                          );

-- присвоим ранг стоимости звонков по каждому оператору и потом выберем только первые два места по каждому
select *, case when rnk = 1 then 'max_cost' else 'second_max_cost' end from
    (select dense_rank()  over operator_wnd rnk, cid, bill_date, opername, operator_id, cost from call_price
                                                                                                  window operator_wnd as (partition by operator_id order by cost desc)) as rankedPrices where rnk in (1,2) order by operator_id

-- то же самое, только с подзапросами
with max_operator_cost as (select cost, cp.operator_id, opername, bill_date from call_price cp
                                                                                     inner join (
    select operator_id, max(cost) max_cost from call_price group by operator_id
) t on t.operator_id = cp.operator_id and max_cost = cp.cost
                           order by operator_id)
select cost, cp.operator_id, opername, bill_date, 'second_max_cost' from call_price cp
                                                                             inner join (
    select cp.operator_id, max(cp.cost) second_max_cost from call_price cp inner join max_operator_cost on cp.operator_id = max_operator_cost.operator_id where  cp.cost != max_operator_cost.cost group by cp.operator_id
) t on t.operator_id = cp.operator_id and second_max_cost = cp.cost
union all select cost, operator_id, opername, bill_date, 'max_cost' from max_operator_cost
order by operator_id, cost



-- 4. Посчитайте платежи в системе в разрезе год (строка) - месяц (колонка), на пересечении должна быть сумма платежей за этот год и месяц.
CREATE extension tablefunc;
SELECT *
FROM crosstab( 'select (date_part(''year'', bill_date))::INTEGER year_,  (date_part(''month'', bill_date))::INTEGER month_ , (sum(cost))::NUMERIC from call_price group by date_part(''year'', bill_date), date_part(''month'', bill_date)')
         AS final_result(Year INTEGER, January NUMERIC, February NUMERIC, March NUMERIC, April NUMERIC, May NUMERIC, June NUMERIC, July NUMERIC, August NUMERIC, September NUMERIC, October NUMERIC, November NUMERIC, December NUMERIC);