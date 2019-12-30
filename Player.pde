class Player
{
  public BufferedReader reader;
  int nextMillis = 0;
  int callerInitialMillis; // initial millis() of the application at SkeletonPlayer creation 
  
  boolean loaded = false;
  
  final int STOPPED = 0;
  final int LOADING = 1;
  final int PLAYING = 2;
  int state = STOPPED;
  
  int currFrame;
  int totalFrames = 0;  
}