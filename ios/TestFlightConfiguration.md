# PT Champion TestFlight Configuration Guide

This document outlines the configuration and setup process for TestFlight external testing of the PT Champion iOS app.

## Prerequisites

1. An active Apple Developer account with App Store Connect access
2. Xcode 15+ installed on your development machine
3. PT Champion iOS app code properly configured and building without errors

## External Testing Setup Process

### 1. Create App in App Store Connect

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to "Apps" > "+" > "New App"
3. Fill in the required information:
   - Platform: iOS
   - App Name: PT Champion
   - Primary Language: English (U.S.)
   - Bundle ID: com.ptchampion.app (must match your project)
   - SKU: PTCHAMPION2023
   - User Access: Full Access

### 2. Configure App Information

Before starting TestFlight testing, you need to configure minimal App Store information:

1. Navigate to your app in App Store Connect
2. Go to the "App Store" tab
3. Fill in required fields:
   - App Information (Privacy Policy URL, Category, etc.)
   - Pricing and Availability 
   - App Review Information (contact info, demo account)

### 3. Prepare App for TestFlight

#### Configure Build Settings

1. Open the PT Champion project in Xcode
2. Select the project in the Navigator
3. Go to the "Signing & Capabilities" tab
4. Ensure "Automatically manage signing" is enabled
5. Select your Team
6. Verify the Bundle Identifier matches App Store Connect entry
7. Set Version and Build numbers correctly:
   - Version: 1.0.0 (semantic versioning)
   - Build: incremental number (e.g., 1)

#### Add Export Compliance Information

1. In Xcode, select the Info.plist file
2. Add the following keys:
   ```
   ITSAppUsesNonExemptEncryption: NO
   ```

### 4. Create and Upload a Build

1. In Xcode, select the PT Champion target
2. Set the device to "Any iOS Device (arm64)"
3. Select Product > Archive
4. When the archive is complete, click "Distribute App"
5. Select "App Store Connect" and then "Upload"
6. Follow the prompts to upload the build
7. Wait for the build to finish processing in App Store Connect

### 5. TestFlight Configuration

1. In App Store Connect, go to your app's "TestFlight" tab
2. Once your build is processed, configure test information:
   - App Description: Brief overview of the app
   - Feedback Email: beta@ptchampion.com
   - What to Test: Specific focus areas for testers
   - Test Group: Configure test notes for features to test
   - Beta App Review Information: Contact details for App Review

### 6. Create Testing Groups

#### Internal Testing Group
1. Click "Add Group" to create an internal testing group
2. Add team members with Apple Developer accounts
3. Internal testers can access builds immediately without App Review

#### External Testing Group
1. Click "Add Group" to create an external testing group (e.g., "PT Champion Evaluators")
2. Configure group settings:
   - Group Name: "PT Champion Evaluators"
   - Public Link: Enable/Disable as needed
   - Group Description: Instructions for testers

### 7. Add External Testers

There are two ways to add external testers:

#### Option 1: Email Invitations
1. Go to your external test group
2. Click "Add Testers" > "Add New Testers"
3. Enter email addresses (up to 10,000 testers allowed)
4. Click "Next" and select the build to test
5. Click "Send Invitations" to notify testers

#### Option 2: Public Link
1. In your external test group, enable "Public Link"
2. Copy the generated URL
3. Share this URL with potential testers
4. Testers can join without direct invitations

### 8. Manage External Testing

#### Monitor Tester Feedback
1. Go to the "TestFlight" tab
2. Select your build
3. Click "Feedback" to view tester comments and crash reports

#### Update Builds
1. Create and upload new builds as needed
2. Testers will be automatically notified of new builds
3. Enable automatic installation if desired

## Special Considerations

### Privacy Manifests
1. Ensure your app includes the `PrivacyInfo.xcprivacy` file
2. Verify all privacy declarations are accurate
3. Update privacy manifests with each build as needed

### Expiration Dates
- TestFlight builds expire after 90 days
- Plan to update builds before expiration
- Monitor expiration dates in App Store Connect

### App Review for External Testing
- First build for external testing requires App Review
- Review typically takes 1-2 business days
- Address any rejections promptly

## Post-TestFlight Workflow

1. Gather and analyze feedback from testers
2. Fix identified issues and upload new builds
3. When ready for release, submit for App Store Review
4. Create a production release and set a release date

## Troubleshooting

### Common Issues
- **Build Processing Failed**: Check for provisioning profile and code signing issues
- **TestFlight Invitation Not Received**: Verify email addresses and check spam folders
- **App Review Rejection**: Address feedback and resubmit
- **Testers Can't Install**: Check iOS version compatibility and expiration dates

For more details, refer to Apple's [TestFlight documentation](https://developer.apple.com/testflight/).

---

*Last Updated: [CURRENT_DATE]* 