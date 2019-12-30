//Simple plotting class by Rebecca Fiebrink, 24 October 2017
// Please share only with attribution

import java.util.LinkedList;

class Plot {
   //The points to plot
   //protected LinkedList<PVector> points; 
   protected LinkedList<FloatList> points;// [Brizo] Multiple curves on same plot
   int numCurves;
   
   //Determines how plot is shown on screen
   protected int pHeight = 100;
   protected int totalWidth = 200;
   protected int labelWidth = 50;
   protected int plotWidth = totalWidth - labelWidth;
   protected int numPointsToPlot = 100;
   protected int x = 0;
   protected int y = 0;
   protected float min = 0.0001;
   protected float max = 0.; 
   protected double horizontalScale = 1;
   
   //Store string versions of axis labels so we don't have to recompute each frame
   String sMin = "0.0001";
   String sMax = "0.0";
   
   //Store last point so we can draw lines between subsequent points
   FloatList lastPointX;
   FloatList lastPointY;

   // colors...  //  [Brizo]
   color colour;
   color colors[] = {0xFFFF0000, 0xFF0000FF, 0xFF00FF00, 0xFF000000, 0xFFFF00FF, 0xFF00FFFF, 0xFFFFFF00};
   
   //  title  //  [Brizo]
   String title;
   
   //  

   //Constructor
   public Plot(int plotWidth, int plotHeight, int p_numCurves, int numPoints, int x, int y, String p_title)
   {
      this.pHeight = plotHeight;
      this.totalWidth = plotWidth;
      this.plotWidth = totalWidth - labelWidth;
      this.numPointsToPlot = numPoints;
      this.x = x;
      this.y = y;
      this.numCurves = p_numCurves;
      points = new LinkedList<FloatList>();
      
      lastPointX = new FloatList(0., 0., 0.);
      lastPointY = new FloatList(0., 0., 0.);
      
      title = p_title;
   }
   
   //Resize plot after it's been created
   public void resize(int newWidth, int newHeight, int newX, int newY) {
     this.pHeight = newHeight;
      this.totalWidth = newWidth;
      this.plotWidth = totalWidth - labelWidth;
      this.x = newX;
      this.y = newY;  
      rescale();
   }  
   
   public void setColor(int i) {
       colour = colors[i];
   }
   
   //Add a new point to the data series we're plotting
   public void addPoint(FloatList p) {
     for(int i=0; i<numCurves; i++)
     {
       if (points.size() == 0 && i==0) {
         min = p.get(i) - 0.0001;
         max = p.get(i) + 0.0001;
         rescale();
       }
       
       if (p.get(i) < min) {
         min = p.get(i);
         rescale();
       }
       if (p.get(i) > max) {
         max = p.get(i);
         rescale();
       }
       
       //Use synchronized so we don't read from and edit linkedlist simultaneously
       synchronized(this) {
         points.add(p);
         while (points.size() > numPointsToPlot) {
           points.removeFirst();
         }
       }
     }
   }
   
   //Plots the current set of points for the chosen graph position and size
   public void plotPoints() {
     //Plot area
     stroke(220);//153
     fill(255);
     rect(x + labelWidth, y, plotWidth, pHeight);
     
     //Plot labels
     putLabels();
     
     //Data points
     //stroke(255, 0, 0);
     //stroke(red(colour), green(colour), blue(colour));  //  [Brizo]
     int n = 0;
     synchronized(this) {
       for (FloatList f : points) {
         n++;
         for(int i=0; i<numCurves; i++)
         {
           stroke(red(colors[i]), green(colors[i]), blue(colors[i]));  //  [Brizo]
           float thisX = labelWidth + (float)(n * horizontalScale) + x;
           
           float thisY = y + pHeight - ((f.get(i) - min)/(max - min)) * pHeight;
         
           if (n == 1) {
             //It's the first point
             lastPointX.set(i,(float)thisX);
             lastPointY.set(i,(float)thisY);
           } else {
             //Draw a line from the last point to this point
             line(lastPointX.get(i), lastPointY.get(i), thisX, thisY);
             lastPointX.set(i,thisX);
             lastPointY.set(i,thisY);
           }
         }
       }
       for(int i=0; i<numCurves; i++)
       {
         text(points.get(points.size()-1).get(i), lastPointX.get(i), lastPointY.get(i));  //  [Brizo]
       }
     }
   }
   
   //Draw axis bounds
   protected void putLabels() {
     fill(0);
     textSize(8);
     textAlign(RIGHT);
     text(sMin, x + labelWidth, y + pHeight); 
     text(title, x + labelWidth, y + (pHeight+10)/2);  //  [Brizo]
     text(sMax, x + labelWidth, y + 10);
   }
   
   //Call when min, max, width, or number of points to plot changes
   protected void rescale() {
     horizontalScale = (double)plotWidth/numPointsToPlot;
     sMin = Float.toString(min);
     sMax = Float.toString(max);
   }
}