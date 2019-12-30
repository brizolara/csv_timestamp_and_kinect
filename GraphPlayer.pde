class GraphPlayer extends Player
{
  int n_curves;
  int initialTimestamp;
  
  protected LinkedList<GraphicFrame> frames = new LinkedList<GraphicFrame>();
  
  GraphPlayer() {
    
  }
  
  GraphPlayer(int p_nc) {
    n_curves = p_nc;
  }
  
  String loadNextFrame()
  {
    try
    {
      int count = 0;
      for(;;)
      {
        line = reader.readLine(); 
        //println(line);
        if(line == null)
        {
            this.currFrame = 0;
            this.callerInitialMillis = millis();
            println("this.callerInitialMillis = " + this.callerInitialMillis);
            this.initialTimestamp = this.getTimestampAtCurrFrame();
            println(this.initialTimestamp);
            //this.setNextMillis(0);  //  
            //println("nextMillis = " + nextMillis);
            
            this.state = PLAYING;
            
            println(totalFrames + " frames loaded");
            countGood = 0;
            countDropped = 0;
            return "";  
        }
        pieces = split(line, ' ');
        
        if(line.contains("M0 e ")) {
          break;  
        }
        if(count == 100) {
          println("== Error: couldn't parse file!!");
          return "";
        }
      }
 
      FloatList fl = new FloatList();
 
      for(int c=0; c<n_curves; c++) {
        fl.append(float(pieces[c+2]));
      }
      GraphicFrame fr = new GraphicFrame(fl, int(pieces[2+n_curves]));
      frames.add(fr);
      totalFrames++;
      return line;
      //nextMillis = int(pieces[4]);
    } catch (IOException e) {
      e.printStackTrace();
    }
    
    return line;
  }
  
  int getNextMillis() {
    return this.getTimestampAtCurrFrame()/1000 - this.initialTimestamp/1000;
  }
  
  void setNextMillis(int ts) {
    nextMillis = ts;
  }
  
  FloatList getPointsAtCurrFrame()
  {
    return frames.get(this.currFrame).pts;
  }
  
  int getTimestampAtCurrFrame()
  {
    return frames.get(this.currFrame).timestamp;
  }
}
//---------------------------------------------------------------

class GraphicFrame
{
  FloatList pts;
  int timestamp;
  
  GraphicFrame() { };
  GraphicFrame(FloatList ps, int t) {
    pts = ps;
    timestamp = t;
  }
}