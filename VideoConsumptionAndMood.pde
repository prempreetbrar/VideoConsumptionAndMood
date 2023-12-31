//This .pde will not run until the controlP5 library is installed to your processing instance
// This is very easy and can be done by going to Sketch -> Import Library -> Manage Libraries and searching for "controlP5" and pressing the install button

import controlP5.*;

// ControlP5 library and objects for UI
ControlP5 cp5;
DropdownList moodFilter;

//global variables to keep track of data and interactions
IntDict moodToColor = new IntDict(); 
Table collectedData; // our data from phase 3
SelectedBox selection = new SelectedBox(); // the current box selected by the user for details-on-demand
boolean beforeSelected = true; // a boolean tracking whether the user wants to see the mood before or the mood after viewing
ArrayList<SelectableDataPoint> dataPoints = new ArrayList<SelectableDataPoint>();
ArrayList<CollectorText> collectorLabels = new ArrayList<CollectorText>();


//class representing the text to write for each collector; x and y is the location of the label
class CollectorText {
  public String collector;
  public float x;
  public float y;

  CollectorText(String c, float x1, float y1) {
    collector = c;
    x = x1;
    y = y1;
  }
}


// Class to represent selected data
class SelectedBox {
  // Properties of the data
  public String collector;
  public String day;
  public String videoType;
  public String intentionality;
  public String duration;
  public String activityBefore;
  public String moodBefore;
  public String moodBeforeIntensity;
  public String moodAfter;
  public String moodAfterIntensity;
  public String location;
  public String device;
  public String deviceProximity;

  // Default constructor
  SelectedBox()
  {
    empty();
  }
  
  // to empty the details-on-demand box
  void empty() {
    collector="";
    day="";
    videoType="";
    intentionality="";
    duration="";
    activityBefore="";
    moodBefore="";
    moodBeforeIntensity="";
    moodAfter="";
    moodAfterIntensity="";
    location="";
    device="";
    deviceProximity="";
  }
}

// Class representing raw data from the table (csv file)
class RawData {
  public String collector;
  public String day;
  public String videoType;
  public String intentionality;
  public String duration;
  public String activityBefore;
  public String moodBefore;
  public String moodBeforeIntensity;
  public String moodAfter;
  public String moodAfterIntensity;
  public String location;
  public String device;
  public String deviceProximity;

  RawData(TableRow rawData) {
    // remove accidental leading and trailing whitespaces from phase 3 data collection
    collector = rawData.getString("Collector").trim();
    day = rawData.getString("Day of Week").trim();
    videoType = rawData.getString("Video Content Type").trim();
    intentionality = rawData.getString("Intentionality").trim();
    duration = rawData.getString("Duration (min)").trim();
    activityBefore = rawData.getString("Current Activity Before Viewing").trim();
    moodBefore = rawData.getString("Mood Before (Category)").trim();
    moodBeforeIntensity = rawData.getString("Mood Before (Rating)").trim();
    moodAfter = rawData.getString("Mood After (Category)").trim();
    moodAfterIntensity = rawData.getString("Mood After (Rating)").trim();
    location = rawData.getString("Physical Location").trim();
    device = rawData.getString("Viewing Device").trim();
    deviceProximity = rawData.getString("Proximity of Device").trim();
  }
}


// Class representing selectable data points for visualization
class SelectableDataPoint {
  public PVector position_; //position of visualization
  public float width_; // related to duration
  public float height_; // related to intensity of mood
  color colour_; // related to type of mood
  RawData rawData_; //the raw data
  boolean initialMood_;
  public boolean isVisible_;

  SelectableDataPoint(float x, float y, TableRow rawData) {
    position_ = new PVector(x, y);
    rawData_ = new RawData (rawData);
    colour_ = moodToColor.get(rawData_.moodBefore);
    height_ = Integer.parseInt(rawData_.moodBeforeIntensity);
    
    // add 10 to each bar (so that sessions with incredibly small durations are still visible to the naked eye and clickable for details).
    // Scale all by 2.5 so that they fit in the chosen window size. Note that these numbers are arbitrary and would change if we chose
    // a different window size.
    width_ =  (Integer.parseInt(rawData_.duration)+10)/2.5; 
    initialMood_=true; // we are defaulting to showing the user the mood before each video (initial mood)
    isVisible_=false;
  }

  // Display the data point
  void show() {
    fill(colour_);
    strokeWeight(3);
    rect(position_.x, position_.y, width_, height_);
    isVisible_ = true;
  }

  //Hide the data point
  void hide()
  {
    isVisible_ = false;
  }

  // Switch between initial and final mood views -> Yi's reconfigure
  void switchViewingModes()
  {
    if (initialMood_) {
      colour_ = moodToColor.get(rawData_.moodAfter);
      height_ = Integer.parseInt(rawData_.moodAfterIntensity);
    } else {
      colour_ = moodToColor.get(rawData_.moodBefore);
      height_ = Integer.parseInt(rawData_.moodBeforeIntensity);
    }
    initialMood_=!initialMood_;
  }

  // Write selected data to the selection object -> Schneiderman's details-on-demand
  void writeSelection()
  {
    if (isVisible_) {
      selection.collector =     rawData_.collector;
      selection.day =     rawData_.day;
      selection.videoType =     rawData_.videoType;
      selection.intentionality =     rawData_.intentionality;
      selection.duration =   rawData_.duration;
      selection.activityBefore =rawData_.activityBefore;
      selection.moodBefore=rawData_.moodBefore;
      selection.moodBeforeIntensity=rawData_.moodBeforeIntensity;
      selection.moodAfter=rawData_.moodAfter;
      selection.moodAfterIntensity=rawData_.moodAfterIntensity;
      selection.location=rawData_.location;
      selection.device=  rawData_.device;
      selection.deviceProximity =     rawData_.deviceProximity;
    }
  }
}


void setup() {
  // Set canvas size and background (chosen to be large enough so that the data isn't squished and selection is possible)
  size(1660, 800);
  background(51);

  // Load data from CSV file; pass in header so that we can access data by column name (easier than using indices)
  collectedData = loadTable("data.csv", "header");

  // Define colors for different mood categories
  moodToColor.set("Angry", #FF0000);
  moodToColor.set("Sad", #0000FF);
  moodToColor.set("Happy", #FFFF00);
  moodToColor.set("Confused", #FF00FF);
  moodToColor.set("Tired", #696969);
  moodToColor.set("Tense", #FFFFFF);
  moodToColor.set("Afraid", #000000);
  moodToColor.set("Energetic", #00FF00);
  textSize(24);

  float x = 0;
  float y = 0;
  StringList collectors = new StringList();

  // Loop through each row in the collectedData table
  for (TableRow row : collectedData.rows()) {
    // Extract collector information from the row
    String collector = row.getString("Collector").trim();
    // check if we've encountered this collector before; if not, create a label for them
    if (!collectors.hasValue(collector)) {
      // if the collector is the first one being displayed, add less padding (we don't want
      // a huge gap from the top). Otherwise, add more padding (to ensure there is enough space
      // between the previous collector's datapoints and the current collector's name)
      if (collectors.size()>0) {
        x=0;
        y+=150;
      } else {
        y+=45;
      }
      collectors.append(collector);
      CollectorText label = new CollectorText(collector, x, y);
      collectorLabels.add(label);
    }

    // Create a SelectableDataPoint for each row and add it to the dataPoints list
    SelectableDataPoint dataPoint = new SelectableDataPoint(x, y, row);
    dataPoints.add(dataPoint);

    // Update x position for the next data point
    x+=dataPoint.width_;
  }

  cp5 = new ControlP5(this);

  // add the mood filter to the bottom right of the window -> Shneiderman's filter
  moodFilter = cp5.addDropdownList("MoodFilter").setPosition(1200, 650)
    .setSize(120, 100)
    .setBarHeight(20)
    .setItemHeight(20);

  // add all 8 VAMS (Visual Analogue Mood Scale) moods
  moodFilter.addItem("All", 0);
  moodFilter.addItem("Angry", 1);
  moodFilter.addItem("Sad", 2);
  moodFilter.addItem("Happy", 3);
  moodFilter.addItem("Confused", 4);
  moodFilter.addItem("Tired", 5);
  moodFilter.addItem("Tense", 6);
  moodFilter.addItem("Afraid", 7);
  moodFilter.addItem("Energetic", 8);

  // show all data when the user first runs the program -> Shneiderman's overview
  moodFilter.setLabel("All");
  moodFilter.setOpen(false);
}

void draw() {
  // Draw background and collector labels
  background(211);
  for (CollectorText collector : collectorLabels) {
    fill(0); // we want the textbox to be transparent (ie. just the text itself)
    text(collector.collector, collector.x, collector.y);
  }

  // Get selected mood from the filter
  String selectedMood = moodFilter.getLabel();

  // Display data points based on the selected mood
  for (SelectableDataPoint dataPoint : dataPoints) {
    // Filter data points based on the selected mood
    if (selectedMood.equals("All") || dataPoint.rawData_.moodBefore.equals(selectedMood)) {
      dataPoint.show(); //Show points the meet the criteria
    } else {
      dataPoint.hide(); //hide points that don't
    }
  }

  // Display selected data information (details-on-demand)
  fill(255);
  rect(1200, 45, 400, 600);
  fill(0);
  text("Collector: "+selection.collector, 1225, 75);
  text("Day Collected: "+selection.day, 1225, 125);
  text("Video Type: "+selection.videoType, 1225, 175);
  text("Intentionality: "+selection.intentionality, 1225, 225);
  text("Duration: "+selection.duration, 1225, 275);
  text("Activity before: "+selection.activityBefore, 1225, 300, 375, 125);
  text("Mood Before: "+selection.moodBefore + "=" +selection.moodBeforeIntensity, 1225, 375);
  text("Mood After: "+selection.moodAfter+"=" +selection.moodAfterIntensity, 1225, 425);
  text("Location: "+selection.location, 1225, 475);
  text("Device: "+selection.device, 1225, 525);
  text("Device Proximity: " + selection.deviceProximity, 1225, 575);

  //Showing label for which mood is currently being displayed
  if (beforeSelected) {
    text("Displaying Mood Before", 1350, 668);
  } else
  {
    text("Displaying Mood After", 1350, 668);
  }
}

// Function to handle key presses
void keyPressed() {
  // Toggle between initial and final mood views on spacebar press (Yi's reconfigure)
  if (key == ' ') {
    for (SelectableDataPoint dataPoint : dataPoints) {
      dataPoint.switchViewingModes();
    }
  }
  beforeSelected = !beforeSelected;
}

// Function to handle mouse clicks
void mousePressed() {
  boolean datapointClicked = false;
  // For all data points, Check if a data point is clicked and update the selection
  for (SelectableDataPoint dataPoint : dataPoints) {
    if (mouseX >= dataPoint.position_.x && mouseX < dataPoint.position_.x + dataPoint.width_ &&
      mouseY >= dataPoint.position_.y && mouseY < dataPoint.position_.y + dataPoint.height_) {
      datapointClicked = true;
      dataPoint.writeSelection();
    }
  }
  
  // if the user clicked off the datapoints, they do not want to see the detail anymore; empty the box
  if (!datapointClicked) {
    selection.empty();
  }
}

//Function to handle controlP5 event change ie.changing mood filter
void controlEvent(ControlEvent filterMood) {
  if (filterMood.isController()) {
    redraw(); // Trigger redraw when the mood filter changes
  }
}
