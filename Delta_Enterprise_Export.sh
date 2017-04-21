#!/bin/bash
# original source from http://www.thecave.com/2014/09/16/using-xcodebuild-to-export-a-ipa-from-an-archive/

# xcodebuild clean -project CrowdCheer -configuration Release -alltargets
# xcodebuild -project CrowdCheer.xcodeproj clean archive -scheme CrowdCheer -archivePath CrowdCheer.xcarchive
# xcodebuild -exportArchive -archivePath CrowdCheer.xcarchive -exportPath CrowdCheer2 -exportOptionsPlist CrowdCheer.plist PROVISIONING_PROFILE_SPECIFIER="Delta Lab C"
# mv -i CrowdCheer2.ipa  CrowdCheer.ipa

# xcodebuild clean -project CrowdCheer -configuration Release -alltargets
# xcodebuild -project CrowdCheer.xcodeproj clean archive -scheme CrowdCheer -archivePath CrowdCheer.xcarchive
# xcodebuild -exportArchive -archivePath CrowdCheer.xcarchive -exportPath CrowdCheer2 -exportFormat ipa -exportProvisioningProfile "Delta Lab C"
# mv -i CrowdCheer2.ipa  CrowdCheer.ipa

xcodebuild clean -project CrowdCheer -configuration Release -alltargets
xcodebuild -project CrowdCheer.xcodeproj clean archive -scheme CrowdCheer -archivePath CrowdCheer.xcarchive
xcodebuild -exportArchive -archivePath CrowdCheer.xcarchive -exportPath CrowdCheer2 -exportOptionsPlist CrowdCheer.plist PROVISIONING_PROFILE_SPECIFIER="Delta Lab C"
mv -i CrowdCheer2.ipa  CrowdCheer.ipa
