/*
 * ServletDisplayModel.java: Topmost class for the servlet display model
 *
 * Created on November 5, 2000, 10:51 AM
 */
import java.io.*;
import java.util.*;
import java.awt.*;
import java.awt.image.*;
import java.awt.geom.*;
import java.awt.font.*;

import jadex.swing.map.*;

/**
 *
 * @author  wgm
 * @version 
 */
public abstract class ServletDisplayModel extends Object {

    protected final int SHOW_NUMBER = 30; // The number of names will be displayed in the range
    protected final float WIDTH = 400.0f; // Width of the image
    protected final float HEIGHT = 400.0f; // Height of the image
    protected float xPadding = 40.0f; // Horizontal padding
    protected float yPadding = 10.0f; // Vertical padding

    public float START;  // end values of full scale
    public float END;
    public Font font = new Font("Dialog", 0, 10);

    //private float rightP; // The vertical position
    protected float verticalP; // The x position of the chromosome
    protected float offset, rel; // these two variables are for coordinate conversion
    protected String name = null; // The name of the chromosome
    protected DisplayModel model = null; // DisplayModel holding all data
    
    protected java.util.List points = null; // All mappoints
    private MapRange range = null; // Current MapRange
    private MapPoint[] sPoints = null; // Total locus can be shown in the range
    private MapPoint[] sNames = null; // These mappoints' names will be displayed in the image
    
    // These variables are for locus selection.
    private MapPoint selectedPoint = null; // The selected Locus to be highlighted.
    private String selectedLocus = null; // The name of the selectedPoint.
    private boolean needChecking = false; // A flag to show if a check is needed for slectedLocus.
    
    protected Map shapes = null; // All drawing shapes, which will be used for imagemaps in HTML
    // To make things simple, all shapes are Rectangle2D.Float

    private Map images = new HashMap(); // Caching the images for multi-accessing
    private Set algs = null; // Some specific names, which need specific measures
    private boolean isUp, isDown; // Check if map can be move up or down
    
    private int pointLength = 10000; // the position number after the point
    
    private String path = null; // The path of the current class
         
    /** Creates new ServletDisplayModel */
    protected ServletDisplayModel() {
    }
  
    /** Set and get name */
    public void setName(String name) {
        this.name = name;
    }
    
    public String getName() {
        return this.name;
    }
    
    /** Set and get path for images */
    public void setPath(String path) {
      this.path = path;
    }
    
    public String getPath() {
      return this.path;
    }
    
    /** shapes for creating image maps */
    public Map getShapes() { 
        return shapes; 
    }

    /** Some specifical names */
    public Set getAlgs() { 
        return algs; 
    }
    
    /** Set and get verticalP position */
    public void setVerticalP(float p) {
        verticalP = p;
    }
    
    public float getVerticalP() {
        return this.verticalP;
    }
    
    /** Set and get the number after the point */
    public void setPointLength(int length) {
        this.pointLength = length;
    }
    
    public int getPointLength() {
        return this.pointLength;
    }
    
    /** Set the selectedLocus.
    * @param locus the selectedLocus to be highted.
    */
    public void setSelectedLocus(String locus) {
        this.selectedLocus = locus;
        // The selectedPoint should be reset
        //this.setSelectedPoint(null);
    }
        
    /** Get the selectedLocus.
    * @return the selectedLocus.
    */
    public String getSelectedLocus() {
        return this.selectedLocus;
    }
    
    /** Set the selectedPoint to be highlighted. */
    public void setSelectedPoint(MapPoint point) {
        this.selectedPoint = point;
    }
    
    public MapPoint getSelectedPoint() {
        return this.selectedPoint;
    }
    
    /** Get the cached bufferedImage by using a string key */
    public BufferedImage getImage(String key) {
        BufferedImage img = (BufferedImage) images.get(key);
        images.remove(key);
        return img;
    }
    
    /** Create a image by specifying a maprange */
    public void createImage(MapRange r) {

        setMapRange(r);
        shapes = new HashMap();
        algs = new HashSet();

        BufferedImage img = new BufferedImage((int)WIDTH, (int)HEIGHT, BufferedImage.TYPE_INT_RGB);
        try {
            String key = new String("name=" + name + "&start=" + r.getStartF() + "&end=" + r.getEndF());
            if (selectedLocus != null) key += "&locus=" + selectedLocus;
            images.put(key, img);
        }
    catch(UnknownPositionException e) { System.err.println(e); }
        Graphics2D g2 = img.createGraphics();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

        // Set the white blackbround
        g2.setPaint(Color.white);
        g2.fill(new Rectangle2D.Float(0.0f, 0.0f, WIDTH, HEIGHT));

        // Draw the outline of the image
        g2.setPaint(Color.black);
        g2.draw(new Rectangle2D.Float(0.0f, 0.0f, WIDTH - 1.0f, HEIGHT - 1.0f));
        // Draw all points
        // Drawing points to show locus distribution.
        if (points.size() != 0) drawPoints(g2);
        // Drawing line to represent the cartoon.
        drawChromosome(g2);
        drawHorizontalLines(g2);
        drawNames(g2);
        drawScale(g2);
        drawMiniMapCartoon(g2);
        drawZoomButton(g2);
    }
    
    /** Draw all mappoints on the left of the chromosome 
    *  protected for subclassing
    */
    protected abstract void drawPoints(Graphics2D g2);
    
    /** Draw the vertical line as the chromosome */
    private void drawChromosome(Graphics2D g2) {
        float x = verticalP;
        g2.setPaint(Color.lightGray);
        g2.draw(new Line2D.Float(x, yPadding, x, HEIGHT - yPadding));
        //draw the up knob
        if (isUp) {
            Rectangle2D.Float rect1 = new Rectangle2D.Float( x - 3.0f, yPadding - 6.0f, 6.0f, 6.0f);
            shapes.put("up", rect1);
            algs.add("up");
            g2.setPaint(Color.blue);
            g2.draw(new Line2D.Float(x - 3.0f, yPadding - 3.0f, x, yPadding - 6.0f));
            g2.draw(new Line2D.Float(x, yPadding - 6.0f, x + 3.0f, yPadding - 3.0f));
            g2.draw(new Line2D.Float(x, yPadding - 6.0f , x, yPadding));
        }
        else {
            g2.setPaint(Color.lightGray);
            g2.fill(new Ellipse2D.Float(x - 3.0f, yPadding - 6.0f, 6.0f, 6.0f));
        }
        // draw the down knob
        if (isDown) {
            Rectangle2D.Float rect2 = new Rectangle2D.Float(x - 3.0f, HEIGHT - yPadding, 6.0f, 6.0f);
            shapes.put("down",rect2);
            algs.add("down");
            g2.setPaint(Color.blue);
            g2.draw(new Line2D.Float(x - 3.0f, HEIGHT - yPadding + 3.0f, x, HEIGHT - yPadding + 6.0f));
            g2.draw(new Line2D.Float(x, HEIGHT - yPadding + 6.0f, x + 3.0f, HEIGHT - yPadding + 3.0f));
            g2.draw(new Line2D.Float(x, HEIGHT - yPadding + 6.0f, x, HEIGHT - yPadding));
        }
        else {
            g2.setPaint(Color.lightGray);
            g2.fill(new Ellipse2D.Float(x - 3.0f, HEIGHT - yPadding, 6.0f, 6.0f));
        }
    }
    
    /** Represent mappoints as short horizonal lines on the chromosome */
    private void drawHorizontalLines(Graphics2D g2) {
        if ((sPoints != null) && (sPoints.length != 0)) {
            g2.setPaint(Color.black);
            for (int i = 0; i < sPoints.length; i++) {
                drawLocusLine(g2, sPoints[i]);
            }
        }
    }
    
    /** Draw a horizontal line */
    private void drawLocusLine(Graphics2D g2, MapPoint p) {
        try {
            float pos = p.getPosition();
            //float y = (offset - pos) * rel + yPadding;
            float y = (pos - offset) * rel + yPadding;
            g2.draw(new Line2D.Float(verticalP - 3.0f, y, verticalP + 3.0f, y));
        }
        catch(UnknownPositionException e) {
            System.err.println("LocusDisplayModel.drawLocusLine: " + e);
        }
    }

    /** Draw mappoint names on the right of the vertical line */
    private void drawNames(Graphics2D g2) {
        if ((sNames == null) || (sNames.length == 0)) return;

        float x = verticalP + 30.0f;

       // float y = yPadding + 5.0f;
        float y = HEIGHT - yPadding + 5.0f;
        float diff = (HEIGHT - 2 * yPadding) / (sNames.length - 1);

        MapPoint p = null;
        g2.setFont(font);
        FontRenderContext context = g2.getFontRenderContext();
        boolean selected = false;
        for (int i = 0; i < sNames.length; i++) {
            try {
                p = (MapPoint) sNames[i];
                String name = p.getName();
                if (name.equalsIgnoreCase(selectedLocus)) selected = true;
                else selected = false;
                float pos = p.getPosition();
                //g2.setPaint(Color.blue);
                if (selected) g2.setPaint(Color.red);
                else g2.setPaint(Color.blue);
                g2.drawString(name, x, y); // draw name of locus as a string
                addFontShape(name, x, y, context); // add shape of name to shapes
                if (!selected) g2.setPaint(Color.lightGray);
                //float startY = (offset - pos) * rel + yPadding;
                float startY = (pos - offset) * rel + yPadding;
                g2.draw(new Line2D.Float(verticalP + 3.0f, startY, x, y));
                //y += diff;
                y -= diff;
                if (selected) {
                    g2.draw(new Line2D.Float(verticalP - 3.0f, startY, verticalP + 3.0f, startY));
                }
            }
            catch(UnknownPositionException e) {
                System.err.println("LocusDisplayModel.drawNames(): " + e);
            }
        }
    }
    
     // A helper to calculate font rectange and add it to the shapes
    private void addFontShape(String name, float x, float y, FontRenderContext frc) {
        java.awt.font.LineMetrics metrics = font.getLineMetrics(name, frc);
        Rectangle2D rect = font.getStringBounds(name, frc);
        float ascent = metrics.getAscent();
        Rectangle2D.Float rect1 = new Rectangle2D.Float(x, y - ascent, (float) rect.getWidth(), (float) rect.getHeight());
        shapes.put(name, rect1);
    }
    
    /** Draw mapscale on the left side of the image */
    private void drawScale(Graphics2D g2) {

        float total_tick = 10.0f;
        float hpos = yPadding;
        float diff = (HEIGHT - 2.0f * yPadding) / total_tick;
        float sDiff = diff / 10.0f;
        for (int i = 0; i <= total_tick; i ++) {
            g2.setPaint(Color.black);
            g2.draw(new Line2D.Float(0.0f, hpos, 7.5f, hpos));
            float sY = hpos;
            if (i < total_tick) {
                for (int j = 0; j < 9; j++) {
                    sY += sDiff;
                    g2.draw(new Line2D.Float(0.0f, sY, 3.0f, sY));
                }
            }
            drawLabel(7.5f, hpos, g2, i);
            hpos += diff;
        }
    }

    /** Draw number labels on the mapscale */
    private void drawLabel(float posx,float posy,Graphics2D g2,int number){
        try {
            float extend = range.getExtendF();
            float diff = extend / 10.0f;
            //int ll = (int)((range.getEndF() - number * diff) * pointLength);
            int ll = (int)((range.getStartF() + number * diff) * pointLength);
            float label = ll / (float) pointLength;
            g2.setFont(new Font("Dialog", 0, 9));
            g2.setPaint(Color.gray);
            g2.drawString(label + "", posx + 2.0f, posy + 4.0f);
        }
        catch (UnknownPositionException e) {
            System.err.println("LocusDisplayModel.drawLabel(): " + e);
        }
    }
    /** A minimapcartoon to show the shown range's position in the chromosome */
    private void drawMiniMapCartoon(Graphics2D g2) {
        float w = 30.0f;
        float h = 50.0f;
        float x = WIDTH - w - 1.0f;
        float y = 1.0f;

        g2.setColor(Color.lightGray);
        g2.fill(new Rectangle2D.Float(x, y, w, h));

        g2.setColor(Color.gray);
        g2.fill(new RoundRectangle2D.Float(x + w/3.0f, y + 1.0f, w/3.0f, h - 2.0f, 5.0f, 5.0f));

        try {
            float rel = (h - 2.0f) / (END - START);
            //float offset = END;
            float offset = START;

            g2.setColor(Color.black);
            float height = rel * range.getExtendF();
            if (height < 1.0f) height = 1.0f;
            //float startY = (offset - range.getEndF()) * rel + 1.0f;
            float startY = (range.getStartF() - offset) * rel + 1.0f;
            g2.setColor(Color.green);
            g2.fill(new Rectangle2D.Float(x + w/3.0f, y + startY, w/3.0f, height));
        }
    catch (UnknownPositionException e) { System.err.println(e); }
    }

    /** This method is used to draw zoom buttons */
    private void drawZoomButton(Graphics2D g2) {
        float w = 30.0f;
        float h = 90.0f;
        float inset = 3.0f;
        float w1 = w - 2 *inset;
        float x = WIDTH - w - 1.10f;
        float y = 51.0f;

        g2.setPaint(Color.lightGray);
        g2.fill(new Rectangle2D.Float(x, y, w, h));

        // Draw three circles for the buttons
        g2.setPaint(Color.blue);
        float x1 = x + inset;
        // Fetch all button images
        String imgPath = path + "images" + File.separator;
        //System.out.println("imagePaht: " + imgPath);
        javax.swing.ImageIcon icon= new javax.swing.ImageIcon(imgPath + "ZoomIn24.gif");
        Image zoomIn = icon.getImage();
        icon = new javax.swing.ImageIcon(imgPath + "ZoomOut24.gif");
        Image zoomOut = icon.getImage();
        icon = new javax.swing.ImageIcon(imgPath + "FullScale.gif");
        Image full = icon.getImage();
        // ZoomIn Button
        g2.drawImage(zoomIn, (int)x1, (int)(y + inset), null);
        try {
            if ((range.getEndF() - range.getStartF()) > 0.001f) { // The minimum range can be shown
                shapes.put("zoomIn", new Rectangle2D.Float(x1, y + inset, w1, w1));
                algs.add("zoomIn");
            }
            // Reset button
            y += w;
            g2.drawImage(full, (int)x1, (int)(y + inset), null);
            if ((range.getStartF() > START) || (range.getEndF() < END)) {
                shapes.put("reset", new Rectangle2D.Float(x1, y + inset, w1, w1));
                algs.add("reset");
            }
            y += w;
            g2.drawImage(zoomOut, (int)x1, (int) (y + inset), null);
            if ((range.getStartF() > START) || (range.getEndF() < END)) {
                shapes.put("zoomOut", new Rectangle2D.Float(x1, y + inset, w1, w1));
                algs.add("zoomOut");
            }
        }
        catch(UnknownPositionException e) {
            System.err.println("LocusDisplayModel.drawZoomButtons(): " + e);
        }
    }

    /** Specify the maprange */
    public void setMapRange(MapRange range) {
        this.range = range;
        try {
            rel = (HEIGHT - 2 * yPadding) / range.getExtendF();
            //offset = range.getEndF();
            offset = range.getStartF();
            //if (offset < END) isUp = true;
            if (range.getStartF() > START) isUp = true;
            else isUp = false;
            //if (range.getStartF() > START) isDown = true;
            if (range.getEndF() < END) isDown = true;
            else isDown = false;
        }
        catch (UnknownPositionException e) {
            System.err.println("LocusDisplayServlet.setMapRange(): " + e);
        }
        sPoints = model.getMapPoints(range);
        sNames = model.getMapPoints(range, SHOW_NUMBER);
        // Add a method to put into the selectedLocus.
        if (selectedLocus != null) checkSNames();
        model.sort(sNames);
    }
    
    /** A helper to check if the selectedLocus is in the sNames. If not, 
    * put it as the last one in the array sNames.
    */
    private void checkSNames() {
        String name = null; // The name of the mappoint to be checked.
        for (int i = 0; i < sNames.length; i++) {
            name = sNames[i].getName();
            if (name.equalsIgnoreCase(selectedLocus)) return;
        }
        if (getSelectedPoint() != null) {
            MapPoint[] temp = new MapPoint[sNames.length + 1];
            temp[sNames.length] = getSelectedPoint();
            System.arraycopy(sNames, 0, temp, 0, sNames.length);
            sNames = temp;
            //sNames[sNames.length - 1] = getSelectedPoint();
            //System.out.println("checkSNames: " + getSelectedPoint());
        }
    }
    
    /** Set start and end values */
    public void setStart(float s) { 
      this.START = s;
      //System.out.println("Start: " + START);
    }
    
    public float getStart() { return this.START; }
    
    public void setEnd(float e) { 
      this.END = e; 
    }
    
    public float getEnd() { return this.END; }
}