# PT Champion TestFlight Deployment Guide

This guide provides detailed steps for deploying the PT Champion iOS app to Apple's TestFlight for beta testing.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [App Store Connect Setup](#app-store-connect-setup)
3. [Xcode Project Configuration](#xcode-project-configuration)
4. [Building Your App for TestFlight](#building-your-app-for-testflight)
5. [Uploading to TestFlight](#uploading-to-testflight)
6. [Managing Beta Testers](#managing-beta-testers)
7. [Distributing to Beta Testers](#distributing-to-beta-testers)
8. [Updating Your TestFlight App](#updating-your-testflight-app)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

Before deploying to TestFlight, ensure you have:

- An **Apple Developer Program** membership ($99/year)
- **Xcode** (latest version) installed on a Mac
- Complete **Swift app** (PTChampion-Swift folder)
- **Backend API** deployed to a production server (not localhost)
- Apple ID with two-factor authentication enabled
- iTunes Connect/App Store Connect access

## App Store Connect Setup

1. **Sign into App Store Connect**:
   - Go to [App Store Connect](https://appstoreconnect.apple.com/)
   - Sign in with your Apple Developer account

2. **Create a New App**:
   - Go to "My Apps"
   - Click the "+" button and select "New App"
   - Fill in the required information:
     - Platforms: iOS
     - Name: PT Champion (this will be the public app name)
     - Primary language: English (or your preferred language)
     - Bundle ID: Select from the dropdown (must match your Xcode project)
     - SKU: A unique identifier for your app (e.g., "ptchampion2025")
     - User Access: Full Access
   - Click "Create"

3. **Configure App Information**:
   - In the App Information tab, complete required fields:
     - Privacy Policy URL
     - App Store Information
     - Version Information (for your first build)

## Xcode Project Configuration

1. **Update Production API URL**:
   - Open the `PTChampion-Swift` project in Xcode
   - Navigate to the API client file
   - Update the base URL to point to your production backend:
   ```swift
   private let baseURL = "https://your-production-api.com/api"
   ```

2. **Configure App Signing**:
   - Open your project settings
   - Select the target and go to "Signing & Capabilities"
   - Ensure "Automatically manage signing" is checked
   - Select your Team (from your Apple Developer account)
   - Verify the Bundle Identifier matches what you created in App Store Connect

3. **Configure App Version and Build Number**:
   - In your target's "General" tab:
     - Set Version to your semantic version (e.g., "1.0.0")
     - Set Build to your build number (start with "1")
   - These will need to be incremented for each new TestFlight submission

4. **App Icons and Launch Screen**:
   - Ensure your app has proper app icons in the Assets catalog
   - Configure your Launch Screen storyboard

## Building Your App for TestFlight

1. **Select Destination**:
   - Choose "Any iOS Device (arm64)" from the device selector in Xcode

2. **Archive Your App**:
   - Go to Product > Archive
   - Wait for the archive process to complete

3. **Validate App**:
   - When the Archives window appears, select your latest archive
   - Click "Validate App"
   - Follow the prompts, including:
     - Select your distribution method (App Store)
     - Select your Apple Developer account
     - Verify the provisioning profile and signing certificate
   - Review and resolve any validation issues

## Uploading to TestFlight

1. **Upload Your Build**:
   - After successful validation, click "Distribute App"
   - Select "App Store Connect"
   - Select "Upload" (not "Export")
   - Follow the prompts to complete the upload
   - Wait for the upload to complete

2. **Processing Time**:
   - After uploading, Apple will process your build
   - This can take from a few minutes to several hours
   - You'll receive an email when processing is complete

3. **TestFlight Review**:
   - All TestFlight builds go through a review process
   - This is shorter than App Store reviews (usually 1-2 days)
   - You'll be notified when your build is approved for testing

## Managing Beta Testers

1. **Internal Testers**:
   - Go to your app in App Store Connect
   - Navigate to TestFlight tab
   - Under "Internal Testing", you can add up to 25 internal testers
   - Internal testers must be part of your App Store Connect team
   - Internal builds don't require a Beta App Review

2. **External Testers**:
   - Under "External Testing", click "Add External Testers"
   - You can:
     - Create a public link
     - Add individual testers by email
     - Create testing groups
   - External testers can include up to 10,000 users
   - External builds require Beta App Review from Apple

3. **Create Testing Groups** (optional):
   - Under "External Testing", click "+"
   - Create groups based on testing phases, features, or user segments
   - Assign specific builds to specific groups

## Distributing to Beta Testers

1. **Set Build for Testing**:
   - Go to your app in App Store Connect > TestFlight
   - Select the build you want to test
   - Click "TestFlight" tab then "Test Information"
   - Fill in the test information:
     - What to test
     - Known issues
     - Other feedback instructions
   - Save changes

2. **Distributing to Internal Testers**:
   - Select "Internal Testing"
   - Toggle on the builds you want to test
   - Testers will receive an email invitation

3. **Distributing to External Testers**:
   - Once your build passes Beta App Review:
   - Select your group of external testers
   - Click "Start Testing"
   - Testers will receive an email invitation

4. **Using Public Link** (for external testers):
   - Go to External Testing > Public Link
   - Enable the public link
   - Configure the number of testers allowed
   - Copy and share the link with your testers

## Updating Your TestFlight App

1. **Prepare New Build**:
   - Make necessary changes to your app
   - Increment the build number in Xcode
   - Archive and upload the new build following the steps above

2. **Testing Multiple Builds**:
   - You can have multiple builds available for testing
   - Specify which builds are available to which testing groups
   - Mark older builds as "inactive" when they're no longer needed

3. **Beta App Review**:
   - Major changes will require another Beta App Review
   - Minor updates may not need additional review
   - Plan for 1-2 days for review

## Troubleshooting

### Common Upload Issues

1. **Provisioning Profile Issues**:
   - Error: "No matching provisioning profiles found"
   - Solution: Ensure your Apple Developer account is active, and the correct team is selected in Xcode

2. **Certificate Issues**:
   - Error: "Missing iOS Distribution certificate"
   - Solution: In Xcode, go to Preferences > Accounts > Manage Certificates and create a new iOS Distribution certificate

3. **Bitcode and dSYM Issues**:
   - Error related to Bitcode or dSYM files
   - Solution: In your build settings, ensure the "Enable Bitcode" option is set appropriately (typically "Yes" for TestFlight)

### TestFlight Specific Issues

1. **Build Rejected in Beta Review**:
   - Review the feedback from Apple
   - Fix the issues mentioned
   - Submit a new build with an incremented build number

2. **Tester Can't Install App**:
   - Ensure they've installed the TestFlight app from the App Store
   - Verify they've accepted the testing invitation
   - Check if they're using a supported iOS version

3. **App Crashes on Launch in TestFlight**:
   - Review crash logs in App Store Connect
   - Consider enabling more comprehensive logging for TestFlight builds
   - Check for environment-specific issues (e.g., API endpoints)

## Additional Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Xcode Help](https://help.apple.com/xcode/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

Remember that TestFlight builds expire after 90 days. Be prepared to upload new builds regularly if your testing phase extends beyond this period.