package databaseProcess;

import java.sql.*;
import java.io.*;

public class genSIF{

   String userID;
   String filename;
   String taxon_id;
   File output;
   BufferedWriter out;
   

   public genSIF(String userID){
     try{
      this.userID=userID;
      filename = "./temp_data/"+userID+"/sample.sif" ;
      output = new File(filename) ;
      output.createNewFile();
      out = new BufferedWriter( new FileWriter(output.getPath(), true) ) ;
     }catch (IOException io) {
            System.out.println("Error: IOException, " + io) ;

     }
   }
   
   private void addUDNearEdge( String user_id, Connection conn, String selectStat1, String selectStat2){
      try{
          if(conn == null){return;}
          Statement stat = null;
          ResultSet rs = null;
          stat = conn.createStatement();
          rs = stat.executeQuery("select p.node1, p.node2, p.value, p.type, p.dataset from ud_interaction p, ("+selectStat1+") as n1, ("+selectStat2+") as n2 WHERE p.node1 = n1.node_primary_name AND p.node2 = n2.node_primary_name and p.UID = '"+user_id+"';");
          while(rs.next()){
              String text = rs.getString("node1")+" "+rs.getString("type")+" "+ rs.getString("node2");
              for (int i = 0 ; i < text.length(); i++) {
		             	out.write(text.charAt(i)) ;
		          }
		          out.write("\n");
              //EdgeInfo ei;
	            //if(rs.getString("value") != null){
	            //      	ei= new EdgeInfo(rs.getString("node1"), rs.getString("node2"), rs.getString("type"), rs.getString("dataset"), true, rs.getDouble("value"));
	            //}else{
	            //    ei= new EdgeInfo(rs.getString("node1"), rs.getString("node2"), rs.getString("type"), rs.getString("dataset"), false, 0.0);
	            //}
              //allEdgeSet.put(ei.getFrom()+ei.getTo()+ei.getRelation(), ei);
          }
      }catch(SQLException ex){
            System.out.println("SQLException4: " + ex.getMessage());
            System.out.println("SQLState: " + ex.getSQLState());
            System.out.println("VendorError: " + ex.getErrorCode());
      }catch(Exception e){
            System.out.println(e);
      }
   }

   private void addNearEdge(Connection conn, String selectStat1, String selectStat2, String user_id){
      try{
          if(conn == null){return;}
          Statement stat = null;
          ResultSet rs = null;
          boolean isUsingDefault = false;
          stat = conn.createStatement();
          rs = stat.executeQuery("SELECT * from ud_schema  where user_id =  '"+user_id+"';");                     
          if(!rs.next()) isUsingDefault = true;
          
          rs = stat.executeQuery("SELECT * from ud_schema  where type like 'UD_%' and user_id =  '"+user_id+"';");                     
          if(rs.next()) isUsingDefault = true;
          
          rs = stat.executeQuery("SELECT * from ud_schema  where type not like 'UD_%' and user_id = '"+user_id+"';");                     
          if(rs.next()) isUsingDefault = false;
          
          if(isUsingDefault)
             rs = stat.executeQuery("SELECT distinct p. * FROM gnb_interactions p, ("+selectStat1+") AS n1, ("+selectStat2+") AS n2 WHERE p.from_node_primary_name = n1.node_primary_name AND p.to_node_primary_name = n2.node_primary_name;");
          else
             rs = stat.executeQuery("SELECT distinct p. * FROM gnb_interactions p, ("+selectStat1+") AS n1, ("+selectStat2+") AS n2, ud_schema AS u WHERE p.from_node_primary_name = n1.node_primary_name AND p.to_node_primary_name = n2.node_primary_name AND u.user_id =  n1.user_id AND u.type = p.edge_type AND u.dataset = p.edge_dataset AND ( p.edge_value IS  NULL  OR ( p.edge_value >= u.min AND p.edge_value <= u.max ) );");
          
                     while(rs.next()){
                      	String text = rs.getString("from_node_primary_name")+" "+rs.getString("edge_type")+" "+ rs.getString("to_node_primary_name");
                        for (int i = 0 ; i < text.length(); i++) {
		                       	out.write(text.charAt(i)) ;
		                    }
		                    out.write("\n");
                      	
                     }

      }catch(SQLException ex){
            System.out.println("SQLException5: " + ex.getMessage());
            System.out.println("SQLState: " + ex.getSQLState());
            System.out.println("VendorError: " + ex.getErrorCode());
      }catch(Exception e){
            System.out.println(e);
      }
   }
   public void checkSpecies(){
      try{
          Database_Connection dbconn = new Database_Connection();
          Connection conn = dbconn.getConnection();

          if(conn == null){return;}
          Statement stat = null;
          ResultSet rs = null;

          stat = conn.createStatement();
          rs = stat.executeQuery("select taxon_id from gnb_all where user_id ='"+userID+"';");
          if(rs.next())taxon_id = rs.getString("taxon_id");
          conn.close();
      }catch(SQLException ex){
            System.out.println("SQLException: " + ex.getMessage());
            System.out.println("SQLState: " + ex.getSQLState());
            System.out.println("VendorError: " + ex.getErrorCode());

      }catch(Exception e){
            System.out.println(e);
      }
   }

   public void buildSIF(){
   	  checkSpecies();
      String select_statement = "select node_primary_name, user_id from gnb_all where user_id ='"+userID+"' and taxon_id ="+taxon_id+"";
      try{
           Database_Connection dbconn = new Database_Connection();
           Connection conn = dbconn.getConnection();
           if(taxon_id != null){
                if(taxon_id.equals("0")){
                   addUDNearEdge(userID, conn, select_statement, select_statement);                   
                }else{
                   addNearEdge( conn, select_statement, select_statement, userID);
                   addUDNearEdge(userID, conn, select_statement, select_statement);
                }
           }
           conn.close();
           out.close();
      }catch (IOException io) {
            System.out.println("Error: IOException, " + io) ;

      }catch(SQLException ex){
            System.out.println("SQLException: " + ex.getMessage());
            System.out.println("SQLState: " + ex.getSQLState());
            System.out.println("VendorError: " + ex.getErrorCode());

      }catch(Exception e){
            System.out.println(e);
      }
   }

   public static void main(String [] args){
       genSIF gsif = new genSIF(args[0]);
       gsif.buildSIF();
   }
}
