-- Этим запросом удаляются все дубляжи из таблицы oper_ip. Далее работаем уже с таблицей без них, это допустимое упрощение
delete  oi from oper_ip oi left join (select max(id) maxid, IP_OP, START_DATE, STOP_DATE from oper_ip_tmp group by IP_OP, START_DATE, STOP_DATE ) oit
    on oi.id = maxid where oit.maxid is null
--     Следующий запрос уже считает стоимость звонка
select
       CDR.SRC_IP,
       CDR.SRC_NUMBER_OUT,
       CDR.DST_NUMBER_OUT,
       SETUP_TIME,
       CONNECT_TIME,
       DISCONNECT_TIME,
       ELAPSED_TIME,
       oper_ip.STOP_DATE,
       oper_ip.START_DATE,
       RATES.ID RATE_ID,
       RATES.RATE_DATE,
       RATES.STOP_DATE,
       RATES.TIME_ID,
       RATES.PRICE,
--         Подсчёт цены. Сначала хотел if-ы сделать, т.к. увидел в тарифах поле unpaidsec, но нет записей где это поле больше нуля
       RATES.PRICE * ELAPSED_TIME as call_cost
from CDR
--      Как я понял, основная загвоздка в данном задании это нахождение соответствия между звонком и тарифом.
--      Это соответсвие я нахожу путём соотнесения кода направления и исходящего номера
--      Этот сложный подзапрос как раз нужен, чтобы найти максимально длинный код направления из всех имеющихся,
--      который бы соответсвовал номеру и с помощью этого найти нужный тариф
         inner join (select
                         max(length(DEST_CODE.CODE)) max_length_code,
                         CID cid2
                     from CDR
                              inner join oper_ip on oper_ip.IP_OP = CDR.SRC_IP and CDR.SETUP_TIME between oper_ip.START_DATE and oper_ip.STOP_DATE
                              inner join SITE on oper_ip.OP_ID = SITE.ID
                              inner join RATES  on SITE.rate_o = RATES.RATE_ID and CDR.SETUP_TIME between RATES.RATE_DATE and RATES.STOP_DATE
                              inner join DEST_CODE on RATES.CODE_ID = DEST_CODE.DEST_ID and INSTR(CDR.DST_NUMBER_OUT, DEST_CODE.CODE) = 1
                              inner join DEST on DEST_CODE.DEST_ID = DEST.ID

                     group by CID, COUNTRY_CODE
) FILTERED_CDR on FILTERED_CDR.cid2 = CID
         inner join oper_ip on oper_ip.IP_OP = CDR.SRC_IP and CDR.SETUP_TIME between oper_ip.START_DATE and oper_ip.STOP_DATE
         inner join SITE on oper_ip.OP_ID = SITE.ID
         inner join RATES  on SITE.rate_o = RATES.RATE_ID and CDR.SETUP_TIME between RATES.RATE_DATE and RATES.STOP_DATE
         inner join DEST_CODE on RATES.CODE_ID = DEST_CODE.DEST_ID and INSTR(CDR.DST_NUMBER_OUT, DEST_CODE.CODE) = 1 and length(DEST_CODE.CODE) = max_length_code
         inner join DEST on DEST_CODE.DEST_ID = DEST.ID


