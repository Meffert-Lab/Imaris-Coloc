#Overview

Included are a package of scripts that are for use with the Lin28 utility for IMARIS.

All scripts are Matlab XTensions for IMARIS and must be moved to the XT/matlab folder within your IMARIS installation.

1. BatchRename

During Batch Processing with surfaces or spots definition, IMARIS will 1) make it the lowest object in the root object tree 2) assign a name that includes a timestamp and 3) save an additional file for each processed file in the same directory, where the parent file is unedited but the copy is (the copy has a timestamp added to the filename).
This is problematic for scripts in this folder that rely on the object name. After moving the batch-processed files from the directory containing the parent files, you can use BatchRename to rename the lowest object in the root object tree to one of your choosing. BatchRename will start on the currently open .ims file and change the name of the lowest object, then open the next file in the directory where the currently open image is located, and change the name of the lowest object. This continues for all .ims files in the directory.

2. Lin28Util
Dependencies:
 - S100Cleaner
 - XT_Surface_Surface_coloc
 - XTDeleteSpotsNotInSurface
 - XTDeleteSurfacesNotContainingSpot

Lin28Util requires the following to be predefined:
 - MAP2 Surfaces
 - S100 Surfaces
 - Lin28 Surfaces
 - Lin28 Spots

Lin28Util will determine which spots lie exclusively inside the MAP2 surfaces and S100 surfaces by first determining which spots lie inside MAP2 and S100 and removing any duplicates from S100. The locations of spots are then used to determine which surface corresponds to each spot - if a Lin28 spot from the MAP2 subset is found to localize within a Lin28 surface, that surface will be assigned to a MAP2 containing Lin28 surfaces set.

The results are saved in the same directory as the images as .csv files.

#Instructions

1. Install matlabextensions

Requires:
 - MATLAB R2021B or later (untested with MATLAB Runtime)
 - IMARIS 9.6.1 or later

In order to install Lin28Util, clone this repository using Git (or download and unzip) into the "SharedSupport/XT/matlab" directory of your installation.
On Mac OSX, for example, this will be /Applications/Imaris\ 9.6.0.app/Contents/SharedSupport/XT/matlab.

Example commands:

cd /Applications/Imaris\ 9.6.0.app/Contents/SharedSupport/XT/matlab
git clone https://github.com/Meffert-Lab/matlabextensions

Once the scripts have been added to this directory, check that both of the following directories have been added as XTensions paths within IMARIS:

 - [YOUR_IMARIS_DIRECTORY]/SharedSupport/XT/rtmatlab
 - [YOUR_IMARIS_DIRECTORY]/SharedSupport/XT/matlab
 - [YOUR_IMARIS_DIRECTORY]/SharedSupport/XT/matlab/matlabextensions

Check that either the MATLAB runtime or the MATLAB application are accessible by IMARIS.

2. Run matlabextensions

Prerequisites:
 - Ensure that all files in the directory you would like to analyze contain 'MAP2', 'S100', and 'Lin28' surfaces as well as 'Lin28' spots.
  - If they do not, you may either define each manually or use IMARIS batch processing. Caution when using batch processing - this generates a new file instead of modifying the original. You can move the batch processing result files (their filenames will have an appended timestamp) to a new directory and run BatchRename to change the name of the result to one you specify.

Launch IMARIS and open the first .ims file inside of a directory you would like to analyze.
Under Image Processing/Spots Functions, find 'PunctaUtil'. Click it to run.

A prompt will ask for the names of the Primary Channel, Secondary Channel, and Puncta Channel. If you have highly overlapping channels where one takes up less volume than another, put the smaller volume channel as the Primary Channel (i.e. MAP2) and the larger volume channel as the Secondary Channel (i.e. S100).

Lin28Util will iterate through all .ims files in the folder, starting with the file currently open, and calculate the number of Lin28 spots and volume of Lin28 surfaces inside MAP2 and S100.

If you would like to calculate the colocalized volume between MAP2 and S100, find 'Surface-Surface coloc' under Image Processing/Surfaces Functions. XT_Surface_Surface_coloc will iterate through all files in the folder, starting with the file currently open.

The outputs of both Lin28Util and XT_Surface_Surface_coloc are .csv files.