# Changelog

All notable changes to the Interactive PDF Viewer plugin will be documented in this file.

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