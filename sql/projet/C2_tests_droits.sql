\set ON_ERROR_STOP on

CREATE FUNCTION pg_temp.tester(p_role text, p_sql text, p_autorise boolean)
RETURNS text LANGUAGE plpgsql AS $f$
DECLARE v_ok boolean;
BEGIN
    RESET ROLE;
    BEGIN
        EXECUTE format('SET LOCAL ROLE %I', p_role);
        EXECUTE p_sql;
        v_ok := true;
    EXCEPTION WHEN insufficient_privilege THEN
        v_ok := false;
    END;
    RESET ROLE;
    RETURN format('%s | %-13s | %-12s | %s',
                CASE WHEN v_ok = p_autorise THEN 'PASS' ELSE 'FAIL' END , p_role,
                CASE WHEN v_ok THEN 'autorisé' ELSE 'refusé' END , p_sql);
END $f$;

SELECT pg_temp.tester('analyst_login','SELECT count(*) FROM retail.orders', true);
SELECT pg_temp.tester('analyst_login','UPDATE retail.orders SET status = status WHERE false', false);
SELECT pg_temp.tester('analyst_login','DELETE FROM retail.orders WHERE false', false);
SELECT pg_temp.tester('analyst_login','CREATE TABLE retail.test_interdit(i int)', false);
SELECT pg_temp.tester('app_login'    ,'UPDATE retail.orders SET status = status WHERE false', true);
SELECT pg_temp.tester('app_login'    ,'INSERT INTO retail.orders SELECT * FROM retail.orders WHERE false', true);
SELECT pg_temp.tester('app_login'    ,'DELETE FROM retail.orders WHERE false', false);
SELECT pg_temp.tester('app_login'    ,'UPDATE retail.products SET list_price = list_price WHERE false', false);