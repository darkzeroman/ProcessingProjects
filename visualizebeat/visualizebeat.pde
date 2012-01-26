import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;
AudioPlayer song;
FFT fft;
String windowName;
Data data;
AudioBuffer buffer;

float[] peakDecay;
float peakDecayFactor, eRadius, eRadius1, cum, errTol;
BeatDetect beat;
ArrayList bands;
boolean hasAnalyzed;
int fftspacing, wavespacing, numBreaks, multfactor, numofChanges, bsize;

void setup()
{
  size(800, 600);

  minim = new Minim(this);
  data = new Data();
  data.beginSave();

  //initializing constants
  eRadius1 = 20;
  hasAnalyzed = false;
  bsize = 512;
  errTol = .9;
  multfactor = 10;
  peakDecayFactor = .95;
  eRadius = 20;


  song = minim.loadFile("sample.mp3", bsize); // 
  beat = new BeatDetect();
  beat.setSensitivity(100);
  ellipseMode(CENTER_RADIUS);
  song.play(5000);
  fft = new FFT(song.bufferSize(), song.sampleRate());
  textFont(createFont("SanSerif", 16));
  windowName = "None";
  fft.logAverages(22, 4);

  wavespacing = bsize/song.bufferSize();
  fftspacing =  bsize/(fft.avgSize());

  //frameRate(20);
}


void draw()
{ 

  background(0);
  numofChanges = 0;
  stroke(255);
  fft.forward(song.mix);

  if (!hasAnalyzed) {
    analyzeSong();
  }
  //the peak decays
  for (int i = 0; i< peakDecay.length; i++) {
    peakDecay[i] = peakDecay[i]*peakDecayFactor;
    if (peakDecay[i] < 5)
      peakDecay[i] = 5;
  }

  //drawing the wave form
  for (int i = 0; i < song.bufferSize() - 1; i++)
  {
    line(i*wavespacing, 50 + song.left.get(i)*50, i*wavespacing+wavespacing, 50 + song.left.get(i+1)*50);
    line(i*wavespacing, 150 + song.right.get(i)*50, i*wavespacing+wavespacing, 150 + song.right.get(i+1)*50);
  }

  //float[] fftspectrum = new float[fft.avgSize()];
  //drawing the fft
  for (int i = 0; i < fft.avgSize(); i++)
  {
    // draw the line for frequency band i, scaling it by 4 so we can see it a bit better
    rect( i*fftspacing, height - abs(fft.getAvg(i)*multfactor)-5, fftspacing, abs(fft.getAvg(i)*multfactor)+5);
    //    fftspectrum[i] = abs(fft.getAvg(i)*multfactor);
  }
  //  data.add(fftspectrum);

  fill(128);

  //  float[] averages = new float[numBreaks];
  float sum;
  float maxnum = 0;
  //operations for every band group

  for (int i = 0; i< bands.size(); i=i+2) {
    stroke(255, 0, 0);
    sum = 0;
    maxnum = 0;
    //summing and finding the greatest values;
    for (int j = (Integer)  bands.get(i); j <= (Integer) bands.get(i+1); j++) {

      //System.out.println("I: "+(Integer) bands.get(i) + " to: " + (Integer) bands.get(i+1));
      //System.out.println(j);
      //System.out.println("request: " + j);
      float temp = fft.getAvg(j)*multfactor;
      if (temp > maxnum) //summing each band
        maxnum = temp;
      sum = sum + abs(temp);
    }
    //System.out.println(" first band: "+ bands.get(i) + " second band: " + ((Integer) bands.get(i+1)+1));
    int divisor = (Integer) bands.get(i+1)-(Integer) bands.get(i)+1;
    //System.out.print(i + ": " + sum + " ");
    float average = sum/(divisor); //average value

    if (peakDecay[i] < average) {
      numofChanges++;
      peakDecay[i] = maxnum;
      stroke (255);
    }
    else
      stroke(0);
    //change line
    line(fftspacing*((Integer) bands.get(i)), height/2, fftspacing*((Integer) bands.get(i+1)+1), height/2);

    stroke(255, 0, 0);
    //peak line
    line(fftspacing*((Integer) bands.get(i)), height - peakDecay[i]-5, fftspacing*((Integer) bands.get(i+1)+1), 
    height- peakDecay[i]-5);
    //averages[i] = sum;
    //average line
    stroke(0, 255, 0);
    line(fftspacing*((Integer) bands.get(i)), height - average-5, fftspacing*((Integer) bands.get(i+1)+1), height- average-5);
  }
  //for coloring the circle
  fill(255);
  stroke(255);
  if (numofChanges > 1) {
    fill(128);
    eRadius =80;
  } 
  else {
    fill(255);
  }
  ellipse(600, 300, eRadius, eRadius);
  eRadius *= .95;
  if (eRadius < 20) eRadius = 20;

  ///BEAT CODE
  stroke(255);
  fill(255);
  beat.detect(song.mix);
  float a = map(eRadius1, 20, 80, 60, 255);
  fill(60, 255, 0, a);
  if ( beat.isOnset() ) eRadius1 = 80;
  ellipse(width/2, height/2, eRadius1, eRadius1);
  eRadius1 *= 0.95;
  if ( eRadius1 < 20 ) eRadius1 = 20;



  //data.add(averages);
  //  data.add(peakDecay);
  // keep us informed about the window being used
  text("The window being used is: " + windowName, 5, 20);
  text("numChanges: " + numofChanges, 5, 100);
}

void keyReleased()
{
  if ( key == 'w' ) 
  {
    // a Hamming window can be used to shape the sample buffer that is passed to the FFT
    // this can reduce the amount of noise in the spectrum
    fft.window(FFT.HAMMING);
    windowName = "Hamming";
  }

  if ( key == 'e' ) 
  {
    fft.window(FFT.NONE);
    windowName = "None";
  }
  if (key == 't')
  {
    stop();
  }
  if (key == 'd')
    song.play(song.position() + 10*1000);
  if (key == 'a')
    song.play(song.position() - 5*1000);
  if (key == 's')
    hasAnalyzed = false;
  if (key == 'z') {
    hasAnalyzed = false;
    errTol = errTol-.1;
    System.out.println(errTol);
  }
  if (key == 'x') {
    hasAnalyzed = false;
    errTol = errTol +.1;
    System.out.println(errTol);
  }
  if (key == 'y'){
   save("screenshot.tif"); 
  }
}
void analyzeSong() {

  cum = 0;
  bands = new ArrayList();
  int lastIndex = 0;
  //    System.out.println('0');
  for (int i = 0; i < fft.avgSize(); i++) {
    cum = cum + fft.getAvg(i)*multfactor;

    float average = cum / (1+i - lastIndex);
    float tempavg = (average + fft.getAvg(i)) / 2;

    float compareValue = fft.getAvg(i)/ tempavg;
    if (tempavg < 1) 
      compareValue = 1; //for when the  values are realy close to zero; 
    if ((compareValue > 1+errTol)|(compareValue < 1-errTol)) {
      bands.add(lastIndex);
      bands.add(i);
      lastIndex = i+1;
      cum = 0;
    }
  }


  if ( lastIndex!= fft.avgSize()) {
    bands.add(lastIndex);
    bands.add(fft.avgSize()-1);
  }


  data.add(bands);
  for (int i = 0; i < bands.size(); i++)
    //System.out.print(bands.get(i) + " ");
    numBreaks = bands.size();

  peakDecay = new float[numBreaks];
  for (int i = 0; i < numBreaks; i++)
    peakDecay[i] = 0;

  hasAnalyzed = true;
}

void stop()
{
  // data.endSave("test.txt"); uncomment if save information is needed
  // closing Minim
  song.close();
  minim.stop();

  super.stop();
}

