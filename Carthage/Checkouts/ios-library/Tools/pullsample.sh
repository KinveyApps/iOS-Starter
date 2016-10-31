#!/bin/sh

#if [ $# -lt 1 ]
#then
#	echo "Usage: ./pullsample.sh gitloc"
#	exit
#fi 


## clean samples dir
if	[ -d samples ]
then
 rm -rf samples
fi


mkdir samples
cd samples
##


#gitloc="$1"
sample="TestDrive-iOS"
gitloc="git@github.com:KinveyApps/${sample}.git"

#clone the project
if [ ! -d $sample ]
then
    echo "clone fresh ${sample}"
    cloneCMD="git clone ${gitloc}"
    $cloneCMD
    cd $sample
else
    echo "${sample} already created, updating"
    cd $sample
    git pull
fi

#replace KinveyKit with latest
# -- need to have done release-kinvey first
if [ ! -d Kinvey ]
then
  echo "no kinvey kit"
  exit 1
fi
rm -rf Kinvey

mkdir Kinvey
kkreleaseDir=../../out/KinveyKit-OUT
cp -r $kkreleaseDir/KinveyKit.framework Kinvey/
cp -r $kkreleaseDir/LICENSES Kinvey/


xcodebuild clean
xcodebuild -sdk iphonesimulator6.1  GCC_TREAT_WARNINGS_AS_ERRORS=YES

# check status
STATUS=$?
echo "Build Status: $STATUS"
if [ $STATUS -ne 0 ]
then
echo "exit, error"
exit 1
fi


