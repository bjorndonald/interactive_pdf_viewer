# Changelog

## 0.2.6 - 2024-03-22
* Enhanced UI behavior:
  * Automatic minimization when using quote, share, or info buttons
  * Improved user experience with seamless transitions
  * Better screen space management
  * Consistent minimization behavior across all actions

## 0.2.5 - 2024-03-22
* Added minimizable PDF viewer functionality:
  * Floating minimized view with rounded corners
  * Progress bar showing reading progress
  * Title and page number display
  * Expand and close buttons
  * Customizable position and appearance
* Enhanced quote management:
  * New `removeQuote` method for removing specific quotes
  * Improved quote highlighting and unhighlighting
  * Better quote text matching
* Updated UI elements:
  * Changed back button to close icon
  * Updated minimize/maximize icons to carets
  * Improved button positioning and layout
  * Enhanced visual feedback

## 0.2.3 - 2024-03-21
* Fixed Swift compiler error related to CGRect bounds calculation
* Removed quote-management from package topics to better reflect current features
* Documentation updates and clarifications

## 0.2.2 - Unreleased
* Removed Linux platform support to fix build issues
* Clarified iOS-only implementation in documentation
* Added customizable text highlighting options:
  * Enable/disable highlighting of quoted text
  * Custom highlight color support using hex values
  * New `openPDFWithOptions` method for highlighting configuration
* Replaced "Mark as Done" feature with "Clear All Quotes":
  * New clear button to remove all quotes from the document
  * Added `onClearAllQuotes` callback for handling quote clearing
  * Updated UI with new trash icon for clear functionality
* Added support for opening PDFs at specific pages:
  * New `initialPage` parameter for all PDF opening methods
  * Ability to resume reading from last viewed page
  * Smooth page transitions when opening at specific pages
* Added support for pre-existing quotes:
  * New `PDFQuote` class for structured quote data
  * Ability to pre-highlight existing quotes when opening PDFs
  * Support for quote location information
  * Available in all PDF opening methods
* Enhanced quote management:
  * Individual quote removal by tapping on highlights
  * Dynamic UI updates (Clear button changes to Remove)
  * New `onQuoteRemoved` callback for tracking removals
  * Improved highlight interaction and feedback

## 0.2.1
* Initial release with iOS support
* Interactive PDF viewing capabilities using PDFKit
* Text selection and extraction features
* Page tracking and navigation
* Support for loading PDFs from various sources

## [0.2.0] - 2024-03-20

### Added
- Page tracking functionality:
  - Real-time page change events
  - Current page tracking
  - Total pages information
  - Smooth page transitions
- Programmatic viewer control:
  - Static `closePDF()` method for programmatic closing
  - Error handling for viewer operations
  - State management improvements
- Documentation updates:
  - Added examples for page tracking
  - Added examples for programmatic control
  - Updated API documentation

### Changed
- Made `closePDF()` method static for consistency
- Improved error handling in method channel calls
- Enhanced example application with page tracking UI

## [0.1.0] - 2024-03-19

### Added
- Initial release of Interactive PDF Viewer plugin
- Support for iOS 13.0+ using PDFKit and SF Symbols
- Basic PDF viewing capabilities:
  - Open PDFs from local storage
  - Open PDFs from URLs with progress tracking
  - Open PDFs from Flutter assets
- Interactive features:
  - Single tap to select sentences
  - Double tap to clear selections
  - Visual highlighting of selected text
  - Save button for selected sentences
- UI Components:
  - Custom close button (top left)
  - Save button for selected sentences (top right)
  - Full-screen PDF viewer
- Method channel communication:
  - `onSelectedSentencesChanged` callback for sentence selection
  - `onSaveSelectedSentences` callback for save actions
- Platform support:
  - iOS 13.0+ support
  - PDFKit integration
  - SF Symbols for UI elements

### Known Limitations
- iOS-only support
- Requires iOS 13.0+ for PDFKit and SF Symbols
- Text highlighting covers entire lines
- Text position information is approximated
- Native text selection features not available

### Future Improvements
- Implement precise text highlighting instead of line-based highlighting
- Add support for native text selection on iOS devices
- Improve text position accuracy
- Add support for text search functionality
- Implement text copying to clipboard
- Add support for annotations and comments

## [0.2.8] - 2024-03-19

### Added
- Automatic closing of existing PDF viewer when opening a new PDF
- Improved resource management and cleanup

### Fixed
- Potential memory leaks from multiple PDF viewers
- UI conflicts when opening multiple PDFs

## [0.2.7] - Previous version
// ... existing code ... 