/*
 * LocusDisplayHtml.java
 *
 * Created on September 30, 2000, 10:09 AM
 */
import javax.servlet.*;
import javax.servlet.http.*;

import java.util.*;
import java.io.*;
import java.net.*;
import java.awt.geom.*;

import jadex.swing.map.*;
/**
 *
 * @author  Guanming Wu
 * @version
 */
public class LocusDisplayHtml extends ServletDisplayHtml {

    private LocusDisplayModel model = LocusDisplayModel.getInstance();
    private final String WORMBASE_LOCUS = new String("http://www.wormbase.org/perl/ace/elegans/gene/locus?name=");
    private String url = null; // The url for locus linking.
    private String self = new String("LocusDisplayHtml");
    private String imageUrl = new String("LocusDisplayImage");
    private String fullImgUrl = null; // The full url for image
    private String realPath = null; // The real path of this servlet

    //These informatin should get from HttpRequest
    private String scriptUrl = null; // The calling script full URL
    private String aceHost = null; // AceDB server name
    private String acePort = null; // AceDB port number

    /** Several initial variables */
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        super.setModel(model);
        //super.setUrl(url);
        if (realPath == null) {
            String tmp = config.getServletContext().getRealPath("");
            // Under Windows95, this tmp ends with "/", while under Win98 and
            // Linux, ends with "//".
            if (tmp.endsWith("//")) {
                int pos = tmp.lastIndexOf(File.separator);
                realPath = tmp.substring(0, pos); // Get rid of the last slash.
            }
            else realPath = tmp;
            model.setPath(realPath);
        }
    }

    public synchronized void doGet(HttpServletRequest req, HttpServletResponse res)
    throws ServletException, IOException {

        // Construct the full image url
        //if (fullImgUrl == null) {
        String tmp = HttpUtils.getRequestURL(req).toString();
        int pos = tmp.indexOf(self);
        String pref = tmp.substring(0, pos);
        fullImgUrl = pref + imageUrl;
        //}
        // Set up JSAceAccessor on model
        //if ((aceHost == null) || (acePort == null)) {
        aceHost = req.getParameter("server");
        if (aceHost == null) aceHost = "www.wormbase.org";
        acePort = req.getParameter("aceport");
        if (acePort == null) acePort = "2005";
        model.setAceAccessor(aceHost, acePort);
        //}

        // Get the url for Locus detail information.
        url = req.getParameter("linkurl");
        if (url == null) url = WORMBASE_LOCUS;
        super.setUrl(url);
        
        // Get the selected locus name
        String locus = req.getParameter("locus");
        model.setSelectedLocus(locus);
        
        // Set the cgiUrl
        //if (scriptUrl == null) {
        scriptUrl = req.getParameter("script");
        if (scriptUrl == null) scriptUrl = self;
        super.setCgiUrl(scriptUrl);
        
        //}
               
        String start = req.getParameter("start");
        String end = req.getParameter("end");
        String name = req.getParameter("name");


        res.setContentType("text/html");
        PrintWriter out = res.getWriter();
        //out.println("<html>");
        //out.println("<head><title>An ImageMap Test for Servlet</title></head>");
        //out.println("<body>");

        boolean isFileModel = false;

        if ((name==null) || (name.length() == 0)) {
            name = "I";
            isFileModel = true;
        }

        //printTop(out, name);

        //synchronized(this) {
        if (isFileModel)   model.setFileModel();
        else model.setAceObject(name);

        float s, e;
        if ((start == null) || (start.length() == 0))  s = model.getStart();
        else s = Float.parseFloat(start);
        if ((end == null) || (end.length() == 0))  e = model.getEnd();
        else e = Float.parseFloat(end);

        model.createImage(new MapRange(s, e));
        String query = new String("?name=" + name + "&start=" + s + "&end=" + e);
        if (locus != null) query += "&locus=" + locus;
        out.println(); // Just for a new line
        //out.println("<img src=\"" +fullImgUrl + query + "\" usemap=\"#shapes\" border=0>");
        out.println("<img src=\"" +fullImgUrl + query + "\" usemap=\"#shapes\" border=0 " +
            "width=\"" + (int)model.WIDTH + "\" height=\"" + (int) model.HEIGHT + "\">");
        createImageMap(out, s, e, name);
        //}
        createControl(out, name);
        //out.println("</body></html>");
        //printBottom(out);
    }
}