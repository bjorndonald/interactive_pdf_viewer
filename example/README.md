# Interactive PDF Viewer Example

This example demonstrates how to use the `interactive_pdf_viewer` package in a Flutter application.

## Features Demonstrated

- Loading PDFs from different sources:
  - Local file system (using file picker)
  - Assets
  - Remote URL
- Text selection and sentence tapping
- Error handling
- Page navigation
- Custom styling

## Running the Example

1. Make sure you have Flutter installed and set up
2. Navigate to the example directory:
   ```bash
   cd example
   ```
3. Get the dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Usage

The example app provides three ways to load a PDF:

1. **Pick PDF**: Opens a file picker to select a PDF from your device
2. **Sample PDF**: Loads a sample PDF included in the assets
3. **Remote PDF**: Loads a PDF from a remote URL

Once a PDF is loaded, you can:
- Tap on text to select sentences
- Swipe to navigate between pages
- See the total number of pages
- View any errors that occur during loading

## Screenshots

(Screenshots will be added after the app is running)

## Notes

- The sample PDF is a simple one-page document
- The remote PDF is a dummy PDF from W3C
- Error handling is implemented for all operations
- The app uses Material 3 design 