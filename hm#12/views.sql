-- Выборка суммарного времени по странам
create view  sum_by_countries as select c1.country_name, c1.country_code,
            (case when sum is null then  0
                  else sum end)
     from countries c1
              left join (
         select
             sum(elapsed_time) sum,
             countries.country_code
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
         )  group by countries.country_code) tmp on c1.country_code = tmp.country_code;



-- выборка кол-ва  звонков по странам
create  view call_count as select c1.country_name, c1.country_code,
      (case when count is null then  0
            else count end)
from countries c1
        left join (
   select
       count( DST_NUMBER_BILL) count,
       countries.country_code
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
   )  group by countries.country_code) tmp on c1.country_code = tmp.country_code  ;

-- выборка кол-ва нулевых звонков по странам
create view zero_call_count as select c1.country_name, c1.country_code,
          (case when count is null then  0
                else count end)
   from countries c1
            left join (
       select
           count( DST_NUMBER_BILL) count,
           countries.country_code
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
       )  group by countries.country_code) tmp on c1.country_code = tmp.country_code  ;

-- Тут вьюха для просмотра звонков и скрытия важных данных для конкретного оператора - MMDS.
-- Т.е. предполагается, что у каждого оператора будет похожая вьюха, доступ к которой имеет только он
--  все айпишники оператора MMDS
create view MMDS_call as with operator_MMDS_ips as (select ip_op from oper_ip_tmp
                                              inner join site on (op_id = site.id)
                                              inner join operators on (site.oper_id = operators.id)
                        where operators.id = 109
)
select
 cid,
 DST_NUMBER_BILL,
 case when dst_ip in (select ip_op from operator_MMDS_ips) then dst_ip else null end dst_ip,
 case when src_ip in (select ip_op from operator_MMDS_ips) then src_ip else null end src_ip,
 elapsed_time,
 case when dst_ip in (select ip_op from operator_MMDS_ips) then r_dst.price  else null end price_dst,
 case when src_ip in (select ip_op from operator_MMDS_ips) then r_src.price  else null end price_src,
 case when dst_ip in (select ip_op from operator_MMDS_ips) then r_dst.price * elapsed_time  else null end cost_dst,
 case when src_ip in (select ip_op from operator_MMDS_ips) then r_src.price * elapsed_time  else null end cost_src
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
     INNER JOIN oper_ip_tmp ip_src ON (ip_src.IP_OP=src_ip)
     INNER JOIN SITE  s_dst ON s_dst.ID=ip_dst.OP_ID
     INNER JOIN SITE  s_src ON s_src.ID=ip_src.OP_ID
     INNER JOIN RATES r_dst ON r_dst.RATE_ID=s_dst.rate_t AND r_dst.RATE_DATE < BILL_DATE AND r_dst.stop_DATE>BILL_DATE
     INNER JOIN RATES r_src ON r_src.RATE_ID=s_src.rate_o AND r_src.RATE_DATE < BILL_DATE AND r_src.stop_DATE>BILL_DATE

WHERE
 ip_dst.ID IS NOT NULL
and ip_src.id is not null
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
)
AND r_src.ID = (
 SELECT r3.ID
 FROM DEST_CODE dc3,
      RATES r3
 WHERE dc3.DEST_ID = r3.CODE_ID
   AND r3.RATE_ID = s_src.rate_o
   AND r3.RATE_DATE < BILL_DATE
   AND r3.stop_DATE > BILL_DATE
   AND dc3.CODE
     IN (
         SUBSTRING(CDR_CTE.SRC_NUMBER_BILL, 1, 1),
         SUBSTRING(CDR_CTE.SRC_NUMBER_BILL, 1, 2),
         SUBSTRING(CDR_CTE.SRC_NUMBER_BILL, 1, 3),
         SUBSTRING(CDR_CTE.SRC_NUMBER_BILL, 1, 4),
         SUBSTRING(CDR_CTE.SRC_NUMBER_BILL, 1, 5),
         SUBSTRING(CDR_CTE.SRC_NUMBER_BILL, 1, 6)

           )
 ORDER BY dc3.CODE DESC
 LIMIT 1
);

