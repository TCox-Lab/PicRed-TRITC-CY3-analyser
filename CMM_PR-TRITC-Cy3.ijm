//Set script version number
	ver = "1.08"
	
// Start timer at beginning of script
startTime = getTime();

// Date and Time stamp for the output files
	MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	TimeString = "";
	if (dayOfMonth<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+dayOfMonth+" "+MonthNames[month]+" "+year+" ";
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute;

// Set file system 
	fs = File.separator;

// Tidy up before starting 
	run("Close All");
	run("Collect Garbage");
	print("\\Clear");
	if (isOpen("Output")) {
	    close("Output");
	}

// Set some base script parameters
	FiTy=".tif"; // set file type - can be done manually here, but will still prompt
	TotA = 0; // Total Tissue Area Detection module
	TriA = 0; // Fluorescence Signal Detection module
	TVA = 0; // Pretty Output (does not affect analysis)
	MemMon = 0; // set to 1 to run memory monitor, but will still prompt
	BaMod = 0; // Set to 1 for batch mode , but will still prompt
	TotalArea = "Module not enabled";
	TRITCArea = "Module not enabled";
	textureVariance = "Module not enabled";
	TRITCPer = "Module not enabled";
	TRITCmean = 0;
	TRITCmed = 0;
	BrTh = 21; // Base parameter for brightness thresholding
	BGThr = 40; // Base parameter for bakground removal

// Launch a dialog box to collect inputs
	Dialog.create("CMM PR-T Analyser Settings");
	Dialog.addString("Specify File Type", FiTy);
	Dialog.addNumber("Tissue Detection Threshold", BrTh);
	Dialog.addNumber("Backgrounding Threshold", BGThr);
	Dialog.addCheckbox("Run Total Tissue Area Detection", true); // Currently enabled to run by default
	Dialog.addCheckbox("Run PR-T Signal Extraction", true); // Currently enabled to run by default
	Dialog.addCheckbox("Pretty Output", true);
	Dialog.addCheckbox("Launch Memory Monitor [Debugging]", false); // Currently disbled by default
	Dialog.addCheckbox("Batch Mode On [Faster]", true); // Enabled by default, disable to visualise the steps it goes through
	Dialog.show();
	FiTy = Dialog.getString();
	BrTh = Dialog.getNumber();
	BGThr = Dialog.getNumber();
	TotA = Dialog.getCheckbox();
	TriA = Dialog.getCheckbox();
	TVA = Dialog.getCheckbox();
	Mem = Dialog.getCheckbox();
	BaMod = Dialog.getCheckbox();
	if (TotA==true) TotA = 1;
	if (TriA==true) TriA = 1;
	if (TVA==true) TVA = 1;
	if (Mem==true) MemMon = 1;
	if (BaMod==true) BaMod = 1;

// If enabled, launch the memory monitor (udeful for large batches)
	if (MemMon==1){
		doCommand("Monitor Memory...");
		}

// Prompt user to select the target directory
	dir = getDirectory("Choose a Directory ");

// Setup output windows
	requires("1.38m");
	title1="Output";
	run("Text Window...", "name="+title1);
	print("[Output]","=== PR-T Analyser === v"+ver+" - Run Date: "+TimeString+"\n");
	print("[Output]","=== CMM Lab (www.matrixandmetastasis.com) ==="+"\n \n");
	print("[Output]", "Image"+"\t"+"Total Area"+"\t"+"Total PR-T Area"+"\t"+"% PR-T Area"+"\t"+"PR-T Mean"+"\t"+"PR-T Median"+"\n");

// Batch Process Folders - 
	requires("1.33s"); 

// Set batch mode to speed up processing
	setBatchMode(false);
	if (BaMod==1){
		setBatchMode(true);
		}

// Identify number of images in the target directory
	fileList = getFileList(dir);
	extension = FiTy;  
	countimages = 0;
	ImCt = 1;
	for (i = 0; i < fileList.length; i++) {
    	filename = fileList[i];
    	if (endsWith(filename, extension)) {
        	countimages++;
  		}
	}
// Identify and iterate through the specific images in the target directory
	count = 0;
	countFiles(dir);
	n = 0;
	processFiles(dir);
	function countFiles(dir) {
		list = getFileList(dir);
		for (i=0; i<list.length; i++) {
			if (endsWith(list[i], "/"))
			countFiles(""+dir+list[i]);
			else
			count++;
		}
	}
	function processFiles(dir) {
		list = getFileList(dir);
		for (i=0; i<list.length; i++) {
			if (endsWith(list[i], "/"))
			processFiles(""+dir+list[i]);
			else {
				showProgress(n++, count);
				path = dir+list[i];
				processFile(path);
			}
		}
	}
	
	function processFile(path) {
		if (endsWith(path, FiTy)) {
			open(path);

// Begin script
			run("Clear Results"); 
			roiManager("reset");
			name=getTitle();
			fname=File.nameWithoutExtension; 
			String.copy(name);
			print("File "+ImCt+" of "+countimages+" - "+name);
			ImCt=ImCt++;
			dir=getDirectory("image");
			selectWindow(name);
			run("Select None");
			print("Analysis running on "+fname+" ...");
			
// Total Tissue Detection Module
			if(TotA==1){
// Start Analysing Total Tissue Area
				run("Duplicate...", "title="+fname+"_TotArea");
				run("8-bit");
				run("Gaussian Blur...", "sigma=1");
				setThreshold(BrTh, 255, "raw"); // Threshold needs to be low enough to capture whole tissue at this point
				setOption("BlackBackground", true);
				run("Convert to Mask");
// Invert image so tissue (white) becomes foreground (black)
				run("Invert");
// Remove small noise particles
				run("Analyze Particles...", "size=100-Infinity show=Masks");
// Dilate will expand the tissue (black pixels)
				run("Options...", "iterations=5 count=1 black do=Dilate");
// Smooth the boundary
				run("Options...", "iterations=1 count=1 black do=Close");
// Fill all holes to create single continuous outline
				run("Fill Holes");
// Erode back to fit tissue size
				run("Options...", "iterations=4 count=1 black do=Erode");
// Remove any extraneous pixels from the main mask
				run("Remove Outliers...", "radius=10 threshold=1 which=Bright");
				run("Options...", "iterations=1 count=1 black do=Erode");
				run("Remove Outliers...", "radius=75 threshold=1 which=Bright");
// Create final selection and measure
				run("Create Selection");
				if (selectionType() != -1) {
					run("Set Measurements...", "area mean median display redirect=None decimal=0");
					run("Measure");
					TotalArea = getResult("Area", nResults-1);   
// Visualise oultine on original
					selectWindow(name);
					run("Duplicate...", "title="+fname+"_outline");
					run("RGB Color");
					run("Restore Selection");
					run("Draw", "slice");
// Downsample the image to half original size
					width = getWidth();
					height = getHeight();
					new_wid = (width/2);
					new_hei = (width/2);
					run("Size...", "width=new_wid height=new_hei constrain average interpolation=Bilinear");
// Set the ROI line colour and width, burn in and save
					run("Line Width...", "line=10");
					setForegroundColor(255, 0, 0);    // Red
					run("Flatten");
					saveAs("PNG", dir+fname+"_Outline.png");
					close();
					if(isOpen(fname+"_TotArea")) {
						selectWindow(fname+"_TotArea");
						close();
					}
				} else {
				    print("Could not create tissue envelope. Try adjusting parameters.");
				}
			
// Clean up
				if(isOpen("Mask of "+fname+"_TotArea")) {
					selectWindow("Mask of "+fname+"_TotArea");
					close();
					}
				if(isOpen(fname+"_outline")) {
					selectWindow(fname+"_outline");
					close();
					}
			}

// Now to run signal threshold detection for the fluorescence signal if enabled
			if (TriA || TVA){
				selectWindow(name);
				run("Duplicate...", "title="+fname+"_PR-T");
				run("8-bit");
			
// Remove very dim pixels below a threshold
				run("Duplicate...", "title=PR-T-BG-temp");
				setThreshold(0, BGThr);  // Remove pixels within values shown
				run("Convert to Mask");
				run("Invert");
				imageCalculator("AND", fname+"_PR-T", "PR-T-BG-temp");
				selectWindow("PR-T-BG-temp");
				close();
				selectWindow(fname+"_PR-T");		
				setOption("BlackBackground", true);
				run("Convert to Mask");
// Capture Area for measurement	
				run("Create Selection");
				roiManager("Add");
				run("Measure");
				if(TriA==1){
					TRITCArea = getResult("Area", nResults-1);
					TRITCArea = floor(TRITCArea);
				}
				
// Create a mask of the captured area using the original image
				imageCalculator("AND create", fname+"_PR-T", name);
				selectWindow("Result of "+fname+"_PR-T");
				roiManager("Select", roiManager("count")-1);
				run("Measure");
				TRITCmean = getResult("Mean", nResults-1);
				TRITCmean = floor(TRITCmean);
				TRITCmed = getResult("Median", nResults-1);
				TRITCmed = floor(TRITCmed);
				
// Downsample the image to half original size, save and close
				width = getWidth();
				height = getHeight();
				new_wid = (width/2);
				new_hei = (width/2);
				run("Size...", "width=new_wid height=new_hei constrain average interpolation=Bilinear");
				if(TriA==1){
					saveAs("PNG", dir+fname+"_PR-T.png");
				}
// For a LUT applied "pretty image"
				
					if (TVA==1){
						run("Enhance Contrast", "saturated=0.35");
						run("Fire");
						saveAs("PNG", dir+fname+"_PR-T-PO.png");
						close();
					} else {
						close();
					}
				}
// Tidy up			
					
				if(isOpen(name)) {
					selectWindow(name);
					close();
					}
				if(isOpen(fname+"_PR-T")) {
					selectWindow(fname+"_PR-T");
					close();
					}
		
// Output results
			
			if(TVA==1){
				TRITCPer=((100/TotalArea)*TRITCArea);
				TRITCPer = d2s(TRITCPer,2);
			}
			ImPer = (100/countimages) * ImCt;
			ImPer = floor(ImPer);
			print(fname+" Total Area = "+TotalArea);
			print(fname+" PR-T Area = "+TRITCArea);
			print(fname+" % PR-T Signal = "+TRITCPer);
			print(fname+" Mean Intensity = "+TRITCmean);
			print(fname+" Median Intensity = "+TRITCmed);
			print("[Output]",name+"\t"+TotalArea+"\t"+TRITCArea+"\t"+TRITCPer+"\t"+TRITCmean+"\t"+TRITCmed+"\n");
	
			print("Analysis finished - run is ~"+ImPer+"% complete \n");
		}
	}

// Output Parameters used to a parameters file
title="Parameters";
run("Text Window...", "name="+title);
print("[Parameters]","CMM PR-T Analyser v"+ver+" - Run Date: "+TimeString+"\n");
print("[Parameters]","CMM Lab website (www.matrixandmetastasis.com)"+"\n");
print("[Parameters]","CMM Lab GitHub (www.github.com/tcox-lab)"+"\n\n");
print("[Parameters]","File Type Used = "+FiTy+"\n\n");
print("[Parameters]","Brightness Threshold (for Tissue Detection) = "+BrTh+"\n\n");
print("[Parameters]","Backgrounding Threshold = "+BGThr+"\n\n");
print("[Parameters]","Copy of Log"+"\n\n");
print("[Parameters]", getInfo("log"));
selectWindow("Parameters");
saveAs("Text",dir+"Parameters.txt");
run("Close");

// Final tidy up
	selectWindow("Output");
	saveAs("Text",dir+"PR-T_Results.txt");
	run("Close");
	selectWindow("Results");
	run("Close");

// Calculate and display elapsed time at end
	endTime = getTime();
	elapsedTime = (endTime - startTime) / 1000;
	elapsedTime = elapsedTime/60;
	elapsedTime = d2s(elapsedTime,2);
	print("Analysis completed in: ~" + elapsedTime + " minutes");

