# Maui Diameter Data Cleaning

MauiDiameterDataCleaning.m is a signal processing algorithm that takes in the output of Maui and identifies artifacts within the data, replacing them with the median of the entire dataset. Currently, there are specific metrics meant for the ICA and VA arteries, but this can easily be expanded with relevant physiological metrics. 

## Usage

There are 3 main functions utilized in the script:

**MauiDiameterDataCleaning:** 
Outputs a list of the names of the edited files chosen to be saved. Saves a .m file containing the reformatted diameter as a MATLAB array. 

**saveButtonPushed:** Opens another UI to ask the user to save, 'Yes' saves the output into the same directory as the file as 'filename_Clean.mat', 'No' skips this file and proceeds to the next .csv in the file path.

**smoothOutliers:** Takes the original diameter as well as the output from a hampel filter as input. For each flagged outlier, utilizes an offset to set ever value +/- to an outlier equal to the median of the entire signal.

## Adjustable Parameters

- **source_path:** Source path of your dataset
- **filePattern:** Set the arrangement of the file pattern, default is to subfolders containg .csv's
- **numSections:** Determines the number of sections to split the data up into, default is 1. Use more for increasingly messy data.
- **offset:** Sets the window around any flagged outliers equal to median with window size equal to offset, default is 5

## Contributing

Please feel free to update and utilize this script, I can post up the relevant GitHub if you would like. The main addition would definitely be the interpolation of outlier's rather than using the mean.
