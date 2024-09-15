create table tables
(
    id integer       auto_increment
        primary key,
    table_number int not null,
    capacity     int not null,
    constraint tables_unique_1 unique (table_number)
);

create table customers
(
    id           int auto_increment
        primary key,
    first_name   varchar(50) not null,
    table_number int         not null,
    cash         float       not null,
    address      varchar(50) not null,
    constraint customers_unique_1 unique (first_name),
    constraint customers_fk_1 foreign key (table_number) references tables(table_number)
);

create table orders
(
    id           int auto_increment
        primary key,
    first_name   varchar(50) not null,
    dish         varchar(50) not null,
    table_number int         not null,
    bill         float       not null,
    served       bool        null default false
);