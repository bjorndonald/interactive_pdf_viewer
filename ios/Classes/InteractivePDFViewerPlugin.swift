import Flutter
import UIKit
import PDFKit

public class InteractivePDFViewerPlugin: NSObject, FlutterPlugin {
  var currentPage: PDFPage?
  var currentSentenceIndex: Int = 0
  var selectedSentence: String = ""
  var selectedSentences: [String] = []
  var currentSentences: [String] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "interactive_pdf_viewer", binaryMessenger: registrar.messenger())
    let instance = InteractivePDFViewerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openPDF":
      guard let args = call.arguments as? [String: Any],
            let filePath = args["filePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", 
          message: "Missing or invalid filePath argument", 
          details: nil))
        return
      }
      
      openPDF(filePath: filePath, result: result)
    case "getSentences":
      result(selectedSentences)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func openPDF(filePath: String, result: @escaping FlutterResult) {
    // Create URL from file path
    let fileURL = URL(fileURLWithPath: filePath)
    
    // Verify file exists
    guard FileManager.default.fileExists(atPath: filePath) else {
      result(FlutterError(code: "FILE_NOT_FOUND", 
        message: "The PDF file was not found at path: \(filePath)", 
        details: nil))
      return
    }
    
    // Check if PDFKit is available (iOS 11+)
    if #available(iOS 11.0, *) {
      // Verify file is a PDF
      guard let document = PDFDocument(url: fileURL) else {
        result(FlutterError(code: "INVALID_PDF", 
          message: "The file at \(filePath) is not a valid PDF", 
          details: nil))
        return
      }
      
      // Get the root view controller
      DispatchQueue.main.async {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          result(FlutterError(code: "NO_VIEWCONTROLLER", 
                             message: "Could not get root view controller", 
                             details: nil))
          return
        }
        
        // Create a PDF view
        let pdfView = PDFView(frame: UIScreen.main.bounds)
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.addGestureRecognizer(self.tapGesture)
          pdfView.addGestureRecognizer(self.doubleTapGesture)
        
        // Create a view controller to present the PDF
        let pdfViewController = UIViewController()
        pdfViewController.view = pdfView
        pdfViewController.modalPresentationStyle = .fullScreen
        
        // Add a close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.backgroundColor = UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.layer.cornerRadius = 5
        closeButton.addTarget(self, action: #selector(self.dismissPDFView(_:)), for: .touchUpInside)
        
        // Store reference to view controller for dismissal
        objc_setAssociatedObject(closeButton, 
                                UnsafeRawPointer(bitPattern: 1)!, 
                                pdfViewController, 
                                .OBJC_ASSOCIATION_RETAIN)
        
        // Position close button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        pdfView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
          closeButton.topAnchor.constraint(equalTo: pdfView.safeAreaLayoutGuide.topAnchor, constant: 20),
          closeButton.trailingAnchor.constraint(equalTo: pdfView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
          closeButton.widthAnchor.constraint(equalToConstant: 80),
          closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Present the PDF view controller
        rootViewController.present(pdfViewController, animated: true, completion: nil)
        
        result(true)
      }
    } else {
      // PDFKit is not available on this iOS version
      result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                         message: "PDFKit is only available on iOS 11 and above", 
                         details: nil))
    }
  }

    lazy var tapGesture: UITapGestureRecognizer = {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.numberOfTapsRequired = 1
            return tap
        }()
    
    lazy var doubleTapGesture: UITapGestureRecognizer = {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            tap.numberOfTapsRequired = 2
            return tap
        }()
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let page = currentPage else { return }
        
        let annotations = page.annotations
        for annotation in annotations {
            page.removeAnnotation(annotation)
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
      guard let pdfView = gesture.view as? PDFView else { return }
      let location = gesture.location(in: pdfView)
      if let page = pdfView.page(for: location, nearest: true) {
        currentPage = page
        if let selectedSentence = selectSentence(at: location, on: page, in: pdfView) {
          self.selectedSentence = selectedSentence
            self.selectedSentences.append(selectedSentence)
        } else {
          print("No sentence selected")
        }
      } else {
        print("No page found at tap location")
      }
    }

    func selectSentence(at location: CGPoint, on page: PDFPage, in pdfView: PDFView) -> String? {
      let pdfPoint = pdfView.convert(location, to: page)
                                
      guard let pageContent = page.string else {
        print("Could not get page content")
        return nil
      }
      // Improved word selection
      guard let tappedWord = getWordAt(point: pdfPoint, on: page, in: pageContent) else {
        print("No word found at tap location")
        return nil
      }

      print("Tapped word: \(tappedWord)")

      // Split content into sentences
      let sentences = pageContent.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .map { $0 + "." }
        currentSentences = sentences
        if let index = sentences.firstIndex(where: { $0.contains(tappedWord) }) {
            let selectedSentence = sentences[index]
            print("Found sentence: \(selectedSentence)")
            self.currentSentenceIndex = index
            
            highlightSentence(selectedSentence)
            return selectedSentence + "."
        }
        print("No sentence found containing the word: \(tappedWord)")
        return tappedWord

    }

    func highlightSentence(_ selectedSentence: String) {
      guard let page = currentPage else { return }
      let annotations = page.annotations
      
      if let selections = page.document?.findString(selectedSentence){
        print("Number of selections: \(selections.count)")
                
        if(selections.count > 0){
          let lines = selections[0].selectionsByLine()
          for line in lines {
            let highlight = PDFAnnotation(bounds: line.bounds(for: page), forType: .highlight, withProperties: nil)
            highlight.endLineStyle = .circle
            highlight.color = UIColor.blue.withAlphaComponent(0.5)
            page.addAnnotation(highlight)
          }          
        }    
      }
    }

    func getWordAt(point: CGPoint, on page: PDFPage, in pageContent: String) -> String? {
      let wordRange = 20
      print("Word range: \(point)")
      
      // Get character index and validate it
      let rawCharacterIndex = page.characterIndex(at: point)
      guard rawCharacterIndex >= 0 && rawCharacterIndex < pageContent.count else {
          print("Invalid character index: \(rawCharacterIndex)")
          return nil
      }
      
      let characterIndex = Int64(rawCharacterIndex)
      print("Character index: \(characterIndex)")
      
      // Safely calculate start and end indices with bounds checking
      let startIndex: Int
      if characterIndex > Int64(wordRange) {
          startIndex = Int(characterIndex - Int64(wordRange))
      } else {
          startIndex = 0
      }
      
      let endIndex: Int
      let maxSafeIndex = Int64(pageContent.count)
      if characterIndex + Int64(wordRange) < maxSafeIndex {
          endIndex = Int(characterIndex + Int64(wordRange))
      } else {
          endIndex = pageContent.count
      }
      print("Start index: \(pageContent.count)")
      let start = pageContent.index(pageContent.startIndex, offsetBy: startIndex)
      let end = pageContent.index(pageContent.startIndex, offsetBy: endIndex)
      let searchString = String(pageContent[start..<end])

      let words = searchString.components(separatedBy: .whitespacesAndNewlines)
      let tappedWordIndex = words.firstIndex { word in
        if let wordRange = searchString.range(of: word) {
          let wordStart = searchString.distance(from: searchString.startIndex, to: wordRange.lowerBound)
          let wordEnd = wordStart + word.count
          return (characterIndex - Int64(startIndex) >= Int64(wordStart) && characterIndex - Int64(startIndex) < Int64(wordEnd))
        }
        return false
      }
                        
      return tappedWordIndex.map { words[$0] }
    }
  
  
  @objc private func dismissPDFView(_ sender: UIButton) {
    if let viewController = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: 1)!) as? UIViewController {
      viewController.dismiss(animated: true, completion: nil)
    }
  }
}
