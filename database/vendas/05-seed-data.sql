/* ============================================================================
   ERP VENDAS - Massa de teste
   ============================================================================ */

INSERT INTO CLIENTES (NOME, CPF_CNPJ, EMAIL, TELEFONE, ENDERECO, CIDADE, UF, CEP)
VALUES ('Cliente Teste 01', '12345678901', 'cliente01@teste.com', '11999990001', 'Rua A, 100', 'Sao Paulo', 'SP', '01000-000');

INSERT INTO CLIENTES (NOME, CPF_CNPJ, EMAIL, TELEFONE, ENDERECO, CIDADE, UF, CEP)
VALUES ('Empresa Exemplo LTDA', '12345678000190', 'contato@empresaexemplo.com', '1133334444', 'Av. Paulista, 1000', 'Sao Paulo', 'SP', '01310-100');

INSERT INTO PRODUTOS (CODIGO, DESCRICAO, UNIDADE, PRECO_VENDA, ESTOQUE)
VALUES ('P001', 'Notebook Dell Inspiron', 'UN', 4500.00, 10);

INSERT INTO PRODUTOS (CODIGO, DESCRICAO, UNIDADE, PRECO_VENDA, ESTOQUE)
VALUES ('P002', 'Mouse sem fio Logitech', 'UN', 120.00, 50);

INSERT INTO PRODUTOS (CODIGO, DESCRICAO, UNIDADE, PRECO_VENDA, ESTOQUE)
VALUES ('P003', 'Teclado mecanico ABNT2', 'UN', 350.00, 30);
