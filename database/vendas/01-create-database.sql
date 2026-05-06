/* ============================================================================
   ERP VENDAS - Criacao do banco de dados Firebird 3.0
   Execute via isql:  isql -u SYSDBA -p masterkey -i 01-create-database.sql
   Ajuste o caminho do arquivo .FDB conforme seu ambiente.
   ============================================================================ */

CREATE DATABASE 'C:\CartSys\DB\ERP_VENDAS.FDB'
    USER 'SYSDBA' PASSWORD 'masterkey'
    PAGE_SIZE 16384
    DEFAULT CHARACTER SET UTF8 COLLATION UTF8;
