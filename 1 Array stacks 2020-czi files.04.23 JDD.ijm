requires("1.47j"); // 1.47j required for File.copy command


//These first questions establish the variables that will be used in the
//to name the stacks at the end of the macro




// Asks for case/stack specific label information
Dialog.create("Case number: ")
Dialog.addString("Case number:", "AM274-drop-block10", 40);
Dialog.show();
casenumber=Dialog.getString();

Dialog.create("What stack is this?")
Dialog.addString("Stack number:", "4", 40);
Dialog.show();
stacknumber=Dialog.getString();

Dialog.create("How many sections/slices are in this stack?")
Dialog.addNumber("Number of sections:", 18, 0,25, "");
Dialog.show();
startNum=Dialog.getNumber();

Dialog.create("How many channels?");
Dialog.addNumber("n", 4, 0, 25, "channels");
Dialog.show();
NumChannels=Dialog.getNumber();

n=1;
channelname = newArray();
while (n<NumChannels+1)	{
	Dialog.create("What would you like to name channel "+n+"?")
	Dialog.addString("Channel "+n+":", "", 50);
	Dialog.show();
	channel = Dialog.getString();
	channelname = Array.concat(channelname, channel);
	n++;
}

// Asks where your files are
dir = getDirectory('Choose the folder that contains your stack files');

// Create sub-folders in directory
File.makeDirectory(dir+"orig")
File.makeDirectory(dir+"working")

// This code will copy files from your selected directory to the "orig" sub-folder
list = getFileList(dir);

for (i=0; i<list.length; i++) { 
    if (endsWith(toLowerCase(list[i]),".zvi")) {
    	OrigSourceFile = dir+list[i];
    	OrigDestFile = dir+"orig"+File.separator+list[i];
    	File.rename(OrigSourceFile,OrigDestFile); // move original files to "orig" sub-folder 
    } else if  (endsWith(toLowerCase(list[i]),".zva")) {
    	OrigSourceFile = dir+list[i];
    	OrigDestFile = dir+"orig"+File.separator+list[i];
    	File.rename(OrigSourceFile,OrigDestFile); // move original zva file to "orig" sub-folder 
    }
}

// This code will make a copy of files from "orig" to "working" sub-folder and rename them
list = getFileList(dir+"orig"+File.separator);
n=1;
for (i=0; i<list.length; i++) {
	if (endsWith(toLowerCase(list[i]),".zvi")) {
		OrigDestFile = dir+"orig"+File.separator+list[i];
		WorkingDestFile = dir+"working"+File.separator+n+".zvi";
		if (!File.exists(WorkingDestFile)) {
			File.copy(OrigDestFile,WorkingDestFile);  // Removed "done = " from before File.copy command
		} else {
			print("warning: "+WorkingDestFile+" already exists (stack has probably already copied and renamed)");
		}
		n++;	
	}
}

// This section of the script separates all the channels from images,
// performs contrast normalization, downsamples images to 8-bit,
// and saves them into new channel-specific stacks

savedir = dir+"working"+File.separator;

// Separate channels, subract backroung, normalize,
// downsample, save as channel slice
for (n=1; n<startNum+1; n++) {
	filename = dir+"working"+File.separator+n+".zvi";
   	run("Bio-Formats", "open=[filename] color_mode=Grayscale split_channels view=Hyperstack stack_order=XYCZT");
	for (k=1; k<(NumChannels+1); k++) {
		selectImage(1);
		rename(channelname[k-1]+n);
		run("Subtract Background...", "rolling=50"); // Background subtraction
		run("Enhance Contrast", "saturated=0.35 normalize"); // Contrast normalization
		run("8-bit"); // Downsample to 8-bit
		save(savedir+channelname[k-1]+n+".tif");
		run("Close");
	}
}

// Open all slices for speicifc channel and save out channel stack
for (k=1; k<(NumChannels+1); k++) {
			

	for (l=1; l<startNum+1; l++) {
		open(savedir+channelname[k-1]+l+".tif");
	}
	run("Images to Stack", "name=Stack title=[] keep");
	saveAs("tiff", savedir+casenumber+"-stack"+stacknumber+"-"+channelname[k-1]);
	run("Close All");
}

run("Close All");

print("Finished.");