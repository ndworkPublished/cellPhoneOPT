


This ReadMe file describes how to use the code to reconstruct a volume from Optical Projection Tomography data.
This code accompanies the manuscript "Inexpensive Optical Projection Tomography on a Mobile Phone Platform" by
Gennifer T. Smith, James Sikes, and Nicholas Dwork.


Before reconstructing the data, one must first find the rotation center.  To do so, run run_findRotCenter.
This will create a directory called rotCenters_<datacaseNumber>.  In that directory, you will see the reconstructions
for many different possible rotation centers.  Choose the one that looks the best.

Once you've selected the rotation center, enter it into loadDatacase.m.
Specify the rotCenterX variable for your datacase.

Then you can reconstruct the volume by running run_reconOPT.



