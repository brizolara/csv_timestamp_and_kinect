# csv-timestamp-and-kinect

Boilerplate code for personal use.

Main file is csv_timestamp_and_kinect.pde (Processing language/environment). Plays back .csv curves alongside with Kinect v1 recordings, synced via timestamps - no external synchronization: we assume both files start at the same time...

* Records timestamped Kinect data (uses Kinect4Win Processing library [Kinect v1])
* Players to render timestamped data:
  * Skeleton recorded by this application
  * Myo data (CSV format). This plot is adapted from Rebeca Fiebrink's [OSCDataPlotter](https://github.com/fiebrink1/wekinator_examples/tree/master/teaching_examples/OSCDataPlotter).

![](https://gitlab.com/brizolara/csv_timestamp_and_kinect/-/blob/master/csv_timestamp_and_kinect.png)

---------------------------------------------------
LICENSE: GPL v2.0