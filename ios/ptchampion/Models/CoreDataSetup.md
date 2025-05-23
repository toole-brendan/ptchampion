# Core Data Setup for Calibration Storage

## Overview
This document explains how to set up Core Data to store calibration data for the PTChampion app.

## Steps to Setup Core Data Model

### 1. Create Core Data Model File
1. In Xcode, go to File → New → File
2. Select "Data Model" under Core Data
3. Name it `PTChampionDataModel.xcdatamodeld`
4. Place it in the `Models` folder

### 2. Create CalibrationEntity
In the data model editor:

1. Add a new Entity named `CalibrationEntity`
2. Set the Codegen to "Manual/None"
3. Add the following attributes:

#### Basic Attributes
- `id` (UUID, Optional: No)
- `timestamp` (Date, Optional: No) 
- `exercise` (String, Optional: No)

#### Device Position Attributes
- `deviceHeight` (Float, Optional: No, Default: 1.0)
- `deviceAngle` (Float, Optional: No, Default: 0.0)
- `deviceDistance` (Float, Optional: No, Default: 1.5)
- `deviceStability` (Float, Optional: No, Default: 0.5)

#### User Measurement Attributes
- `userHeight` (Float, Optional: No, Default: 1.7)
- `armSpan` (Float, Optional: No, Default: 1.7)
- `torsoLength` (Float, Optional: No, Default: 0.6)
- `legLength` (Float, Optional: No, Default: 0.9)

#### Quality Metrics
- `calibrationScore` (Float, Optional: No, Default: 0.0)
- `confidenceLevel` (Float, Optional: No, Default: 0.0)
- `frameCount` (Integer 32, Optional: No, Default: 0)

#### Complex Data (JSON)
- `angleAdjustmentsData` (Binary Data, Optional: Yes)
- `visibilityThresholdsData` (Binary Data, Optional: Yes)
- `poseNormalizationData` (Binary Data, Optional: Yes)
- `validationRangesData` (Binary Data, Optional: Yes)
- `rawData` (Binary Data, Optional: Yes)

#### Metadata
- `deviceModel` (String, Optional: Yes)
- `appVersion` (String, Optional: Yes)
- `createdAt` (Date, Optional: Yes)
- `updatedAt` (Date, Optional: Yes)
- `isArchived` (Boolean, Optional: No, Default: NO)
- `notes` (String, Optional: Yes)

### 3. Update App Delegate or SceneDelegate
Add Core Data stack initialization:

```swift
import CoreData

// Add this to your App delegate or main app file
lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "PTChampionDataModel")
    container.loadPersistentStores { _, error in
        if let error = error as NSError? {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
    return container
}()

func saveContext() {
    let context = persistentContainer.viewContext
    
    if context.hasChanges {
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
```

### 4. Inject Repository in Views
Update your view models to use the repository:

```swift
// In your WorkoutSessionViewModel or wherever CalibrationManager is used
let repository = CalibrationRepository(container: persistentContainer)
let calibrationManager = CalibrationManager(
    poseDetectorService: poseDetectorService,
    calibrationRepository: repository
)
```

### 5. Migration from UserDefaults
The repository automatically handles migration from UserDefaults on first run. Existing calibrations will be moved to Core Data.

## Benefits of Core Data Storage

1. **Persistent Storage**: Data survives app uninstalls and updates
2. **Query Capabilities**: Efficient searching and filtering
3. **Multiple Calibrations**: Store history of calibrations per exercise
4. **Statistics**: Track calibration quality over time
5. **Backup/Sync**: Can be extended to support CloudKit syncing

## Usage Examples

```swift
// Get best calibration for pushups
let bestCalibration = await repository.getBestCalibration(for: .pushup)

// Get all usable calibrations
let usableCalibrations = await repository.getUsableCalibrations(for: .pushup)

// Delete old calibrations (older than 30 days)
try await repository.deleteOldCalibrations(olderThan: 30)

// Get statistics
let stats = await repository.getCalibrationStatistics()
```

## Testing
The system gracefully falls back to UserDefaults if Core Data is not available, ensuring backward compatibility during development. 