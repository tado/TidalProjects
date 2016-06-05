void drawChar(char c, Thing thing) {
  switch(c) {
  case 'a': 
    a(thing); 
    break;
  case 'b': 
    b(thing); 
    break;
  case 'c': 
    c(thing); 
    break;
  case 'd': 
    d(thing); 
    break;
  case 'e': 
    e(thing); 
    break;
  case 'f': 
    f(thing); 
    break;
  case 'g': 
    g(thing); 
    break;
  case 'h': 
    h(thing); 
    break;
  case 'i': 
    i(thing); 
    break;
  case 'j': 
    j(thing); 
    break;
  case 'k': 
    k(thing); 
    break;
  case 'l': 
    l(thing); 
    break;
  case 'm': 
    m(thing); 
    break;
  case 'n': 
    n(thing); 
    break;
  case 'o': 
    o(thing); 
    break;
  }
}


/*
This is part of an ongoing tristeTren set.
(drawings by @oliverse)
*/


void a(Thing thing) {
}


void b(Thing thing) {
  pushMatrix();
  for (int i = 0; i < in.bufferSize () - 1; i++) {    
    //fill(lerpColor(#FFFFFF, #FFDA03, random(1))); // amarilloblanco
    noStroke();
    fill(lerpColor(#FFFFFF, thing.c, random(1)), random(125, 255));
    translate(-2 + in.left.get(i) * 22, 0);
    rect(0, 0, 0.6, 1 + in.left.get(i) * 25);
  }
  popMatrix();
}

void c(Thing thing) {
}

void d(Thing thing) {
  pushMatrix();
  for (int i = 0; i < in.bufferSize () - 1; i++) {    
    noStroke(); 
    translate(random(200, 60), 0);
    fill(thing.c);
    rect(0, 0, 20 + in.left.get(i) * 1225, random(103));
  }
  popMatrix();
}

void e(Thing thing) {
  pushMatrix();
  for (int i = 0; i < in.bufferSize () - 1; i++) {    
    noStroke();
    fill(thing.c); // amarilloblanco
    translate(random(13, -13), 0 + in.left.get(i) * 15);
    ellipse(0, 0, 3 + in.left.get(i) * 815, 
      3 + in.left.get(i) * 815);
  }
  popMatrix();
}

void f(Thing thing) {
  pushMatrix();
  for (int i = 0; i < in.bufferSize () - 1; i++) {    
    noFill();
    stroke(lerpColor(thing.c, #FFA7EC, random(1))); // amarilloblanco
    translate(random(133, -133), 0);
    line(0, 0, 13 + in.left.get(i) * 2525, 
      13 + in.left.get(i) * 2525);
  }
  popMatrix();
}

void g(Thing thing) {
  pushMatrix();
  for (int i = 0; i < in.bufferSize () - 1; i++) {    
    noFill();
    stroke(lerpColor(thing.c, #FFCB0D, random(1))); // amarilloblanco
    translate(random(133, -133), 0);
    line(0, 0, 13 + in.left.get(i) * 4000, 
      13 + in.left.get(i) * 4000);
  }
  popMatrix();
}

void h(Thing thing) {
  pushMatrix();  
  beep.disableStyle();
  noStroke();
  fill(thing.c);
  translate(random(233), 0);
  shape(beep, 0, 0, 120, 120);  
  popMatrix();
}

void i(Thing thing) {
  pushMatrix();  
  beep1.disableStyle();
  noStroke();
  fill(thing.c);
  translate(random(233), 0);
  shape(beep1, 0, 0, 160, 160);  
  popMatrix();
}

void j(Thing thing) {
  pushMatrix();  
  beep2.disableStyle();
  noStroke();
  fill(thing.c);
  translate(random(-133), 0);
  shape(beep2, 0, 0, 160, 160);  
  popMatrix();
}

void k(Thing thing) {
  pushMatrix();  
  beep3.disableStyle();
  noStroke();
  fill(thing.c);
  translate(random(-133), 0);
  shape(beep3, 0, 0, 160, 160);  
  popMatrix();
}

void l(Thing thing) {
  pushMatrix();  
  beep4.disableStyle();
  noStroke();
  fill(thing.c);
  translate(random(-133), 0);
  shape(beep4, 0, 0, 160, 160);  
  popMatrix();
}

void m(Thing thing) {
  pushMatrix();  
  beep5.disableStyle();
  noStroke();
  fill(thing.c);
  translate(random(-133), 0);
  shape(beep5, 0, 0, 160, 160);  
  popMatrix();
}

void n(Thing thing) {
  pushMatrix();  
  beep6.disableStyle();
  noStroke();
  fill(thing.c);
  translate(random(-133), 0);
  shape(beep6, 0, 0, 160, 160);  
  popMatrix();
}

void o(Thing thing) {
  pushMatrix();  
  beep7.disableStyle();
  noStroke();
  fill(thing.c);
  translate(random(-133), 0);
  shape(beep7, 0, 0, 160, 160);  
  popMatrix();
}

/*
 void p(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void q(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void r(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void s(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void t(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void u(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void v(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void w(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void x(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void y(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 void z(Thing thing) {
 ellipse(0, 0, 10, 10);
 }
 */