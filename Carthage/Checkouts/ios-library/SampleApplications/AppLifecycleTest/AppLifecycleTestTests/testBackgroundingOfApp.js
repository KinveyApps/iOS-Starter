
var target = UIATarget.localTarget();


var blobImage = target.frontMostApp().mainWindow().buttons()["blobImageView"];

target.frontMostApp().mainWindow().buttons()["downloadblob"].tap();


target.deactivateAppForDuration(10);

if (blobImage.isVisible()) {
	UIALogger.logFail("download callback happened in bg");
} else {
	UIALogger.logPass("download callback did not happen in bg");
}

target.delay(15); //wait for callback to complete

if (blobImage.isVisible()) {
	UIALogger.logPass("download continued after restore");
} else {
	UIALogger.logFail("download did not continue after restore");
}