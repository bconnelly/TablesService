package com.fullstack.tableservice.DomainLogic;

import com.fullstack.tableservice.DBAccessEntities.Table;
import com.fullstack.tableservice.Repositories.TableRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
public class TableLogic {

    TableRepository tableRepository;

    @Autowired
    public TableLogic(TableRepository repository){
        this.tableRepository = repository;
    }

    public List<Table> getAllTables (){
        return tableRepository.findAll();
    }

    public Boolean tableExists(Integer tableNumber){
        return tableRepository.existsByTableNumber(tableNumber);
    }
}
