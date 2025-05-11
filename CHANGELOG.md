# Changelog

All notable changes to the interactive_pdf_viewer package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of the interactive PDF viewer package
- Support for loading PDFs from various sources (URL, file system, assets, bytes)
- Basic PDF viewing functionality with page navigation
- Text selection capability with sentence-level granularity
- Multi-selection mode (toggle with double tap)
- Visual feedback for selected text blocks
- Page navigation controls
- Support for custom selection color
- Disabled zooming on double-tap gestures to prevent conflicts with multi-selection mode

### Known Issues
- Text highlighting currently covers the entire line rather than individual text
- Text position information is approximated and may not be perfectly accurate
- Native text selection features are not available on iOS devices

### Future Improvements
- Implement precise text highlighting instead of line-based highlighting
- Add support for native text selection on iOS devices
- Improve text position accuracy
- Add support for text search functionality
- Implement text copying to clipboard
- Add support for annotations and comments 