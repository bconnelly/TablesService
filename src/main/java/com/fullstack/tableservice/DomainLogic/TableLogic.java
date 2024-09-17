package com.fullstack.tableservice.DomainLogic;

import com.fullstack.tableservice.DBAccessEntities.Table;
import com.fullstack.tableservice.Repositories.TableRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
public class TableLogic {

    private final TableRepository tableRepository;


    public TableLogic(TableRepository tableRepository){
        this.tableRepository = tableRepository;
    }

    public List<Table> getAllTables (){
        return tableRepository.findAll();
    }

    public Boolean tableExists(Integer tableNumber) throws IllegalArgumentException {
        if(tableNumber == null || tableNumber < 1) throw new IllegalArgumentException("invalid table number");
        return tableRepository.existsByTableNumber(tableNumber);
    }
}
