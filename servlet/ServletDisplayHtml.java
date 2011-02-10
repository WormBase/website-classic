/*
 * ServletDisplayHtml.java: The super class of displayhtml servlets
 *
 * Created on November 6, 2000, 12:10 PM
 */

import javax.servlet.*;
import javax.servlet.http.*;

import jadex.swing.sequence.*;
import jadex.swing.map.*;

import java.io.*;
import java.net.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import java.util.*;

/**
 *
 * @author  wgm
 * @version 1.0
 */
public class ServletDisplayHtml extends HttpServlet {
    private ServletDisplayModel model = null; // The display model creating images
    private String url = null; // The url to CGI script for the this class, i.e., Locus or Clone
    private String cgiUrl = null; // The URL for top and bottom CGI
   
    public void init(ServletConfig config) throws ServletException {
      super.init(config);
    }
    
    /** set cgiUtl */
    public void setCgiUrl(String url) {
      this.cgiUrl = url;
    }
    
    /** Set and get displayModel */
    public void setModel(ServletDisplayModel model) { this.model = model; }
    
    public ServletDisplayModel getModel() { return this.model; }
    
    /** Set and get url name */
    public void setUrl(String url) {
        this.url = url;
    }
    
    public String getUrl() {
        return this.url;
    }
    
    // Create all controls for the map
    protected void createControl(PrintWriter out, String name) {
        StringBuffer buf = new StringBuffer();
        buf.append("<form action=" + "\"" + cgiUrl + "\">\n");
        buf.append("<input type=hidden name=name value=" + name + ">\n");
        buf.append("Specify a range please:\n");
        //buf.append("<br>\n");
        buf.append("Start: <input type=text size=10 name=start>\n");
        //buf.append("<br>\n");
        buf.append("End: <input type=text size=10 name=end>\n");
        buf.append("<input type=hidden name=class value=Map>\n");
        if (model.getSelectedLocus() != null) buf.append("<input type=hidden name=locus value=" + model.getSelectedLocus() + ">\n");
        //buf.append("<br>\n");
        buf.append("<input type=submit value=OK>\n");
        buf.append("</form>\n");
        out.println(buf.toString());
    }

    protected void createImageMap(PrintWriter out, float start, float end, String obj) {
        if (model == null) return ;
        Map shapes = model.getShapes();
        Set algs = model.getAlgs();
        out.println("<map name = \"shapes\">");
        Rectangle2D.Float rect = null;
        Set keys = shapes.keySet();
        for (Iterator it = keys.iterator(); it.hasNext(); ) {
            String name = (String) it.next();
            rect = (Rectangle2D.Float) shapes.get(name);
            StringBuffer coor = new StringBuffer();
            coor.append((int)rect.getX() + " ");
            coor.append((int)rect.getY() + " ");
            coor.append((int)rect.getMaxX() + " ");
            coor.append((int)rect.getMaxY());
            if (algs.contains(name)) {
                createZoomImageMap(name, coor, out, start, end, obj);
            }
            else {
                out.println("<area shape=rect coords=\""
                + coor.toString() + "\" href=\"" + url + name + "\">");
            }
        }
        out.println("</map>");
    }

    protected void createZoomImageMap(String name, StringBuffer coor, PrintWriter out, float start, float end, String obj) {
        float step = (end - start) / 4.0f;
        float s = model.START;
        float e = model.END;
        String query = null;
        if (name.equalsIgnoreCase("up")) {
            //query = new String("?name=" + obj + "&start=" + ((start + step) > e ? e : (start + step)) 
                //+ "&end=" + ((end + step) > e ? e : (end + step)));
          query = new String("?name=" + obj + "&start=" + ((start - step) < s ? s : (start - step)) 
                + "&end=" + ((end - step) < s ? s : (end - step)));
        }
        else if (name.equalsIgnoreCase("down")) {
            query = new String("?name=" + obj + "&start=" + ((start + step) > e ? e : (start + step))
            + "&end=" + ((end + step) > e ? e : (end + step)));
        }
        else if (name.equalsIgnoreCase("zoomIn")) {
            query = new String("?name=" + obj + "&start=" + (start + step) + "&end=" + (end - step));
        }
        else if (name.equalsIgnoreCase("zoomOut")) {
            query = new String("?name=" + obj + "&start=" + ((start - step) < s ? s : (start -step))
                + "&end=" + ((end + step) > e ? e : (end + step)));
        }
        else if (name.equalsIgnoreCase("reset")) {
            query = new String("?name=" + obj);
        }
        query = query + "&class=Map";
        if (model.getSelectedLocus() != null) query += "&locus=" + model.getSelectedLocus();
        out.println("<area shape=rect coords=\""
        + coor.toString() + "\" href=\"" + cgiUrl + query + "\">");
    }
    
    /** Redirect post method to get method */
    public void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException, ServletException {
      doGet(req, res);
    }    
}