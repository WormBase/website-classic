package databaseProcess;

import java.sql.*;

public class Database_Connection {

    private Connection conn = null;

    /** Creates a new instance of Database_Connection */
    public Database_Connection() {

        try{
            
            Class.forName("org.gjt.mm.mysql.Driver").newInstance();
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/nbrowse_wormbase","nbrowse_wormbase","qnztk27");
            
        }catch(Exception e){
            System.out.println("<< Connection Cannot be established >>" + e);
            conn = null;
        }

    }

    public Connection getConnection(){
        return conn;
    }

}
