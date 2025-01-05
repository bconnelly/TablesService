package com.fullstack.tableservice.DomainLogic;

import com.fullstack.tableservice.DBAccessEntities.Table;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertThrows;

@SpringBootTest
class TableLogicTest {

    @Autowired
    TableLogic tableLogic;

    @Test
    void getAllTablesTest() {
        List<Table> tables = tableLogic.getAllTables();
        assert(tables.get(0).getCapacity().equals(2));
        assert(tables.get(1).getCapacity().equals(2));
        assert(tables.get(2).getCapacity().equals(4));
        assert(tables.get(3).getCapacity().equals(4));
        assert(tables.get(4).getCapacity().equals(6));
        assert(tables.size() == 5);
    }

    @Test
    void tableExistsTest(){
        assert(tableLogic.tableExists(1));
        assert(tableLogic.tableExists(2));
        assert(tableLogic.tableExists(3));
        assert(tableLogic.tableExists(4));
        assert(tableLogic.tableExists(5));
    }

    @Test
    void tableExistsBadTableTest(){
        assert(!tableLogic.tableExists(6));
        assertThrows(IllegalArgumentException.class, () -> tableLogic.tableExists(0));
        assertThrows(IllegalArgumentException.class, () -> tableLogic.tableExists(-1));
        assertThrows(IllegalArgumentException.class, () -> tableLogic.tableExists(null));
    }
}