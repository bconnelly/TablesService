insert into tables (table_number, capacity) VALUES (1, 2);
insert into tables (table_number, capacity) VALUES (2, 2);
insert into tables (table_number, capacity) VALUES (3, 4);
insert into tables (table_number, capacity) VALUES (4, 4);
insert into tables (table_number, capacity) VALUES (5, 6);

insert into customers (first_name, table_number, cash, address)
VALUES ('alice', 1, 12.34, '123 main st');
insert into customers (first_name, table_number, cash, address)
VALUES ('bob', 3, 2.34, '124 main st');
insert into customers (first_name, table_number, cash, address)
VALUES ('chuck', 3, 5.00, '125 main st');
insert into customers (first_name, table_number, cash, address)
VALUES ('dave', 1, 100.00, '126 main st');
insert into customers (first_name, table_number, cash, address)
VALUES ('ed', 2, 1.23, '127 main st');
insert into customers (first_name, table_number, cash, address)
VALUES ('fred', 2, 11.23, '128 main st');
insert into customers (first_name, table_number, cash, address)
VALUES ('george', 4, 0.23, '129 main st');

insert into orders (first_name, dish, table_number, bill, served)
VALUES ('alice', 'coke', 1, 2.01, false);
insert into orders (first_name, dish, table_number, bill, served)
VALUES ('bob', 'pizza', 2, 5.12, false);
insert into orders (first_name, dish, table_number, bill, served)
VALUES ('chuck', 'salad', 3, 5.12, false);
insert into orders (first_name, dish, table_number, bill, served)
VALUES ('dave', 'burger', 4, 4.49, false);
insert into orders (first_name, dish, table_number, bill, served)
VALUES ('ed', 'tacos', 5, 4.00, true);
insert into orders (first_name, dish, table_number, bill, served)
VALUES ('ed', 'dr p', 5, 2.01, true);
insert into orders (first_name, dish, table_number, bill, served)
VALUES ('fred', 'dr p', 5, 12.01, true);
insert into orders (first_name, dish, table_number, bill, served)
VALUES ('george', 'dr p', 5, 2.11, true);