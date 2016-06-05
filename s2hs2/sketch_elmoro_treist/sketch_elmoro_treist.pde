import oscP5.*;
import netP5.*;
import oscP5.*;
import netP5.*;
import processing.pdf.*;

OscP5 osc;

import ddf.minim.*;
Minim minim;
AudioInput in;

boolean record;
PFont f;
String words = "a";
int ml = words.length();
int palabras = 180;
PShape beep;
PShape beep1;
PShape beep2;
PShape beep3;
PShape beep4;
PShape beep5;
PShape beep6;
PShape beep7;

ArrayList<Thing> things = new ArrayList();

/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

void setup() {
  smooth();
  noCursor();
  frameRate(12);
  size(displayWidth, displayHeight); 
  /////////////////////////////////////////////////////////////////////
  printArray(PFont.list());
  /////////////////////////////////////////////////////////////////////
  colorMode(HSB);
  /////////////////////////////////////////////////////////////////////
  osc = new OscP5(this, 8010);
  minim = new Minim(this);
  minim.debugOn();
  in = minim.getLineIn(Minim.STEREO, 1024);
  beep = loadShape("beeep.svg");
  beep1 = loadShape("beeep1.svg");
  beep2 = loadShape("beeep2.svg");
  beep3 = loadShape("beeep3.svg");
  beep4 = loadShape("beeep4.svg");
  beep5 = loadShape("beeep5.svg");
  beep6 = loadShape("beeep6.svg");
  beep7 = loadShape("beeep7.svg");
}

void draw() {
  if (record) {
    beginRecord(PDF, "astr"+random(1000)+".pdf");
  }

  if ((keyPressed == true) && (key ==  '<')) {
    palabras = 180;
    noStroke();
    rectMode(CORNERS);
    fill(palabras);
    //fill(lerpColor(#FF746C, #C9D2FF, random(1)), random(255));
    rect(0, 0, width, height);
  } else {
    noStroke();
    rectMode(CORNERS);
    //    fill(lerpColor(#000000, #4A00C4, random(1)), random(255));
    fill(palabras);
    rect(0, 0, width, height);
  }
  synchronized(things) {
    for (Thing thing : things) {
      thing.display();
    }
  }
  for (int i = things.size () - 1; i >= 0; i--) {
    Thing thing = things.get(i);
    if (thing.finished()) {
      print("remove");
      things.remove(i);
    }
  }
  if (record) {
    endRecord();
    record = false;
  }
  // Use a keypress so thousands of files aren't created
  if (keyPressed) {
    if (key == 'b' || key == 'B') {
      record = true;
    }
  }
}

void oscEvent(OscMessage m) {
  String word = m.get(0).stringValue();
  float h = m.get(1).floatValue();
  float s = m.get(2).floatValue();
  float b = m.get(3).floatValue();
  float rotation = m.get(4).floatValue();
  float distance = m.get(5).floatValue();
  int life = m.get(6).intValue();
  float x = m.get(7).floatValue();
  float y = m.get(8).floatValue();
  int str = m.get(9).intValue();

  Thing thing = new Thing(word, 
    color(h*255, s*255, b*255), 
    rotation, 
    distance, 
    life, 
    int(x*width), int(y*height), 
    str
    );

  synchronized(things) {
    things.add(thing);
  }
}

void keyReleased() {
  if (palabras == 180) {
    if (key == '1' || key == '1') {
      palabras = #FF746C;
    }
  }

  if (palabras == 180) {
    if (key == '2' || key == '2') {
      palabras = #03FF8F;
    }
  }

  if (palabras == 180) {
    if (key == '3' || key == '3') {
      palabras = #93EAFF;
    }
  }
  if (palabras == 180) {
    if (key == '4' || key == '4') {
      palabras = #FFD900;
    }
  }
  if (palabras == 180) {
    if (key == '5' || key == '5') {
      palabras = #FFAB03;
    }
  }
  if (palabras == 180) {
    if (key == '6' || key == '6') {
      palabras = #FFCEF9;
    }
  }
}

void stop() {
  in.close();
  minim.stop();
  super.stop();
}