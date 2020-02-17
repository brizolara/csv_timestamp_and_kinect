import processing.video.*;

import kinect4WinSDK.Kinect;
import kinect4WinSDK.SkeletonData;

import oscP5.*;
import netP5.*;

import com.jogamp.newt.event.KeyEvent;

import java.io.File;

VideoPlayer mov;

Kinect kinect;
ArrayList <SkeletonData> bodies;
boolean showRGB = true;
boolean showSkeletonTracking = true;

//  KinectSkeletonOSC
OscP5 oscP5;
NetAddress myRemoteLocation;
//OscMessage [] skeletonMessages;  a versao atual da OscP5 nao me deixa alterar OscMessages...
String [] skeletonAddresses = new String[20];
Object [] xyz = new Object[3];

//  Recording of the skeleton
PrintWriter output;

int initialRecMillis = 0;
int countGood = 0;
int countDropped = 0;

int initPauseMillis = 0;
int pausedMillis = 0;

int fileIndex;
int previousFileIndex;

//  State
enum State {DEFAULT, RECORDING, PLAYBACK};
State state = State.DEFAULT;
int recording = -1;

SkeletonPlayer skeletonPlayer;

String line; // aux
String[] pieces; // aux

GraphPlayer graphPlayer_Left, graphPlayer_Right;

Plot p;
int topGap = 240;
int vertGap = 0;

PGraphics img; // auxiliar

String data_path = "";

void setup()
{
  //size(640, 480);
  size(700, 540);
  background(0);
  //kinect = new Kinect(this);
  smooth();
  bodies = new ArrayList<SkeletonData>();
  
  //  KinectSkeletonOSC
  oscP5 = new OscP5(this,8081); // listening for incoming messages at port 12000
  myRemoteLocation = new NetAddress("192.168.15.14",8082);  //"127.0.0.1"
  
  /*skeletonAddresses[0] = "/skeleton/head/";
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
  //  obbeying Microsoft Kinect SDK's 1.5, 1.6, 1.7, 1.8 enum _NUI_SKELETON_POSITION_INDEX
  skeletonAddresses[0] = "/skeleton/hip_center/";
  skeletonAddresses[1] = "/skeleton/spine/";
  skeletonAddresses[2] = "/skeleton/shoulder_center/";
  skeletonAddresses[3] = "/skeleton/head/";
  skeletonAddresses[4] = "/skeleton/shoulder_left/";
  skeletonAddresses[5] = "/skeleton/elbow_left/";
  skeletonAddresses[6] = "/skeleton/wrist_left/";
  skeletonAddresses[7] = "/skeleton/hand_left/";
  skeletonAddresses[8] = "/skeleton/shoulder_right/";
  skeletonAddresses[9] = "/skeleton/elbow_right/";
  skeletonAddresses[10] = "/skeleton/wrist_right/";
  skeletonAddresses[11] = "/skeleton/hand_right/";
  skeletonAddresses[12] = "/skeleton/hip_left/";
  skeletonAddresses[13] = "/skeleton/knee_left/";
  skeletonAddresses[14] = "/skeleton/ankle_left/";
  skeletonAddresses[15] = "/skeleton/foot_left/";
  skeletonAddresses[16] = "/skeleton/hip_right/";
  skeletonAddresses[17] = "/skeleton/knee_right/";
  skeletonAddresses[18] = "/skeleton/ankle_right/";
  skeletonAddresses[19] = "/skeleton/foot_right/";
  
  fileIndex = -1;
  previousFileIndex = -1;
  
  frameRate(30);
  
  p = new Plot(width/3, height-480, 3, 400, 10, 10, "Euler angles");
  //resizePlots();
  int totalPlotHeight = (height - topGap) / 1;//plots.size();
  int num = 0;
  p.resize(width/2, totalPlotHeight-vertGap, 0, topGap + num*totalPlotHeight);
}

void draw()
{ 
  background(0);
  
  textSize(14);
  text("* Press 'f' key - Select one of the participants (folder 1, 5, 6, 7 or 9)", 10, 14);
  text("* You can select one recording of this participant by pressing a number\nor navigating using keys n (select previous recording) and m (select next recording)", 10, 35);
  text("* Press 'v' key - Plays video (if any), not synced", 10, 80);
  
  text("* Graph: 3-axis acceleration, in units of g. \nTODO: remove gravity component", 0.55*width, 0.75*height);
  
  pushMatrix();
  
  translate(0, 60);
  
  if(graphPlayer_Left != null)
  {
    if(graphPlayer_Left.state != Player.PAUSED) {
      //background(0);
    }
    else {
      pausedMillis = millis() - initPauseMillis; // will make sense only if state is PAUSED      
    }
  }
  //else {
  //  background(0);
  //}
  
  if(showRGB) {
    //image(kinect.GetImage(), 0, 0, 320, 240);
  }
  //image(kinect.GetDepth(), 320, 0, 320, 240);
  //image(kinect.GetMask(), 320, 240, 320, 240);
  if(showSkeletonTracking)
  {
    for (int i=0; i<bodies.size (); i++) 
    {
      drawSkeleton(bodies.get(i));
      //drawPosition(bodies.get(i));
      //sendOSC_Skeleton(bodies.get(i));
    }
  }
  if(state == State.RECORDING) {
    //for (int i=0; i<bodies.size (); i++) 
    //{
      writeSkeleton();
      //saveFrame("kinect-sound_tracing-######.png");
    //}
  }
  else if(state == State.PLAYBACK && skeletonPlayer != null) 
  {
    if(skeletonPlayer != null) {
      if(skeletonPlayer.loaded) {
        drawSkeletonFrame();
      }
    }
    if(graphPlayer_Left != null) {
      if(graphPlayer_Left.loaded) {
        drawGraphFrame();
      }
    }
    if(mov != null)
    {
      if(graphPlayer_Left.state == Player.PLAYING)
      {
        mov.tryStart(); // starts if graphPlayer_Left passed from a reference frame
      }
      image(mov, width/2, 0);
    }
  }
  
  drawPlayButton();
  drawRecButton();
  drawText();
  
  popMatrix();
}

//----------------------------

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    data_path = selection.getAbsolutePath();
    prepareTrack(0);
  }
}

/*void mousePressed()
{
  sendOSC_Skeleton();
}*/
void keyPressed()
{
  if (key == CODED) {
    switch(keyCode) {
      case LEFT:
        mov.increaseTriggerFrame();
        skeletonPlayer.retrogradeFrame(1);
        graphPlayer_Left.retrogradeFrame(1);
      break;
      case RIGHT:
        mov.decreaseTriggerFrame();
        skeletonPlayer.advanceFrame(1);
        graphPlayer_Left.advanceFrame(1);
      break;
    }
  }
  
  switch(key)
  {
    case 'r':
      if(kinect != null) {
        if(state != State.RECORDING) {
          startRecording();
        }
        else { 
          state = State.DEFAULT;
          output.flush(); // Writes the remaining data to the file
          output.close(); // Finishes the file
          println("stopRecording " + 0);
        }
      }      
      break;
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      prepareTrack(Integer.parseInt(str(key)));
    break;
      
    case 'p': //  replay
      pausedMillis = 0;
      if(skeletonPlayer != null){
        if(skeletonPlayer.loaded) {
          skeletonPlayer.currFrame = 0;
          skeletonPlayer.nextMillis = skeletonPlayer.getTimestampAtCurrFrame();
          skeletonPlayer.callerInitialMillis = millis();
          state = State.PLAYBACK;
          skeletonPlayer.state = Player.PLAYING;
          println("----");
        }
      }
      if(graphPlayer_Left != null){
        if(graphPlayer_Left.loaded) {
          graphPlayer_Left.currFrame = 0;
          graphPlayer_Left.nextMillis = graphPlayer_Left.getTimestampAtCurrFrame();
          graphPlayer_Left.callerInitialMillis = millis();
          graphPlayer_Left.state = Player.PLAYING;
          //return;  
        }
      }
    break;

    case 'i': showRGB = !showRGB; break;
    case 'k': showSkeletonTracking = !showSkeletonTracking; break;

    case 'n':
      fileIndex = max(0,--fileIndex);
      println(fileIndex);
      prepareTrack(fileIndex);  
    break;

    case 'm':
      fileIndex = min(11,++fileIndex);
      prepareTrack(fileIndex);  
    break;
    
    case 'd':
      state = State.DEFAULT;
      //graphPlayer_Left.state = graphPlayer_Left.STOPPED;
      skeletonPlayer.state = Player.STOPPED;
     break;
     
    case 'f':
      selectFolder("Select a folder to process:", "folderSelected", new File(sketchPath("../data")));
    break;
    
    case ' ':
     //println("graphPlayer_Left = " + graphPlayer_Left);
     if(graphPlayer_Left != null)
     {
       if(graphPlayer_Left.state == Player.PLAYING) {
         mov.setTriggerFrame(skeletonPlayer.currFrame);
         mov.pause();
         println("mov.externalFrame_trigger = " + mov.externalFrame_trigger + ", of " + graphPlayer_Left.getTotalFrames());
         ////state = State.PAUSED;
         skeletonPlayer.state = Player.PAUSED;
         graphPlayer_Left.state = Player.PAUSED;
         initPauseMillis = millis();
       }
       else if(graphPlayer_Left.state == Player.PAUSED) {
         println("mov.externalFrame_trigger = " + mov.externalFrame_trigger);
         //state = State.PAUSED;
         skeletonPlayer.state = Player.PLAYING;
         graphPlayer_Left.state = Player.PLAYING;
       }
     }
     else {
       println("??????????????");  
     }
    break;
    
    case 'v':
      if(mov != null) {
        mov.jump(0);
        mov.play();
      }
    break;
  }
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage)
{
  /* check if theOscMessage has the address pattern we are looking for. */
  if(theOscMessage.checkAddrPattern("/myo/startRecording")==true) {
    /* check if the typetag is the right one. */
    //if(theOscMessage.checkTypetag("f")) {
                                                              //fileIndex = theOscMessage.get(0).intValue();
                                                              //startRecording();
    //}
  }
  else if(theOscMessage.checkAddrPattern("/myo/stopRecording")==true) {
    //if(theOscMessage.checkTypetag("i")) {
      if(state == State.RECORDING) {
                                                            //state = State.DEFAULT;
                                                            //println("stopRecording " + theOscMessage.get(0).intValue());
                                                            //output.flush(); // Writes the remaining data to the file
                                                            //output.close(); // Finishes the file
      }
    //}
  }
}

void movieEvent(Movie m) {
  m.read();
}

void prepareTrack(int p_fileIndex)
{
  println("prepareTrack");
  pausedMillis = 0;
  fileIndex = p_fileIndex;
//if(state != State.PLAYBACK)
    {
      /*if(skeletonPlayer != null){
        if(skeletonPlayer.loaded) {
          skeletonPlayer.currFrame = 0;
          skeletonPlayer.nextMillis = skeletonPlayer.getTimestampAtCurrFrame();
          skeletonPlayer.callerInitialMillis = millis();
          state = State.PLAYBACK;
          skeletonPlayer.state = skeletonPlayer.PLAYING;
          println("----");
          return;  
        }
      }*/
      state = State.PLAYBACK;
      if(skeletonPlayer == null || p_fileIndex != previousFileIndex)
      {
        File f = dataFile(data_path + "/kinect/positions" + fileIndex + ".txt");
        //String filePath = f.getPath();
        println(f.getPath());
        if(f.isFile())
        {
          skeletonPlayer = new SkeletonPlayer();
          skeletonPlayer.loaded = false;
          println("Loading skeleton from file /positions" + fileIndex + ".txt ...");
          //skeletonPlayer.reader = createReader("../data/4/kinect/positions" + fileIndex + ".txt");
          skeletonPlayer.reader = createReader(data_path + "/kinect/positions" + fileIndex + ".txt");
          while(skeletonPlayer.loadNextFrame() != "") {
              skeletonPlayer.state = Player.STOPPED;
          }
          skeletonPlayer.loaded = true;
          skeletonPlayer.state = Player.PLAYING;
          try {
            println("Skeleton loaded. Closing file to start playback ...");
            skeletonPlayer.reader.close();
            skeletonPlayer.currFrame = 0;
            
          } catch (IOException e) {
            e.printStackTrace();
          }
        }
      }
      
      if(graphPlayer_Left == null || p_fileIndex != previousFileIndex)
      {
        graphPlayer_Left = new GraphPlayer(3/*number of curves*/);
        graphPlayer_Left.loaded = false;
        println("Loading Myo captured data from file " + data_path + "/myos/myoReadings_" + fileIndex + ".csv ...");
        //graphPlayer_Left.reader = createReader("../data/4/myos/myoReadings_" + fileIndex + ".csv");
        graphPlayer_Left.reader = createReader(data_path + "/myos/myoReadings_" + fileIndex + ".csv");
        while(graphPlayer_Left.loadNextFrame("M0 a") != "") {
            graphPlayer_Left.state = Player.STOPPED;
        }
        graphPlayer_Left.loaded = true;
        graphPlayer_Left.state = Player.PLAYING;
        try {
          println("Myo captured data loaded. Closing file to start playback ...");
          graphPlayer_Left.reader.close();
          graphPlayer_Left.currFrame = 0;
          
        } catch (IOException e) {
          e.printStackTrace();
        }
      }
    }
    //else {
    //  state = State.DEFAULT;
    //} 
    
    
    if(mov == null || p_fileIndex != previousFileIndex)
    {
      File f = dataFile(data_path + "/video/vid" + fileIndex + ".mov");
      //println(f.getPath());
      //String filePath = f.getPath();
      if(f.isFile()) {
        mov = new VideoPlayer(this, f.getPath(), graphPlayer_Left);
      } 
    }
    
    if(mov != null) {
        println("Video prepared to play");
        mov.play();
        mov.jump(0);
        mov.pause();
      }
    
    previousFileIndex = p_fileIndex;
}

void startRecording()
{
    state = State.RECORDING;
    initialRecMillis = millis();
    println("startRecording " + fileIndex);
    output = createWriter("positions" + fileIndex + ".txt");      
}

void writeSkeleton()
{
  for(int i=0; i<20; i++)
  {
    if(bodies.size() > 0)
    {
      xyz[0] = bodies.get(0).skeletonPositions[i].x;
      xyz[1] = bodies.get(0).skeletonPositions[i].y;
      xyz[2] = bodies.get(0).skeletonPositions[i].z;
      if(bodies.get(0).skeletonPositions[i].z > 0.0f)  //  evitando bodies zerados
      {
        //oscP5.send(new OscMessage(skeletonAddresses[i], xyz), myRemoteLocation);
        output.println(skeletonAddresses[i] + " " + xyz[0] + " " + xyz[1]  + " " + xyz[2] + " " + (millis()-initialRecMillis));
      }
      //sendOSC_float(skeletonAddresses[i],  xyz);
      
      /*
      OscMessage m = new OscMessage(skeletonAddresses[i]);
      m.add(_s.skeletonPositions[i].x);
      m.add(_s.skeletonPositions[i].y);
      m.add(_s.skeletonPositions[i].z);
      oscP5.send(m, myRemoteLocation);*/
    }
  }
}

void drawSkeletonFrame()
{
  //println(skeletonPlayer.currFrame + " of " + skeletonPlayer.totalFrames);
  if(skeletonPlayer.currFrame < skeletonPlayer.totalFrames-1)
  {
    //println((millis()-skeletonPlayer.callerInitialMillis) + " " + skeletonPlayer.nextMillis);
    
    if( (skeletonPlayer.state == Player.PLAYING) && 
    ((millis()-skeletonPlayer.callerInitialMillis-pausedMillis) > skeletonPlayer.nextMillis) )
    {
      while((millis()-skeletonPlayer.callerInitialMillis-pausedMillis) > skeletonPlayer.nextMillis)
      {
        skeletonPlayer.nextMillis = skeletonPlayer.getTimestampAtCurrFrame();
        
        //println("skeletonPlayer.currFrame = " + skeletonPlayer.currFrame);
       
        if(skeletonPlayer.state == Player.PLAYING) {
          skeletonPlayer.currFrame++;
        }
        
        if(skeletonPlayer.currFrame >= skeletonPlayer.totalFrames) {
          skeletonPlayer.currFrame = skeletonPlayer.totalFrames - 1;
          skeletonPlayer.state = Player.STOPPED;
          //println("Skeleton snimation finished");
          return;   
        }
        
        countDropped++;
      }
      countGood++;
      //println(countGood);
      //drawSkeleton(skeletonPlayer.getSkeletonAtCurrFrame());
    }
    else {
      ;
    }
    drawSkeleton(skeletonPlayer.getSkeletonAtCurrFrame());
    //println(millis());
  }
  else  //  drawing last frame 
  {
    drawSkeleton(skeletonPlayer.getSkeletonAtCurrFrame());
    skeletonPlayer.state = Player.STOPPED;
    //println("Skeleton snimation finished");
  }
}

void drawGraphFrame()
{
  
  if(graphPlayer_Left.currFrame < graphPlayer_Left.totalFrames)//-1)
  {
    //println((millis()-graphPlayer_Left.callerInitialMillis) + " " + graphPlayer_Left.getNextMillis());
    
    if( (graphPlayer_Left.state == Player.PLAYING) && 
    ( (millis()-graphPlayer_Left.callerInitialMillis-pausedMillis) > graphPlayer_Left.getNextMillis()) )
    {
      while((millis()-graphPlayer_Left.callerInitialMillis-pausedMillis) > graphPlayer_Left.getNextMillis())
      {
        //println((millis()-graphPlayer_Left.callerInitialMillis-pausedMillis));
        //println(graphPlayer_Left.getNextMillis());
        //graphPlayer_Left.setNextMillis(graphPlayer_Left.getTimestampAtCurrFrame());
       
        if(graphPlayer_Left.state == Player.PLAYING) {
          graphPlayer_Left.currFrame++;
        }
        
        if(graphPlayer_Left.currFrame >= graphPlayer_Left.totalFrames) {
          graphPlayer_Left.currFrame = graphPlayer_Left.totalFrames - 1;
          graphPlayer_Left.state = Player.STOPPED;
          println("Graph animation finished");
          return;   
        }
        
        countDropped++;
      }
      countGood++;
    }
    else {
      ;
    }
    //plots.get(count + a).setColor(i);
    //plots.get(count + a).addPoint(nextFloat);
    if(graphPlayer_Left.state == Player.PLAYING) {
      p.addPoint(graphPlayer_Left.getPointsAtCurrFrame());
    }
    p.plotPoints();
  }
  else  //  drawing last frame 
  {
    p.plotPoints();
    graphPlayer_Left.state = Player.STOPPED;
    println("Graph animation finished");
  }

}

void resizePlots() {
    int totalPlotHeight = (height - topGap) / 1;//plots.size();
    int num = 0;
    synchronized(this) {
      //for (Plot p : plots) {
       p.resize(width - 10, totalPlotHeight-vertGap, 0, topGap + num*totalPlotHeight);
       num++;
      //}
    }
}

void drawRecButton()
{
  if(state == State.RECORDING)  fill(255,0,0);
  else                          fill(0,0,0);
  stroke(255);
  rect(width-50, 10, 40, 40);
  ellipse(width-30, 30, 40, 40);
  fill(255);
  textSize(20);
  textAlign(LEFT);
  text("REC", width-50, 70);
}

void drawPlayButton()
{
  fill(0,0,0);
  stroke(255);
  ellipse(width-83, 30, 40, 40);
  if(state == State.PLAYBACK) {
    if(graphPlayer_Left != null) {
      if(graphPlayer_Left.currFrame < graphPlayer_Left.totalFrames-1) {
        fill(0,255,0);
      }
    }
  }
  triangle(width-74, 30, width-90, 20, width-90, 40);
  fill(255);
  textSize(20);
  textAlign(LEFT);
  text("REP", width-100, 70);
}

void drawText()
{
  fill(255);
  textSize(20);
  text(fileIndex, width-75, 100); 
}

//-----------------------------------------------------------------------------
//
//  Kinect events and drawing

void drawPosition(SkeletonData _s) 
{
  noStroke();
  fill(0, 100, 255);
  String s1 = str(_s.dwTrackingID);
  text(s1, _s.position.x*width/2, _s.position.y*height/2);
}

void drawSkeleton(SkeletonData _s) 
{
  // Body
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HEAD, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_CENTER);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_CENTER, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_CENTER, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_CENTER, 
  Kinect.NUI_SKELETON_POSITION_SPINE);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_LEFT, 
  Kinect.NUI_SKELETON_POSITION_SPINE);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_SPINE);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SPINE, 
  Kinect.NUI_SKELETON_POSITION_HIP_CENTER);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_CENTER, 
  Kinect.NUI_SKELETON_POSITION_HIP_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_CENTER, 
  Kinect.NUI_SKELETON_POSITION_HIP_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_LEFT, 
  Kinect.NUI_SKELETON_POSITION_HIP_RIGHT);

  // Left Arm
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_LEFT, 
  Kinect.NUI_SKELETON_POSITION_ELBOW_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_ELBOW_LEFT, 
  Kinect.NUI_SKELETON_POSITION_WRIST_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_WRIST_LEFT, 
  Kinect.NUI_SKELETON_POSITION_HAND_LEFT);

  // Right Arm
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_ELBOW_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_ELBOW_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_WRIST_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_WRIST_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_HAND_RIGHT);

  // Left Leg
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_LEFT, 
  Kinect.NUI_SKELETON_POSITION_KNEE_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_KNEE_LEFT, 
  Kinect.NUI_SKELETON_POSITION_ANKLE_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_ANKLE_LEFT, 
  Kinect.NUI_SKELETON_POSITION_FOOT_LEFT);

  // Right Leg
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_KNEE_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_KNEE_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_ANKLE_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_ANKLE_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_FOOT_RIGHT);
}

void DrawBone(SkeletonData _s, int _j1, int _j2) 
{
  noFill();
  stroke(255, 255, 0);
  if ( (_s.skeletonPositionTrackingState[_j1] != Kinect.NUI_SKELETON_POSITION_NOT_TRACKED &&
    _s.skeletonPositionTrackingState[_j2] != Kinect.NUI_SKELETON_POSITION_NOT_TRACKED)
    || state==State.PLAYBACK)
  {
    line(_s.skeletonPositions[_j1].x*width/2, 
    _s.skeletonPositions[_j1].y*height/2, 
    _s.skeletonPositions[_j2].x*width/2, 
    _s.skeletonPositions[_j2].y*height/2);
  }
}

void appearEvent(SkeletonData _s) 
{
  if (_s.trackingState == Kinect.NUI_SKELETON_NOT_TRACKED) 
  {
    return;
  }
  synchronized(bodies) {
    bodies.add(_s);
  }
}

void disappearEvent(SkeletonData _s) 
{
  synchronized(bodies) {
    for (int i=bodies.size ()-1; i>=0; i--) 
    {
      if (_s.dwTrackingID == bodies.get(i).dwTrackingID) 
      {
        bodies.remove(i);
      }
    }
  }
}

void moveEvent(SkeletonData _b, SkeletonData _a) 
{
  if (_a.trackingState == Kinect.NUI_SKELETON_NOT_TRACKED) 
  {
    return;
  }
  synchronized(bodies) {
    for (int i=bodies.size ()-1; i>=0; i--) 
    {
      if (_b.dwTrackingID == bodies.get(i).dwTrackingID) 
      {
        bodies.get(i).copy(_a);
        break;
      }
    }
  }
}

// not used:
//---------------------------------------------------------------------------
//
//  Sending Skeleton data via OSC

void sendOSC_Skeleton(SkeletonData _s)
{
  for(int i=0; i<20; i++)
  {
    xyz[0] = _s.skeletonPositions[i].x;
    xyz[1] = _s.skeletonPositions[i].y;
    xyz[2] = _s.skeletonPositions[i].z;
    if(_s.skeletonPositions[i].z > 0.0f)  //  evitando bodies zerados
    {
      //oscP5.send(new OscMessage(skeletonAddresses[i], xyz), myRemoteLocation);
      output.println(skeletonAddresses[i] + " " + xyz[0] + " " + xyz[1]  + " " + xyz[2]);
    }
    //sendOSC_float(skeletonAddresses[i],  xyz);
    
    /*
    OscMessage m = new OscMessage(skeletonAddresses[i]);
    m.add(_s.skeletonPositions[i].x);
    m.add(_s.skeletonPositions[i].y);
    m.add(_s.skeletonPositions[i].z);
    oscP5.send(m, myRemoteLocation);*/
  }
  /* Para a biblioteca de controle de camera KinectOrbit:
  sendOSC_float(sendOSC_floatkeletonMessages[12], "/telekenisis/orb_red/X/", "f", 0.0 );
  sendOSC_float(sendOSC_floatkeletonMessages[12], "/telekenisis/orb_red/Y/", "f", 0.0 );
  sendOSC_float(sendOSC_floatkeletonMessages[12], "/telekenisis/orb_red/Z/", "f", 0.0 );

  sendOSC_float(sendOSC_floatkeletonMessages[13], "/telekenisis/orb_blue/X/", "f", 0.0 );
  sendOSC_float(sendOSC_floatkeletonMessages[13], "/telekenisis/orb_blue/Y/", "f", 0.0 );
  sendOSC_float(sendOSC_floatkeletonMessages[13], "/telekenisis/orb_blue/Z/", "f", 0.0 );

  sendOSC_float(sendOSC_floatkeletonMessages[14], "/telekenisis/orb_green/X/", "f", 0.0 );
  sendOSC_float(sendOSC_floatkeletonMessages[14], "/telekenisis/orb_green/Y/", "f", 0.0 );
  sendOSC_float(sendOSC_floatkeletonMessages[14], "/telekenisis/orb_green/Z/", "f", 0.0 );*/ 
}

void sendOSC_float(String address, Object [] values)
{
  oscP5.send(new OscMessage(address, values), myRemoteLocation);
}
