# csv-timestamp-and-kinect

Boilerplate code for personal use. Main file is csv_timestamp_and_kinect.pde (Processing language/environment). Plays back .csv curves alongside with Kinect v1 recordings, synced via timestamps - no external synchronization: we assume both files start at the same time...

* Records timestamped Kinect data (uses Kinect4Win Processing library [Kinect v1])
* Implements a player to render timestamped data:
  * Plays back skeleton recorded by this application
  * Plays back data curves from .csv files with other timestamped motion capture data I had recorded. This plot is adapted from Rebeca Fiebrink's [OSCDataPlotter](https://github.com/fiebrink1/wekinator_examples/tree/master/teaching_examples/OSCDataPlotter).
* Assumes certain file structure (which is not in this repository):

|- csv_timestamp_and_kinect
|-- csv_timestamp_and_kinect.pde 
|- data
|-- 1
|---- myos
|---- kinect
|---- video
|-- 2
|---- myos
|---- kinect
|---- video
|-- ...

---------------------------------------------------
LICENSE: GPL v2.0