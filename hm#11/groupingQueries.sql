-- создаём копию таблицы oper_ip_tmp
create table oper_ip_tmp  (like oper_ip including all);
insert into oper_ip_tmp select * from  oper_ip;
-- Этим запросом удаляются все дубляжи из таблицы oper_ip_tmp. Далее работаем уже с таблицей без них, это допустимое упрощение
delete   from oper_ip_tmp
              USING oper_ip_tmp AS oi
                  left join (select max(id) maxid, IP_OP, START_DATE, STOP_DATE from oper_ip_tmp group by IP_OP, START_DATE, STOP_DATE ) oit on oi.id = maxid
where oit.maxid is null and oper_ip_tmp.id = oi.id

-- Выборка суммарного времени по странам
select c1.country_name,
       (case when sum is null then  0
             else sum end)
from countries c1
         left join (
    select
        sum(elapsed_time) sum,
        country_name
    FROM
        (SELECT
             DST_NUMBER_BILL,
             DST_IP,
             BILL_DATE,
             BILL_TIME,
             elapsed_time
         FROM CDR) CDR_CTE
            INNER JOIN oper_ip_tmp ip ON ip.IP_OP=DST_IP
            INNER JOIN SITE s ON s.ID=ip.OP_ID
            INNER JOIN RATES r ON r.RATE_ID=s.rate_t AND r.RATE_DATE < BILL_DATE AND r.stop_DATE>BILL_DATE
            INNER JOIN DEST_CODE dc ON dc.DEST_ID=r.CODE_ID
            inner join DEST ds on dc.DEST_ID = ds.ID
            inner join countries  on countries.country_code = ds.country_code

    WHERE
        ip.ID IS NOT NULL
      AND r.ID = (
        SELECT r2.ID
        FROM DEST_CODE dc2,
             RATES r2
        WHERE dc2.DEST_ID = r2.CODE_ID
          AND r2.RATE_ID = s.rate_t
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
    )  group by country_name) tmp on c1.country_name = tmp.country_name;

-- выборка кол-ва  звонков по странам
select c1.country_name,
       (case when count is null then  0
             else count end)
from countries c1
         left join (
    select
        count( DST_NUMBER_BILL) count,
        country_name
    FROM
        (SELECT
             DST_NUMBER_BILL,
             DST_IP,
             BILL_DATE,
             BILL_TIME,
             elapsed_time
         FROM CDR ) CDR_CTE
            INNER JOIN oper_ip_tmp ip ON ip.IP_OP=DST_IP
            INNER JOIN SITE s ON s.ID=ip.OP_ID
            INNER JOIN RATES r ON r.RATE_ID=s.rate_t AND r.RATE_DATE < BILL_DATE AND r.stop_DATE>BILL_DATE
            INNER JOIN DEST_CODE dc ON dc.DEST_ID=r.CODE_ID
            inner join DEST ds on dc.DEST_ID = ds.ID
            inner join  countries  on countries.country_code = ds.country_code

    WHERE
        ip.ID IS NOT NULL
      AND r.ID = (
        SELECT r2.ID
        FROM DEST_CODE dc2,
             RATES r2
        WHERE dc2.DEST_ID = r2.CODE_ID
          AND r2.RATE_ID = s.rate_t
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
    )  group by country_name) tmp on c1.country_name = tmp.country_name  ;

-- выборка кол-ва нулевых звонков по странам
select c1.country_name,
       (case when count is null then  0
             else count end)
from countries c1
         left join (
    select
        count( DST_NUMBER_BILL) count,
        country_name
    FROM
        (SELECT
             DST_NUMBER_BILL,
             DST_IP,
             BILL_DATE,
             BILL_TIME,
             elapsed_time
--       я так понял, что нулевое звонок это звонок с elapsed_time = 1
         FROM CDR  where elapsed_time = 1) CDR_CTE
            INNER JOIN oper_ip_tmp ip ON ip.IP_OP=DST_IP
            INNER JOIN SITE s ON s.ID=ip.OP_ID
            INNER JOIN RATES r ON r.RATE_ID=s.rate_t AND r.RATE_DATE < BILL_DATE AND r.stop_DATE>BILL_DATE
            INNER JOIN DEST_CODE dc ON dc.DEST_ID=r.CODE_ID
            inner join DEST ds on dc.DEST_ID = ds.ID
            inner join  countries  on countries.country_code = ds.country_code

    WHERE
        ip.ID IS NOT NULL
      AND r.ID = (
        SELECT r2.ID
        FROM DEST_CODE dc2,
             RATES r2
        WHERE dc2.DEST_ID = r2.CODE_ID
          AND r2.RATE_ID = s.rate_t
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
    )  group by country_name) tmp on c1.country_name = tmp.country_name  ;
