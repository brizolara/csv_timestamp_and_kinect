import kinect4WinSDK.Kinect;
import kinect4WinSDK.SkeletonData;

import oscP5.*;
import netP5.*;

import com.jogamp.newt.event.KeyEvent;

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
int fileIndex;

int initialRecMillis = 0;
int countGood = 0;
int countDropped = 0;

//  State
enum State {DEFAULT, RECORDING, PLAYBACK};
State state = State.DEFAULT;
int recording = -1;

SkeletonPlayer skeletonPlayer;

String line; // aux
String[] pieces; // aux

GraphPlayer graphPlayer;

Plot p;
int topGap = 240;
int vertGap = 0;


void setup()
{
  //size(640, 480);
  size(700, 480);
  background(0);
  kinect = new Kinect(this);
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
  if(showRGB) {
    image(kinect.GetImage(), 0, 0, 320, 240);
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
  else if(state == State.PLAYBACK && skeletonPlayer != null)  {
    if(skeletonPlayer.state == skeletonPlayer.PLAYING)
    {
      drawSkeletonFrame();
      //drawGraphFrame();
    }
  }
  
  drawPlayButton();
  drawRecButton();
  drawText();
}

//----------------------------
/*void mousePressed()
{
  sendOSC_Skeleton();
}*/
void keyPressed()
{
  switch(key)
  {
    case 'r':
      if(state != State.RECORDING) {
        startRecording();
      }
      else { 
        state = State.DEFAULT;
        output.flush(); // Writes the remaining data to the file
        output.close(); // Finishes the file
        println("stopRecording " + 0);
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
        skeletonPlayer = new SkeletonPlayer();
        skeletonPlayer.loaded = false;
        fileIndex = Integer.parseInt(str(key));
        println("Loading skeleton from file /positions" + fileIndex + ".txt ...");
        skeletonPlayer.reader = createReader("/kin1/positions" + fileIndex + ".txt");   
        while(skeletonPlayer.loadNextFrame() != "") {
            skeletonPlayer.state = skeletonPlayer.STOPPED;
        }
        skeletonPlayer.loaded = true;
        skeletonPlayer.state = skeletonPlayer.PLAYING;
        try {
          println("Skeleton loaded. Closing file to start playback ...");
          skeletonPlayer.reader.close();
          skeletonPlayer.currFrame = 0;
          
        } catch (IOException e) {
          e.printStackTrace();
        }
        
        //graphPlayer = new GraphPlayer(3);
        //graphPlayer.loaded = false;
        //println("Loading Myo captured data from file /myoReadings_" + fileIndex + ".csv ...");
        //graphPlayer.reader = createReader("myoReadings_" + fileIndex + ".csv");
        //while(graphPlayer.loadNextFrame() != "") {
        //    graphPlayer.state = graphPlayer.STOPPED;
        //}
        //graphPlayer.loaded = true;
        //graphPlayer.state = graphPlayer.PLAYING;
        //try {
        //  println("Myo captured data loaded. Closing file to start playback ...");
        //  graphPlayer.reader.close();
        //  graphPlayer.currFrame = 0;
          
        //} catch (IOException e) {
        //  e.printStackTrace();
        //}
      }
      //else {
      //  state = State.DEFAULT;
      //}
      
    case 'p': //  replay
      if(skeletonPlayer != null){
        if(skeletonPlayer.loaded) {
          skeletonPlayer.currFrame = 0;
          skeletonPlayer.nextMillis = skeletonPlayer.getTimestampAtCurrFrame();
          skeletonPlayer.callerInitialMillis = millis();
          state = State.PLAYBACK;
          skeletonPlayer.state = skeletonPlayer.PLAYING;
          println("----");
          
          //graphPlayer.currFrame = 0;
          //graphPlayer.nextMillis = skeletonPlayer.getTimestampAtCurrFrame();
          //graphPlayer.callerInitialMillis = millis();
          //graphPlayer.state = skeletonPlayer.PLAYING;
          return;  
        }
      }
    break;

    case 'i': showRGB = !showRGB; break;
    case 'k': showSkeletonTracking = !showSkeletonTracking; break;

    case 'n': fileIndex = max(0,--fileIndex); break;

    case 'm': fileIndex = min(40,++fileIndex); break;
    
    case 'd':
      state = State.DEFAULT;
      //graphPlayer.state = graphPlayer.STOPPED;
      skeletonPlayer.state = skeletonPlayer.STOPPED;
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
    
    if((millis()-skeletonPlayer.callerInitialMillis) > skeletonPlayer.nextMillis)
    {
      while((millis()-skeletonPlayer.callerInitialMillis) > skeletonPlayer.nextMillis)
      {
        skeletonPlayer.nextMillis = skeletonPlayer.getTimestampAtCurrFrame();
        
        //println("skeletonPlayer.currFrame = " + skeletonPlayer.currFrame);
       
        skeletonPlayer.currFrame++;
        
        if(skeletonPlayer.currFrame >= skeletonPlayer.totalFrames) {
          skeletonPlayer.currFrame = skeletonPlayer.totalFrames - 1;
          println("Animation finished");
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
  }
}

void drawGraphFrame()
{
  
  if(graphPlayer.currFrame < graphPlayer.totalFrames-1)
  {
    //println((millis()-graphPlayer.callerInitialMillis) + " " + graphPlayer.getNextMillis());
    
    if((millis()-graphPlayer.callerInitialMillis) > graphPlayer.getNextMillis())
    {
      while((millis()-graphPlayer.callerInitialMillis) > graphPlayer.getNextMillis())
      {
        //graphPlayer.setNextMillis(graphPlayer.getTimestampAtCurrFrame());
        
        //println("skeletonPlayer.currFrame = " + skeletonPlayer.currFrame);
       
        graphPlayer.currFrame++;
        
        if(graphPlayer.currFrame >= graphPlayer.totalFrames) {
          graphPlayer.currFrame = graphPlayer.totalFrames - 1;
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
    p.addPoint(graphPlayer.getPointsAtCurrFrame());
    p.plotPoints();
    //println(millis());
  }
  else  //  drawing last frame 
  {
    p.plotPoints();
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
    if(skeletonPlayer.currFrame < skeletonPlayer.totalFrames-1) {
      fill(0,255,0);
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