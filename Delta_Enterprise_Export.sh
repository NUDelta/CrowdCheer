#!/bin/bash
# original source from http://www.thecave.com/2014/09/16/using-xcodebuild-to-export-a-ipa-from-an-archive/

xcodebuild clean -project CrowdCheer -configuration Release -alltargets
xcodebuild -workspace CrowdCheer.xcworkspace clean archive -scheme CrowdCheer -archivePath CrowdCheer.xcarchive
xcodebuild -exportArchive -archivePath CrowdCheer.xcarchive -exportPath CrowdCheer2 -exportFormat ipa -exportProvisioningProfile "Delta Lab C"
mv -i CrowdCheer2.ipa  CrowdCheer.ipa

# xcodebuild 
# 	-scheme CrowdFound 
# 	-workspace CrowdFound.xcworkspace clean archive 
# 	-archivePath build/CrowdFound
# xcodebuild -exportArchive 
# 	-exportFormat ipa 
# 	-archivePath "build/CrowdFound.xcarchive" 
# 	-exportPath "build/CrowdFound.ipa" 
# 	-exportProvisioningProfile "Delta Lab"
