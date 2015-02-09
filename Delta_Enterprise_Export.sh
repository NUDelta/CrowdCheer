#!/bin/bash
# original source from http://www.thecave.com/2014/09/16/using-xcodebuild-to-export-a-ipa-from-an-archive/

xcodebuild clean -project CrowdCheer -configuration Release -alltargets
xcodebuild archive -project CrowdCheer.xcodeproj -scheme CrowdCheer -archivePath CrowdCheer.xcarchive
xcodebuild -exportArchive -archivePath CrowdCheer.xcarchive -exportPath CrowdCheer -exportFormat ipa -exportProvisioningProfile "DeltaLab CrowdCheer"
