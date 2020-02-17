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
    currFrame += nframes;  
  }
  
  void retrogradeFrame(int nframes) {
    currFrame -= nframes;  
  }
  
  int getTotalFrames() {
    return totalFrames;  
  }
  
  
}
