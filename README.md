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

## Tagging a Release

git tag -a "vX.X.X" -m "Tag message"  
git push --follow-tags  
