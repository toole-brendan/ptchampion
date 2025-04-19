// ***********************************************************
// This support file is processed and loaded automatically before your test files.
// This is a great place to put global configuration and behavior that modifies Cypress.
// ***********************************************************

import { mount } from 'cypress/react'
import './commands'

// Augment the Cypress namespace to include type definitions for
// your custom command.
// Alternatively, can be defined in cypress/support/component.d.ts
// with a <reference path="./component" /> at the top of your spec.
declare global {
  namespace Cypress {
    interface Chainable {
      mount: typeof mount
    }
  }
}

Cypress.Commands.add('mount', mount)

// Example: Import your React component testing utilities
// import { ThemeProvider } from 'your-app/context/theme'
// import { AuthProvider } from 'your-app/context/auth'

// Cypress.Commands.add('mount', (component, options = {}) => {
//   const { ...mountOptions } = options
//
//   const wrapped = <ThemeProvider><AuthProvider>{component}</AuthProvider></ThemeProvider>
//
//   return mount(wrapped, mountOptions)
// }) 