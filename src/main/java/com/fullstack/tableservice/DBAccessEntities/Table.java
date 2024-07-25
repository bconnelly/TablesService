package com.fullstack.tableservice.DBAccessEntities;

import lombok.*;

import jakarta.persistence.*;

@Setter
@Getter
@AllArgsConstructor
@NoArgsConstructor
@Builder

@Entity
@jakarta.persistence.Table(name = "tables")
public class Table {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false, nullable = false)
    private Integer id;
    private Integer tableNumber;
    private Integer capacity;

    public String toString() {

        return "[table_number: " + tableNumber +
                ", capacity: " + capacity + "]";
    }

    public boolean equals(Table table) {
        return (table.tableNumber.equals(this.tableNumber) &&
                table.capacity.equals(this.capacity));
    }
}
