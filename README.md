# Ballz1

## Workflow

git checkout master

git fetch --all

git checkout -b new-feature

git push -u origin new-feature

## Changing Video Framerate

ffmpeg -i MOVIENAME.mov -r 30 NEWMOVIENAME.mov

## Upload an App to App Store Connect

https://help.apple.com/xcode/mac/current/#/dev442d7f2ca

1. In Xcode, click Product -> Archive ensuring that the build target is "Generic iOS Device"  
2. Xcode will pop up a new window and click Distribute App -> iOS -> Upload -> Next -> Automatically manage signing -> Upload  
3. Go to appstoreconnect.apple.com, log in, and go to My Apps and click on the appropriate app  
4. Click "+ Version or Platform" and give the app a new version  
5. Fill in the necessary text boxes, upload images, etc  
6. In the build section, your new archived app should appear eventually after uploading it in the previous steps  

## Recording App Preview on Device

`QuickTime -> File -> New Movie Recording -> Select device as video and microphone output`  

At this point, you the QuickTime recording window should show your device screen. Start recording and then play the game/use the app. Stop recording when you're done.  

Now at this point, you'll need to need to change the frame rate of the app using this command:  

`ffmpeg -i MOVIENAME.mov -r 30 NEWMOVIENAME.mov`  

## Recording App Preview on Simulator

To record an app preview on the simulator, run the following command:  

`xcrun simctl io booted recordVideo <filename>.mov`  

This recording will most likely need a sound channel added to it before being accepted as a valid app preview. I'll update this with that process next time I need to do that.

## Tagging a Release

git tag -a "vX.X.X" -m "Tag message"  
git push --follow-tags  

## Fixing CocoaPods Bug With Unit Tests

Follow these steps to resolve unit test modules not being able to find packages. This example is specific to Firebase but could probably be applied to any other 3rd party libraries:  

1. Click on the top-level app item in your Xcode file explorer (in my case it was Ballz1)  
2. Go to Build Settings and click on your MyAppTests target  
3. Search for Header Search Paths under Search Paths subsection  
4. Add the following:  
    * $(inherited) non-recursive  
    * $(SRCROOT)/Pods/Headers/Public recursive  
    * $(SRCROOT)/Pods/Firebase recursive  
5. Try re-running tests and it should be good to go!  
