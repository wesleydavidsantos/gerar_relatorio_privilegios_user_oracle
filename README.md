# Generate Oracle User Privilege Reports / Gerar Relatórios de Privilégios de Usuários do Oracle

Simple and practical script that allows the DBA to generate a report listing the access privileges of any user within the Oracle database.

Script simples e prático que permite o DBA gerar um relatório que lista os privilégios de acesso de qualquer usuário dentro do banco de dados Oracle.



# How It Works / Como Funciona

Running this PL/SQL script enables you to create a detailed HTML report on your local machine, listing each Oracle user along with their access privileges and permissions, all separated by privilege type.

A execução deste script PL/SQL permite que você crie em sua maquina local um relatório em formato HTML que lista de forma detalhada cada usuário do Oracle e seus privilégios e permissões de acesso, tudo isso separados por tipo de privilégio.


# Usage / Modo de Usar

To demonstrate the functionality of this reporting script in a test environment, it was necessary to develop a script that creates new users and grants some permissions randomly, allowing for a comprehensive presentation of the system's functionality.

Para poder apresentar o funcionamento deste script de relatório em uma base de testes, foi necessário desenvolver um script que realiza a criação de novos usuários e concede algumas permissões de forma aleatória, permitindo assim uma boa apresentação do funcionamento do sistema.


**Creating users and granting permissions / Criação dos usuários e concessão de permissões**


```sql
-- Criação dos usuários e concessão de permissões
-- Autor: Wesley David Santos

DECLARE

    TYPE USERNAME_ARRAY IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
    
    v_USERNAMES USERNAME_ARRAY;
    
    v_GRANT_TYPE VARCHAR2(50);
	
    v_SQL VARCHAR2(1000);
	
    CURSOR c_GRANTS IS
        SELECT
			PRIVILEGE
        FROM
			(
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

        WHERE ROWNUM <= DBMS_RANDOM.VALUE(5, 10); -- Seleciona aleatoriamente entre 5 e 10 privilégios
		
BEGIN

    FOR I IN 1..50 LOOP
        
		-- GERAR NOME DE USUÁRIO E SENHA
    v_USERNAMES(I) := 'USER_' || UPPER(DBMS_RANDOM.STRING('A', 5) || '_' || DBMS_RANDOM.STRING('A', 5));
        
        
    DBMS_OUTPUT.PUT_LINE( '' );
		DBMS_OUTPUT.PUT_LINE( '' );
		
		-- CRIAR USUÁRIO
		DBMS_OUTPUT.PUT_LINE( 'CREATE USER ' || V_USERNAMES(I) || ' IDENTIFIED BY ' || v_USERNAMES(I) || ';'  );
		
		
        -- CONCEDER PERMISSÕES ALEATÓRIAS
        FOR GRANT_REC IN C_GRANTS LOOP
        
          -- CONCEDER PERMISSÃO AO USUÁRIO
          DBMS_OUTPUT.PUT_LINE( 'GRANT ' || GRANT_REC.PRIVILEGE || ' TO ' || V_USERNAMES(I) || ';' );
			
        END LOOP;
		
    END LOOP;
	
	DBMS_OUTPUT.PUT_LINE( '' );	
	DBMS_OUTPUT.PUT_LINE( '' );
	DBMS_OUTPUT.PUT_LINE( '' );
	
	

    -- DROP CASCADE DOS USUÁRIOS
    FOR J IN 1..V_USERNAMES.COUNT LOOP
        
		-- DROP CASCADE DO USUÁRIO
        DBMS_OUTPUT.PUT_LINE( 'DROP USER ' || V_USERNAMES(J) || ' CASCADE;' );
		
    END LOOP;
	
END;
/
```



# Report Script / Script do Relatório



**Script to generate the HTML report / Script para gerar o relatório em HTML**

* Note: It is necessary to execute the entire script at once. /  Observação: É necessário executar todo o script de uma única vez. *

```sql

-- Script para gerar o relatório em HTML
-- Observação: É necessário executar todo o script de uma única vez.
-- Autor: Wesley David Santos

SET SERVEROUTPUT ON;
      
exec DBMS_OUTPUT.ENABLE (buffer_size => NULL);

spool "C:\MEU_DIRETORIO\Lista_Permissoes.html"
SET ECHO OFF;
SET FEEDBACK OFF


DECLARE

	-- Nome do seu cliente
	NOME_CLIENTE VARCHAR2(300) := 'Mouse Mágico Tecnologia Ltda';

	-- Nome do DBA que está gerando o relatório
    NOME_DBA_RESPONSAVEL VARCHAR2(300) := 'Wesley David Santos';

    DATA_ATUAL VARCHAR2(255); -- Nao Mexer - Flag usada para informa se existe GRANT para execuçao manual
	
	NOME_DATABASE VARCHAR2(10);


	PROCEDURE LISTA_PERMISSAO( par_username VARCHAR2, par_created VARCHAR2, par_account_status VARCHAR2, par_lock_date VARCHAR2 )
	IS
		
		--name_user VARCHAR2(255) := '"'||par_username||'"'; -- Nao Mexer - Nome do usuário concatenado com aspas duplas
		
		-- Retorna a lista de permissÃµes
		CURSOR c_etlPERMISSOES IS
									WITH 
										TBL_LIST_PRIVILEGE_OBJECT AS (				  
											SELECT DISTINCT 
												OWNER, 
												PRIVILEGE
											FROM
											(
												SELECT DISTINCT 
													OWNER, PRIVILEGE
												FROM
													DBA_TAB_PRIVS
												WHERE 
													 GRANTEE = par_username
											)
										),
										TBL_LIST_PRIVILEGE_USER AS (
											select OWNER, PRIVILEGE from (
												select DISTINCT 
													'SISTEMA' AS OWNER,
													PRIVILEGE AS PRIVILEGE
												from 
													dba_sys_privs
												where grantee = UPPER( par_username )
											union all
												select DISTINCT
													OWNER,
													PRIVILEGE PRIVILEGE
												from 
													dba_tab_privs
												where grantee = UPPER( par_username )
											union all
												select 
													'ROLE' AS OWNER,
													 GRANTED_ROLE PRIVILEGE
												from 
													dba_role_privs
												where grantee = UPPER( par_username ))
										),
										TBL_UNION_GRANT AS (
											SELECT DISTINCT
												OWNER OWNER,
												PRIVILEGE PRIVILEGE
											FROM
												(
													SELECT
														OWNER OWNER,
														PRIVILEGE PRIVILEGE
													FROM
														TBL_LIST_PRIVILEGE_USER
													UNION ALL
													SELECT
														OWNER OWNER,
														PRIVILEGE PRIVILEGE
													FROM
														TBL_LIST_PRIVILEGE_OBJECT
												)
											ORDER BY OWNER, PRIVILEGE
										)
									SELECT
										OWNER,
										rtrim(xmlagg(XMLELEMENT(e,PRIVILEGE,', ').EXTRACT('//text()') ).GetClobVal(), ', ') PRIVILEGE
									FROM
										TBL_UNION_GRANT
									GROUP BY
									   OWNER
									ORDER BY
										OWNER;
			
			
	BEGIN
	
		DBMS_OUTPUT.PUT_LINE( '<table id="customers">' );
		
		DBMS_OUTPUT.PUT_LINE( '<tr>' );
		
			DBMS_OUTPUT.PUT_LINE( '<td align="center" class="name_user">' );
			DBMS_OUTPUT.PUT_LINE( 'USER:  ' );	
			DBMS_OUTPUT.PUT_LINE( par_username || '<br />( Status: ' || par_account_status || ' )' );	
			DBMS_OUTPUT.PUT_LINE( '</td>' );
			
			DBMS_OUTPUT.PUT_LINE( '<td align="center" class="name_user">' );
			DBMS_OUTPUT.PUT_LINE( 'Data criado: ' || par_created );
			DBMS_OUTPUT.PUT_LINE( '<br />' );
			DBMS_OUTPUT.PUT_LINE( 'Data bloqueio: ' || par_lock_date );
			DBMS_OUTPUT.PUT_LINE( '</td>' );
						
		DBMS_OUTPUT.PUT_LINE( '</tr>' );
		
		DBMS_OUTPUT.PUT_LINE( '<table>' );
		
		DBMS_OUTPUT.PUT_LINE( '<table id="customers">' );
		
		DBMS_OUTPUT.PUT_LINE( '<tr><th>OWNER</th><th>PRIVILEGE</th></tr>' );	
		
	
		FOR I IN c_etlPERMISSOES
		
        LOOP
			
			DBMS_OUTPUT.PUT_LINE( '<tr>' );			
				
				DBMS_OUTPUT.PUT_LINE( '<td>' );
					DBMS_OUTPUT.PUT_LINE( I.OWNER ); 
				DBMS_OUTPUT.PUT_LINE( '</td>' );					
				
				DBMS_OUTPUT.PUT_LINE( '<td>' );
					DBMS_OUTPUT.PUT_LINE( I.PRIVILEGE ); 
				DBMS_OUTPUT.PUT_LINE( '</td>' );					
				
			DBMS_OUTPUT.PUT_LINE( '</tr>' );			
		
		END LOOP;	

		DBMS_OUTPUT.PUT_LINE( '</table>' );
		
		DBMS_OUTPUT.PUT_LINE( '<br /><br />' );
		
		
	END;
	
	
	PROCEDURE CATALOG_USERS
    IS	 
		-- Retorna a lista de permissÃµes
		CURSOR c_etlLISTA_USERS IS
			-- SELECT USERNAME FROM DBA_USERS WHERE USERNAME NOT IN ('SYS', 'SYSTEM') ORDER BY USERNAME ASC;
			SELECT USERNAME,CREATED, ACCOUNT_STATUS, LOCK_DATE FROM DBA_USERS ORDER BY USERNAME ASC;
		
	   
	BEGIN
		FOR U IN c_etlLISTA_USERS
			
		LOOP
		
			-- Chama a procedure de lista de permissoes
			LISTA_PERMISSAO(U.USERNAME, U.CREATED, U.ACCOUNT_STATUS, U.LOCK_DATE);
		
		END LOOP;
		
	END;    
	
	
BEGIN

	SELECT TO_CHAR(sysdate, 'DD "de" fmMonth "de" YYYY','NLS_DATE_LANGUAGE=PORTUGUESE') || ' - ' || TO_CHAR(sysdate, 'HH24:MI:SS') INTO DATA_ATUAL FROM DUAL;
	
	SELECT NAME INTO NOME_DATABASE FROM SYS.V$DATABASE;

	DBMS_OUTPUT.PUT_LINE( '<!DOCTYPE html>' );
	DBMS_OUTPUT.PUT_LINE( '<html>' );
	DBMS_OUTPUT.PUT_LINE( '<head>' );
	DBMS_OUTPUT.PUT_LINE( '<meta name="author" content="Wesley David Santos">' );
    DBMS_OUTPUT.PUT_LINE( '<meta name="description" content="Sistema de geração de relatório automático sobre privilégios de usuário. Projeto compartilhado para a comunidade DBA. github: https://github.com/wesleydavidsantos">' );	
	DBMS_OUTPUT.PUT_LINE( '<style> #customers { font-family: "Trebuchet MS", Arial, Helvetica, sans-serif; border-collapse: collapse; width: 100%; } #customers td, #customers th { border: 1px solid #ddd; padding: 8px; } #customers tr:nth-child(even){background-color: #f2f2f2;} #customers tr:hover {background-color: #ddd;} #customers th { padding-top: 12px; padding-bottom: 12px; text-align: left; background-color: #4CAF50; color: white; } .header { padding: 60px; text-align: center; background: #1abc9c; color: white; font-size: 30px; } .name_user { background-color: blue; color: #fff; font-weight: bold; font-size: 30px; }</style>' );
	DBMS_OUTPUT.PUT_LINE( '</head>' );
	DBMS_OUTPUT.PUT_LINE( '<body>' );
	
	DBMS_OUTPUT.PUT_LINE( '<div class="header">' );
	  DBMS_OUTPUT.PUT_LINE( '<h1>' || NOME_CLIENTE || '</h1>' );
	  DBMS_OUTPUT.PUT_LINE( '<h2>Database: ' || NOME_DATABASE || '</h2>' );
	  DBMS_OUTPUT.PUT_LINE( '<p>Relatório: Lista de permissoes dos usuários</p>' );
	  DBMS_OUTPUT.PUT_LINE( '<p style="font-size: 20px;">DBA: ' || NOME_DBA_RESPONSAVEL || '</p>' );
	DBMS_OUTPUT.PUT_LINE( '</div>' );
	
	
	-- Chama a procedure para catalogar os usuários a serem listados
	CATALOG_USERS;
	
	
	DBMS_OUTPUT.PUT_LINE( '<div>' );
		DBMS_OUTPUT.PUT_LINE( '<p>' );
			DBMS_OUTPUT.PUT_LINE( 'Belo Horizonte, ' );
			DBMS_OUTPUT.PUT_LINE( DATA_ATUAL );
		DBMS_OUTPUT.PUT_LINE( '</p>' );
	DBMS_OUTPUT.PUT_LINE( '</div>' );
	
	
	DBMS_OUTPUT.PUT_LINE( '</body>' );
	DBMS_OUTPUT.PUT_LINE( '</html>' );	
	
END;
/



spool off
set serveroutput off;
set echo off;
```



