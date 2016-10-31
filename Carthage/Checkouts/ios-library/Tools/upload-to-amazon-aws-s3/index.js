var AWS = require('aws-sdk');
var s3 = new AWS.S3();
var fs = require('fs');
var path = require('path');
var child_process = require('child_process');

var version = child_process.execFileSync('/usr/libexec/PlistBuddy', [
	'-c', 'Print :CFBundleShortVersionString', path.join(__dirname, '..', '..', 'KinveyKit', 'KinveyKit', 'Info.plist')
], {
	encoding: 'utf-8'
}).trim();

var fileName = 'KinveyKit-' + version + '.zip';
var filePath = path.join(__dirname, '..', '..', 'KinveyKit', 'build', fileName);
var fileBuffer = fs.readFileSync(filePath);

var params = {
	Bucket: 'kinvey-downloads',
	Key: path.join('iOS', fileName),
	ContentType: 'application/zip',
	Body: fileBuffer
};

console.log('Uploading file ' + fileName);
s3.upload(params, function(err, data) {
	if (err) {
		console.error(err);
	} else {
		console.log(data);
	}
});
