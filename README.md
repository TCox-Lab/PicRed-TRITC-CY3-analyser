# **CMM Lab - Picrosirius Red Fluorescence Analyser**
### CMM Lab website [Homepage](http://matrixandmetastasis.com)
### CMM Lab GitHub [Homepage](http://www.github.com/tcox-lab)
---
**ImageJ / FIJI script to analyse and quantify picrosirius red stained sections imaged under fluorescence (TRITC/Cy3) light microscopy.**  
_Requires ImageJ/FIJI 1.38m or above._  
_Tested working on Mac OSX 10.14 and above._  
_Tested working on Windows 10._

_Last updated: 17th Oct 2025._

**Citation:**  
TBC

**Description:**  
The script wraps a simple fluorescence signal quantifier into a loop that iterates through all of the defined images in a directory and sub-directories specified by the user.

_If using multiple sub-directories of images, please ensure that filenames are unique._

This script is designed to automate the quantification of whole tumour sections, by calculating a thresholded area of picrosirius red stained fluorescence signal in each image, as well as detecting the whole tissue boundary, and outputting the details, as well as some processing steps, collated tabulated results, and the option to apply a LUT.

The user can specify the thresholding values.

**All processed images should be taken using identical acquisition parameters and all outputs interrogated carefully**

---
### Installation

Ensure you have ImageJ or FIJI (preferred) installed.
- ImageJ is available from [here](https://github.com/imagej/imagej).
- FIJI is available from [here](https://github.com/fiji/fiji).

Copy the `CMM_PR-TRITC-Cy3.ijm` to the ImageJ/FIJI `plugins` directory.  

Restart ImageJ/FIJI.

The script should now appear in the Plugins Dropdown menu.

---
### Variables specified by the user include:

Upon launching, the script will ask for the following inputs:

- **File Type** - Specify input image file type (.tif .jpg etc.)*.
- **Tissue Detection Threshold** - Used to pick up the low level tissue autofluorescence for calculating the tissue boundary (_can be disabled below for ROIs_)
- **Backgrounding Threshold** - Minimal fluorescence signal threshold for PicRed signal
- **Run Total Tissue Area Detection** (Enable/Disable) - When enabled will attempt to define the tissue area. Disable for whole image ROIs
- **Run PR-T Signal Extraction** (Enable/Disable)- Calculate the fluorescence signal from the PicRed staining
- **Pretty Output** (Enable/Disable) - Applies a pretty LUT and saves as an extra output (_this is purely aesthetic and does not alter analysis_)
- **Launch Memory Monitor** (Enable/Disable) - Mainly for debugging.
- **Enable Batch Mode** (Enable/Disable) - Runs the script silently (_faster_).

_*Output images are saved in .png format. Avoid using input files in the .png format where possible._


_**Once options have been chosen, you will be asked to specify the input directory containing the image files to be analysed**_

---
### Output Image files
The script will output an overlay showing tissue boundary detection (if selected) as well as the fluorescent signal that was quantified. If selected, it will also output a secon version of the fluorescent signal identified with a pretty LUT applied. This is especially useful for visual representations such as figures. All output images are in `.png`

(_The original image always remains unchanged_)

---
### Output text files

The analysis will output two text files in the top level directory:  

1. `Parameters.txt` - Contains a list of all the parameters used in the analysis, along with a copyof the log with a list of successfully analysed image files.  

2. `PR-T_Results.txt` - A copy of the analysed data, including:
     Original image name
     Total detected tissue area (if enabled)
     Total fluorescent signal area
     % of fluorescent signal as a % of detected tissue area, or if diabled, of the total image size
     Mean intensity of the analysed fluorescent area
     Median intensity of the analysed fluorescent area

---
