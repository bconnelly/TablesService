package com.fullstack.tableservice;

import com.fullstack.tableservice.DBAccessEntities.Table;
import com.fullstack.tableservice.DomainLogic.TableLogic;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@SpringBootTest
class TableServiceApplicationTest {

    @InjectMocks
    private TableServiceApplication application;

    @Mock
    private TableLogic tableLogicMock;

    @Test
    void getAllTables() {
        List<Table> expected = new ArrayList<>();
        expected.add(Table.builder().tableNumber(1).capacity(2).build());
        expected.add(Table.builder().tableNumber(2).capacity(6).build());
        when(tableLogicMock.getAllTables()).thenReturn(expected);

        List<Table> response = application.getAllTables();

        assertEquals(response, expected);
        verify(tableLogicMock, times(1)).getAllTables();
    }

    @Test
    void tableExists() {
        when(tableLogicMock.tableExists(5)).thenReturn(true);

        assertTrue(application.tableExists(5));
        verify(tableLogicMock, times(1)).tableExists(5);
    }
}