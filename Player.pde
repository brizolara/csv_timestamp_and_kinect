class Player
{
  public BufferedReader reader;
  int nextMillis = 0;
  int callerInitialMillis; // initial millis() of the application at SkeletonPlayer creation 
  
  boolean loaded = false;
  
  final static int STOPPED = 0;
  final static int LOADING = 1;
  final static int PLAYING = 2;
  final static int PAUSED  = 3;
  int state = STOPPED;
  
  int currFrame;
  int totalFrames = 0;  
  
  void advanceFrame(int nframes) {
    if(currFrame + nframes < totalFrames) {
      currFrame += nframes;
      println(currFrame);
    }
  }
  
  void retrogradeFrame(int nframes) {
    if(currFrame - nframes >= 0) {
      currFrame -= nframes;
      println(currFrame);
    }
  }
  
  int getTotalFrames() {
    return totalFrames;  
  }
  
  
}
