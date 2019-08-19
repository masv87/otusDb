-- Перевод функций из MySql в PostgreSql
CREATE FUNCTION get_max_substring(bill_number varchar(50))
    RETURNS varchar(12) as $$
DECLARE L_CODE VARCHAR(12);
BEGIN

    SELECT MAX(CODE)
    INTO L_CODE
    FROM DEST_CODE
    WHERE code IN (
                   SUBSTRING(bill_number,1,1),
                   SUBSTRING(bill_number,1,2),
                   SUBSTRING(bill_number,1,3),
                   SUBSTRING(bill_number,1,4),
                   SUBSTRING(bill_number,1,5),
                   SUBSTRING(bill_number,1,6),
                   SUBSTRING(bill_number,1,7),
                   SUBSTRING(bill_number,1,8),
                   SUBSTRING(bill_number,1,9),
                   SUBSTRING(bill_number,1,10),
                   SUBSTRING(bill_number,1,11),
                   SUBSTRING(bill_number,1,12)
        );

    RETURN L_CODE;
END;
$$  LANGUAGE plpgsql
    STABLE;

CREATE  FUNCTION  get_price(
    IN_BILL_NUMBER VARCHAR(50), IN_RATE_ID INT, IN_BILL_DATE timestamp with time zone) RETURNS decimal(12,6) as $$
DECLARE L_MAX_CODE VARCHAR(12);
    DECLARE L_PRICE DECIMAL(12,6);
BEGIN

    SELECT MAX(dc.code) INTO L_MAX_CODE
    FROM  RATES r
              INNER JOIN DEST_CODE dc ON dc.DEST_ID=r.code_id AND dc.code IN (
                                                                              SUBSTRING(IN_BILL_NUMBER,1,1),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,2),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,3),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,4),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,5),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,6),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,7),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,8),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,9),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,10),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,11),
                                                                              SUBSTRING(IN_BILL_NUMBER,1,12)
        )
    WHERE r.RATE_ID=IN_RATE_ID AND
            r.RATE_DATE<=IN_BILL_DATE AND r.STOP_DATE>=IN_BILL_DATE;

    SELECT PRICE INTO L_PRICE
    FROM RATES r
             INNER JOIN DEST_CODE dc ON dc.DEST_ID=r.code_id AND dc.code = L_MAX_CODE
    WHERE r.RATE_ID = IN_RATE_ID
    LIMIT 1;

    RETURN L_PRICE;
END;
$$ LANGUAGE plpgsql
    STABLE;


CREATE FUNCTION calc_price_t(
    IN_BILL_NUMBER VARCHAR(50),
    IN_IP VARCHAR(15),
    IN_BILL_DT timestamp with time zone
) RETURNS decimal(12,6) as $$
DECLARE L_MAX_SUBSTR VARCHAR(12);
    DECLARE L_PRICE DECIMAL(12,6) default null;
    DECLARE L_RATE_ID INT;
BEGIN

    L_MAX_SUBSTR := get_max_substring(IN_BILL_NUMBER);
    SELECT s_t.rate_t
    INTO L_RATE_ID
    FROM voip.oper_ip ip_t
             inner join voip.SITE s_t ON s_t.ID=ip_t.OP_ID
    WHERE ip_t.IP_OP=IN_IP
      AND ip_t.START_DATE<= IN_BILL_DT AND ip_t.STOP_DATE >IN_BILL_DT
    LIMIT 1;

    IF L_RATE_ID > 0 THEN
        L_PRICE := get_price(L_MAX_SUBSTR, L_RATE_ID, IN_BILL_DT);
    END IF;
    RETURN L_PRICE;

END ;
$$ LANGUAGE plpgsql
    STABLE ;

-- Для проверки работы можно вызвать вот такое
select dst_number_bill, calc_price_t(dst_number_bill, dst_ip, bill_date) from cdr;