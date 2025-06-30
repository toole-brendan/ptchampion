-- Reverse form_score constraints: Remove default value and constraint
-- WARNING: This will remove data validation for form_score

-- Step 1: Drop the form_score range constraint
ALTER TABLE workouts 
DROP CONSTRAINT IF EXISTS form_score_range;

-- Step 2: Remove the default value for form_score
ALTER TABLE workouts 
ALTER COLUMN form_score DROP DEFAULT;

-- Step 3: Log the changes
DO $$
BEGIN
    RAISE NOTICE 'form_score constraints removed successfully';
    RAISE NOTICE '- Removed range constraint (0-100)';
    RAISE NOTICE '- Removed default value';
    RAISE NOTICE 'WARNING: form_score values are no longer validated';
END $$; 