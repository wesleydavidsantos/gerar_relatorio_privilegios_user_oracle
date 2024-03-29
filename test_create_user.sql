--
-- User creation and permission granting
-- Criação dos usuários e concessão de permissões
--
DECLARE
    TYPE username_array IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
    v_usernames username_array;
    v_password VARCHAR2(50);
    v_grant_type VARCHAR2(50);
    v_sql VARCHAR2(1000);
    CURSOR c_grants IS
        SELECT
			PRIVILEGE
        FROM (
				SELECT 
					DISTINCT PRIVILEGE
				FROM
					(
						SELECT PRIVILEGE FROM DBA_SYS_PRIVS
						UNION ALL
						SELECT PRIVILEGE FROM DBA_TAB_PRIVS
						UNION ALL
						SELECT GRANTED_ROLE AS PRIVILEGE FROM DBA_ROLE_PRIVS
					)
				ORDER BY DBMS_RANDOM.VALUE()
			  )
        WHERE rownum <= DBMS_RANDOM.VALUE(5, 10); -- Seleciona aleatoriamente entre 5 e 10 privilégios
BEGIN
    FOR i IN 1..50 LOOP
        -- Gerar nome de usuário e senha
        v_usernames(i) := 'USER_' || UPPER(DBMS_RANDOM.STRING('A', 5) || '_' || DBMS_RANDOM.STRING('A', 5));
        v_password := v_usernames(i); -- Senha é o próprio nome de usuário
        
        -- Criar usuário
        --EXECUTE IMMEDIATE 'CREATE USER ' || v_usernames(i) || ' IDENTIFIED BY ' || v_password;
		
		DBMS_OUTPUT.PUT_LINE( '' );
		DBMS_OUTPUT.PUT_LINE( '' );
		
		DBMS_OUTPUT.PUT_LINE( 'CREATE USER ' || v_usernames(i) || ' IDENTIFIED BY ' || v_password );
		
        -- Conceder permissões aleatórias
        FOR grant_rec IN c_grants LOOP
            -- Conceder permissão ao usuário
            --EXECUTE IMMEDIATE 'GRANT ' || grant_rec.PRIVILEGE || ' TO ' || v_usernames(i);
			
			DBMS_OUTPUT.PUT_LINE( 'GRANT ' || grant_rec.PRIVILEGE || ' TO ' || v_usernames(i) );
			
        END LOOP;
    END LOOP;
	
	DBMS_OUTPUT.PUT_LINE( '' );	
	DBMS_OUTPUT.PUT_LINE( '' );
	DBMS_OUTPUT.PUT_LINE( '' );
	
	

    -- Drop cascade dos usuários
    FOR j IN 1..v_usernames.COUNT LOOP
        -- Drop cascade do usuário
        --EXECUTE IMMEDIATE 'DROP USER ' || v_usernames(j) || ' CASCADE';
		
		DBMS_OUTPUT.PUT_LINE( 'DROP USER ' || v_usernames(j) || ' CASCADE' );
		
    END LOOP;
END;
/
