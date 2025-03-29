# PT Champion Grading System

This document outlines the scoring system used within the PT Champion application to convert raw exercise performance (repetitions or time) into a standardized score from 0 to 100 points.

The system uses linear interpolation between defined benchmark performance levels for 0, 50, and 100 points.

## Scoring Benchmarks

| Exercise     | 0 Points    | 50 Points      | 100 Points       | Unit        |
|--------------|-------------|----------------|------------------|-------------|
| Push-ups     | 0 reps      | 35 reps        | 71 reps          | Repetitions |
| Sit-ups      | 0 reps      | 47 reps        | 78 reps          | Repetitions |
| Pull-ups     | 0 reps      | 8 reps         | 20 reps          | Repetitions |
| 2-Mile Run   | >= 20:12    | 16:36 (996s)   | <= 13:00 (780s)  | Time (mm:ss)|

## Grading Formulas (Linear Interpolation)

Scores are calculated based on the benchmarks above and capped between 0 and 100 points.

### Push-ups (`Reps`)

- **If `Reps` = 0:** `Points = 0`
- **If 0 < `Reps` <= 35:** `Points = Reps * (50 / 35)` ≈ `Reps * 1.4286`
- **If 35 < `Reps` < 71:** `Points = 50 + (Reps - 35) * (50 / (71 - 35))` ≈ `50 + (Reps - 35) * 1.3889`
- **If `Reps` >= 71:** `Points = 100`

### Sit-ups (`Reps`)

- **If `Reps` = 0:** `Points = 0`
- **If 0 < `Reps` <= 47:** `Points = Reps * (50 / 47)` ≈ `Reps * 1.0638`
- **If 47 < `Reps` < 78:** `Points = 50 + (Reps - 47) * (50 / (78 - 47))` ≈ `50 + (Reps - 47) * 1.6129`
- **If `Reps` >= 78:** `Points = 100`

### Pull-ups (`Reps`)

- **If `Reps` = 0:** `Points = 0`
- **If 0 < `Reps` <= 8:** `Points = Reps * (50 / 8)` = `Reps * 6.25`
- **If 8 < `Reps` < 20:** `Points = 50 + (Reps - 8) * (50 / (20 - 8))` ≈ `50 + (Reps - 8) * 4.1667`
- **If `Reps` >= 20:** `Points = 100`

### 2-Mile Run (`Time` in seconds)

First, convert the run time from `mm:ss` format to total seconds.

- **Benchmark Times:**
    - `Time_100` = 13:00 = 780 seconds
    - `Time_50` = 16:36 = 996 seconds
    - `Time_0` = 20:12 = 1212 seconds (derived linearly)

- **Formulas:**
    - **If `Time` <= 780:** `Points = 100`
    - **If 780 < `Time` < 1212:** `Points = (Time_0 - Time) * (100 / (Time_0 - Time_100))`
        - `Points = (1212 - Time) * (100 / (1212 - 780))`
        - `Points = (1212 - Time) * (100 / 432)` ≈ `(1212 - Time) * 0.2315`
        - *Note: This single formula covers both the 0-50 and 50-100 point ranges due to the linear nature.*
    - **If `Time` >= 1212:** `Points = 0`

---

*Note: These formulas represent a linear scaling model. Depending on requirements or observed results, adjustments (e.g., non-linear scaling) might be considered in the future.* 