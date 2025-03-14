package com.fullstack.tableservice;

import com.fullstack.tableservice.DBAccessEntities.Table;
import com.fullstack.tableservice.DomainLogic.TableLogic;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Slf4j
@RestController
@SpringBootApplication
public class TableServiceApplication extends SpringBootServletInitializer {

    public static void main(String[] args) {
        SpringApplication.run(TableServiceApplication.class, args);
    }


    //need to use field injection here because tomcat needs a no-args constructor, so constructor autowiring won't work
    @Autowired
    private TableLogic tableLogic;

    @GetMapping(path = "/table/all")
    public List<Table> getAllTables(){
        log.debug("getAllTables requested");
        return tableLogic.getAllTables();
    }

    @GetMapping(path = "/table/exists")
    public Boolean tableExists(Integer tableNumber){
        log.debug("tableExists requested");
        return tableLogic.tableExists(tableNumber);
    }
}