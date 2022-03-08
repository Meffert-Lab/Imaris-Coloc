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