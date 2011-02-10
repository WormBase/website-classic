/*
 * LocusDisplayImage.java
 *
 * Created on September 30, 2000, 11:41 AM
 */

import javax.servlet.*;
import javax.servlet.http.*;

import java.awt.image.*;
import java.io.*;
import com.sun.image.codec.jpeg.*;

import jadex.swing.map.MapRange;

/**
 *
 * @author  Guanming Wu
 * @version 
 */
public class LocusDisplayImage extends HttpServlet {

    private LocusDisplayModel model = LocusDisplayModel.getInstance();
    
    public void doGet(HttpServletRequest req, HttpServletResponse res) throws
    ServletException, IOException {
      res.setContentType("image/jpeg");
        ServletOutputStream out = res.getOutputStream();
        JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out);
        String key = req.getQueryString();
        synchronized(this) {
          BufferedImage img = model.getImage(key);
          encoder.encode(img);
        }
      }
}