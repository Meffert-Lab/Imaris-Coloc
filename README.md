# Imaris Coloc: MATLAB XTensions used to analyze surface-surface colocalization

## Requirements

- MATLAB R2021B or later (untested with MATLAB Runtime)
- IMARIS 9.6.1 or later

## Installation

In order to install this utility, clone this repository using Git (or download and unzip) into the "SharedSupport/XT/matlab" directory of your installation. On Mac OSX, for example, this will be /Applications/Imaris\ 9.6.0.app/Contents/SharedSupport/XT/matlab.

Once the scripts have been added to this directory, check that both of the following directories have been added as XTensions paths within IMARIS:

    [YOUR_IMARIS_DIRECTORY]/SharedSupport/XT/rtmatlab
    [YOUR_IMARIS_DIRECTORY]/SharedSupport/XT/matlab
    [YOUR_IMARIS_DIRECTORY]/SharedSupport/XT/matlab/matlabextensions

Check that either the MATLAB runtime or the MATLAB application are accessible by IMARIS.

## Pre-Processing

Prior to running either of these scripts, you must define all surfaces to be colocalized within each image. Instructions are as follows:

1. Start by creating all the surfaces for each channel you would like to analyze within a single image
2. Save the surface creation parameters for batch processing
3. Use batch processing to define surfaces for all the images you would like to analyze with manual adjustment as necessary

## Running

With your first file to be analyzed open in IMARIS, Navigate to the XT menu --> Surfaces Functions --> Batch Coloc OR Surface-Surface coloc.
Click to run either XT_Surface_Surface_coloc or XT_BatchColoc for either a single file or many files respectively. Prompts will open up in MATLAB GUIs.
