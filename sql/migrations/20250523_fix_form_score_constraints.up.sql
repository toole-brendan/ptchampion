-- Fix form_score column: Add default value and constraints
-- This migration ensures form_score is properly handled in the workouts table

-- Step 1: Update any existing NULL form_score values to 0
UPDATE workouts 
SET form_score = 0 
WHERE form_score IS NULL;

-- Step 2: Add default value for form_score column
ALTER TABLE workouts 
ALTER COLUMN form_score SET DEFAULT 0;

-- Step 3: Add constraint to ensure form_score is within valid range
ALTER TABLE workouts 
ADD CONSTRAINT form_score_range CHECK (form_score >= 0 AND form_score <= 100);

-- Step 4: Update the shared schema to reflect that form_score should not be nullable
-- Note: This is handled in the schema.ts file separately

-- Step 5: Verify the changes
DO $$
DECLARE
    null_form_scores INTEGER;
    out_of_range_scores INTEGER;
BEGIN
    -- Check for any remaining NULL values
    SELECT COUNT(*) INTO null_form_scores 
    FROM workouts 
    WHERE form_score IS NULL;
    
    -- Check for any out-of-range values
    SELECT COUNT(*) INTO out_of_range_scores 
    FROM workouts 
    WHERE form_score < 0 OR form_score > 100;
    
    IF null_form_scores > 0 THEN
        RAISE WARNING 'Found % rows with NULL form_score values', null_form_scores;
    END IF;
    
    IF out_of_range_scores > 0 THEN
        RAISE WARNING 'Found % rows with out-of-range form_score values', out_of_range_scores;
    END IF;
    
    RAISE NOTICE 'form_score constraints applied successfully';
    RAISE NOTICE 'Default value: 0';
    RAISE NOTICE 'Valid range: 0-100';
    
END $$; 