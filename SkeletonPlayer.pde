//  Playback of the skeleton
class SkeletonPlayer extends Player
{  
  
  ArrayList<skeletonFrame> skeletonTrajectory = new ArrayList<skeletonFrame>();
  /*Kinect.NUI_SKELETON_POSITION_HEAD
  
  skeletonAddresses[0] = "/skeleton/head/";
  skeletonAddresses[1] = "/skeleton/neck/";
  skeletonAddresses[2] = "/skeleton/lsho/";
  skeletonAddresses[3] = "/skeleton/lelb/";
  skeletonAddresses[4] = "/skeleton/lhnd/";
  skeletonAddresses[5] = "/skeleton/rsho/";
  skeletonAddresses[6] = "/skeleton/relb/";
  skeletonAddresses[7] = "/skeleton/rhnd/";
  skeletonAddresses[8] = "/skeleton/tors/";
  skeletonAddresses[9] = "/skeleton/lhip/";
  skeletonAddresses[10] = "/skeleton/lkne/";
  skeletonAddresses[11] = "/skeleton/lfoo/";
  skeletonAddresses[12] = "/skeleton/rhip/";
  skeletonAddresses[13] = "/skeleton/rkne/";
  skeletonAddresses[14] = "/skeleton/rfoo/";*/
  
  SkeletonPlayer() {
  }
  
  String loadNextFrame()
  {
    SkeletonData skeleton = new SkeletonData();
    for(int i=0; i<20; i++)
    {
      try{
        line = reader.readLine(); 
        //println(line);
        if(line == null)
        {
            this.currFrame = 0;
            this.callerInitialMillis = millis();
            println("this.callerInitialMillis = " + this.callerInitialMillis);
            this.nextMillis = this.getTimestampAtCurrFrame();
            
            this.state = PLAYING;
            
            println(totalFrames + " frames loaded");
            countGood = 0;
            countDropped = 0;
            return "";  
        }
        pieces = split(line, ' ');
 
        skeleton.skeletonPositions[i].x = float(pieces[1]);
        skeleton.skeletonPositions[i].y = float(pieces[2]);
        skeleton.skeletonPositions[i].z = float(pieces[3]) / 20000;
        
        //Kinect.NUI_SKELETON_POSITION_HEAD
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    skeletonTrajectory.add(new skeletonFrame(skeleton, int(pieces[4])));
    totalFrames++;
    return line;
  }
  
  SkeletonData getSkeletonAtCurrFrame()
  {
    return skeletonTrajectory.get(this.currFrame).skeleton;
  }
  
  int getTimestampAtCurrFrame()
  {
    return skeletonTrajectory.get(this.currFrame).timestamp;
  }
  
  int getInitialTimestamp() {
     return skeletonTrajectory.get(0).timestamp;
  }

}
//-----------------------------------------------------------------------

class skeletonFrame
{
  SkeletonData skeleton; // making other use of kinect4WinSDK.SkeletonData ...
  int timestamp;
  
  skeletonFrame() { };
  skeletonFrame(SkeletonData s, int t) {
    skeleton = s;
    timestamp = t;
  }
}
