/*
 * LocusDisplayServlet.java: This is a singleton to hold all data information and process
 * all locus data for LocusDisplayHtml and LocusDisplayImage servlets
 *
 * Created on September 29, 2000, 4:32 PM
 */

import java.io.*;
import java.util.*;
import java.awt.*;
import java.awt.image.*;
import java.awt.geom.*;
import java.awt.font.*;

import jadex.swing.map.*;
import jade.db.*;
/**
 *
 * @author  Guanming Wu
 * @version
 */
public class LocusDisplayModel extends ServletDisplayModel {

    protected final float REL = 5.0f; // Relative value used in point drawing

    // Singleton to this class
    private static LocusDisplayModel instance = null; // Self reference

    // Cache all displaymodels
    private Map models = new HashMap(); // Caching the displaymodel

    private String aceHost = null; // The host name of acedb
    private int acePort = 2005; // The port of acedb
    private AceAccessor accessor = null; // To connect an AceDB to get map data
    private Map accessors = new HashMap(); // Caching all AceAccessors.

    // Singleton method to return the sole instance of this class
    public static LocusDisplayModel getInstance() {
        if (instance == null) instance = new LocusDisplayModel();
        return instance;
    }

    // Protected constructor only can be used by class itself and its subclasses
    protected LocusDisplayModel() {
        //setStart(-30.0f);
        //setEnd(30.0f);
        setPointLength(10000);
    }

    /** Setup a new JSAceAccessor */
    public void setAceAccessor(String server, String port) {
        aceHost  = server;
        acePort = Integer.parseInt(port);

    }

    // Local model for development
    public void setFileModel() {
        name = "I";
        model = getModel(name);
        if (model == null) { // First time access
            // Borrow the functionality of OpenFileAction. Try to find a better way?
            // A lot of design issued involved
            OpenFileAction fileAct = new OpenFileAction();
            // The file path should be changed
            fileAct.processFile(new File(new String("mapview" + File.separator + "genetic_map_I")));

            Object[][] loci = fileAct.getLoci();
            model = constructModel(loci, name);
            //models.put(name, model);
            models.put(aceHost + acePort + name, model);
        }
        setStartAndEnd(model);
        model.sortByError();
        points = model.assignPoints(REL);
        float verticalP = xPadding + 3.0f * points.size() + 5.0f;
        setVerticalP(verticalP);
    }

    // Try to get the model from the caching
    public DisplayModel getModel(String name) {
        String key = aceHost + acePort + name;
        return (DisplayModel) models.get(key);
        //return (DisplayModel) models.get(name);
    }

    // Set the name of geneticMap
    public void setAceObject(String name) {
        // try to get the displaymodel
        //if ((this.name != null) && (this.name.equalsIgnoreCase(name))) return ; // same object, do nothing
        this.name = name;
        model = getModel(name);

        // If not, a new model has to be constructed
        if (model == null) {
            String key = aceHost + acePort;
            AceAccessor accessor = (AceAccessor) accessors.get(key);
            if (accessor == null) {
                accessor = new JSAceAccessor(aceHost, acePort);
                accessors.put(key, accessor);
            }
            try {
                AceObject map = accessor.fetch("map", name);
            String[] params = {map.name};
                Object[][] loci = map.getTable("Map.point", "Map.point", params, "sff");
                model = constructModel(loci, name);
                models.put(aceHost + acePort + name, model);
                //models.put(name, model);
            }
            catch (Exception e) { // If any problems, try to connect the acedb once more
                accessor = new JSAceAccessor(aceHost, acePort);
                accessors.put(key, accessor);
                AceObject map = accessor.fetch("map", name);
            String[] params = {map.name};
                Object[][] loci = map.getTable("Map.point", "Map.point", params, "sff");
                model = constructModel(loci, name);
                models.put(aceHost + acePort + name, model);
                //models.put(name, model);
            }
        }
        setStartAndEnd(model);
        model.sortByError();
        points = model.assignPoints(REL);
        float verticalP = xPadding + 3.0f * points.size() + 5.0f;
        setVerticalP(verticalP);
    }

    /** Set START and END from model data. */
    private void setStartAndEnd(DisplayModel model) {
        model.sort();
        MapPoint[] data = model.getData();
        MapPoint start = data[0];
        MapPoint end = data[data.length - 1];
        try {
            float startF = start.getPosition();
            float endF = end.getPosition();
            setEnd((int) (startF + 0.5));
            setStart((int) (endF - 0.5));
        }
        catch(UnknownPositionException e) {
            System.err.println("LocusDisplayModel.setStartAndEnd(): " + e);
        }
    }

    // Construct a new model
    private DisplayModel constructModel(Object[][] loci, String name) {
        DisplayModel model = new DisplayModel();

        for (int i = 0; i < loci.length; i++) {
            String n = (String) loci[i][0];
            Float position = (Float) loci[i][1];
            float pos = position.floatValue();
            Float error = (Float) loci[i][2];
            float err = error.floatValue();
            MapPoint p = new Locus(n, pos, err, null);
            model.addPoint(p);
        }
        //model.sortByError();
        return model;
    }

    /** Draw all mappoints to the left of the chromosome */
    protected void drawPoints(Graphics2D g2) {
        Vector points = (Vector) this.points;
        int size = points.size();
        float x = xPadding;
        g2.setColor(Color.orange);

        String selectedLocus = getSelectedLocus();
        String name = null;
                
        for (int i = size - 1; i >= 0; i --) {
            Vector v = (Vector) points.elementAt(i);
            int size1 = v.size();
            for (int j = 0; j < size1; j++) {
                try {
                    MapPoint p = (MapPoint) v.elementAt(j);
                    float pos = p.getPosition();
                    //float y = (offset - pos) * rel + yPadding;
                    float y = (pos - offset) * rel + yPadding;
                   
                    // Check the name of the mappoint is the same as the selectedLocus.
                    name = p.getName();
                    if (name.equalsIgnoreCase(selectedLocus)) {
                        setSelectedPoint(p);
                    }
                    if ((y < yPadding) || (y > (HEIGHT - yPadding))) {
                        //if (name.equalsIgnoreCase(selectedLocus)) setSelectedPoint(null);
                        continue; // Do nothing whem position is out of range
                    }
                    g2.draw(new Ellipse2D.Float(x - 0.5f, y - 0.5f, 1.0f, 1.0f));
                                       
                }
            catch (UnknownPositionException e) { System.err.println(e); }
            }
            x = x + 3.0f;
        }
    }
}