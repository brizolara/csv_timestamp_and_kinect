import processing.video.*;
//import GraphPlayer;

class VideoPlayer extends Movie
{
  Player referencePlayer;
  
  //  We assume that when some referencePlayer is at frame externalFrame_trigger, we play this video
  //  (Note that we are not usinf frame rate nor time) 
  int externalFrame_trigger;
  
  VideoPlayer(PApplet p_sketch, String p_path, Player p_player) {
    super(p_sketch, p_path);
    referencePlayer = p_player;
    externalFrame_trigger = referencePlayer.totalFrames + 1; // to force paused state (see tryStart)
  }
  
  void setTriggerFrame(int p_frame) {
    externalFrame_trigger = p_frame;
    //  and write to file
  }
  
  void decreaseTriggerFrame() {
     externalFrame_trigger--;
  }
  
  void increaseTriggerFrame() {
     externalFrame_trigger++;
  }
  
  boolean isPlaying() {
    return this.playbin.isPlaying() && (this.time() < this.duration());   
  }
  
  void tryStart()
  {
    //println("referencePlayer.currFrame, externalFrame_trigger:" + referencePlayer.currFrame + ", " + externalFrame_trigger);
    //println("this.playbin.isPlaying() = " + this.playbin.isPlaying());
    //println("this.time() < this.duration() = " + (this.time() < this.duration()));
    if(!this.isPlaying() && referencePlayer.state == Player.PLAYING) {
      if(referencePlayer.currFrame >= externalFrame_trigger) {
        //println("play!");
        this.jump(0);
        this.play();
        this.volume(1.0); // [BUG] doesn't work... we can't hear our videos's sound...
      }
    }
  }
  
}
