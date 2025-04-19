/**
 * This file contains configuration for Chromatic visual testing integration
 * Run with: npx chromatic --project-token=<your-project-token>
 * 
 * Documentation: https://www.chromatic.com/docs/
 */

module.exports = {
  // Your Chromatic project token (set via environment variable in CI)
  projectToken: process.env.CHROMATIC_PROJECT_TOKEN,
  
  // Optional: Specify which stories to include/exclude
  // storybookBuildDir: 'storybook-static',
  
  // Optional: Override the maximum allowed drift percentage
  // if pixel-diff is larger than threshold the test will fail
  diffThreshold: 0.2, // 0.2%
  
  // Skip certain stories based on parameters
  // e.g. if a story has a parameter like parameters: { chromatic: { disable: true } }
  skip: (story) => {
    return story.parameters?.chromatic?.disable === true;
  },
  
  // Delay capture while animations complete
  delay: 200, // ms
  
  // Different viewports for responsive testing
  viewports: [
    320,   // Mobile
    768,   // Tablet
    1024,  // Desktop
    1440   // Large Desktop
  ],
  
  // Configure how Chromatic handles the repository
  // Helps during CI integration
  gitRetries: 3,
}; 