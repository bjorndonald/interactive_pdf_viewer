import Flutter
import UIKit
import PDFKit

public class InteractivePDFViewerPlugin: NSObject, FlutterPlugin {
  var currentPage: PDFPage?
  var currentSentenceIndex: Int = 0
  var selectedSentence: String = ""
  var currentSentences: [String] = []
  private var actionsChannel: FlutterMethodChannel?
  private var bottomToolbar: UIToolbar?
  private var backButton: UIButton?
  private weak var pdfView: PDFView?

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
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func createCircularButton(title: String, symbol: String) -> UIView {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 100))
    
    // Create circular background
    let circleView = UIView(frame: CGRect(x: 15, y: 0, width: 50, height: 50))
    circleView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) // Light gray background
    circleView.layer.cornerRadius = 25
    containerView.addSubview(circleView)
    
    // Add button
    let button = UIButton(frame: circleView.bounds)
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
    let image = UIImage(systemName: symbol, withConfiguration: config)
    button.setImage(image, for: .normal)
    button.tintColor = .black
    button.addTarget(self, action: Selector(("handle" + title.replacingOccurrences(of: " ", with: "") + "ButtonTap:")), for: .touchUpInside)
    circleView.addSubview(button)
    
    // Add label
    let label = UILabel(frame: CGRect(x: 0, y: 60, width: 80, height: 20))
    label.text = title
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 14)
    label.textColor = .black
    containerView.addSubview(label)
    
    return containerView
  }

  private func openPDF(filePath: String, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: filePath)
    
    guard FileManager.default.fileExists(atPath: filePath) else {
      result(FlutterError(code: "FILE_NOT_FOUND", 
        message: "The PDF file was not found at path: \(filePath)", 
        details: nil))
      return
    }
    
    if #available(iOS 11.0, *) {
      guard let document = PDFDocument(url: fileURL) else {
        result(FlutterError(code: "INVALID_PDF", 
          message: "The file at \(filePath) is not a valid PDF", 
          details: nil))
        return
      }
      
      DispatchQueue.main.async {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          result(FlutterError(code: "NO_VIEWCONTROLLER", 
                             message: "Could not get root view controller", 
                             details: nil))
          return
        }
        
        // Create container view
        let containerView = UIView(frame: UIScreen.main.bounds)
        containerView.backgroundColor = .systemBackground
        
        // Add back button
        let backButton = UIButton(frame: CGRect(x: 16, y: 44, width: 44, height: 44))
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(self.dismissPDFView), for: .touchUpInside)
        containerView.addSubview(backButton)
        self.backButton = backButton
        
        // Add chapter title label
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 44, width: UIScreen.main.bounds.width, height: 44))
        titleLabel.text = "Chapter 1"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        containerView.addSubview(titleLabel)
        
        // Create PDF view with adjusted frame to account for top and bottom bars
        let pdfView = PDFView(frame: CGRect(x: 0,
                                          y: 88,
                                          width: UIScreen.main.bounds.width,
                                          height: UIScreen.main.bounds.height - 176))
        pdfView.document = document
        pdfView.autoScales = true
       
        pdfView.usePageViewController(true)
       
        pdfView.backgroundColor = .systemBackground
        
        // Configure page layout
       
        pdfView.pageBreakMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        
        pdfView.addGestureRecognizer(self.tapGesture)
        pdfView.addGestureRecognizer(self.doubleTapGesture)
        containerView.addSubview(pdfView)
        self.pdfView = pdfView
        
        // Create bottom container view
        let bottomContainer = UIView(frame: CGRect(x: 0,
                                                 y: UIScreen.main.bounds.height - 120,
                                                 width: UIScreen.main.bounds.width,
                                                 height: 120))
        bottomContainer.backgroundColor = .white
        
        // Create buttons
        let quoteButton = self.createCircularButton(title: "Quote", symbol: "text.quote")
        let markAsDoneButton = self.createCircularButton(title: "Mark as Done", symbol: "checkmark")
        let infoButton = self.createCircularButton(title: "Info", symbol: "info.circle")
        let shareButton = self.createCircularButton(title: "Share", symbol: "square.and.arrow.up")
        
        // Calculate spacing and position buttons
        let buttonWidth: CGFloat = 80
        let totalButtons: CGFloat = 4
        let spacing = (UIScreen.main.bounds.width - (buttonWidth * totalButtons)) / (totalButtons + 1)
        
        let buttons = [quoteButton, markAsDoneButton, infoButton, shareButton]
        for (index, button) in buttons.enumerated() {
          button.frame.origin.x = spacing + (buttonWidth + spacing) * CGFloat(index)
          bottomContainer.addSubview(button)
        }
        
        containerView.addSubview(bottomContainer)
        
        // Create and present view controller
        let pdfViewController = UIViewController()
        pdfViewController.view = containerView
        pdfViewController.modalPresentationStyle = .fullScreen
        
        rootViewController.present(pdfViewController, animated: true, completion: nil)
        
        result(true)
      }
    } else {
      result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                         message: "PDFKit is only available on iOS 11 and above", 
                         details: nil))
    }
  }

  @objc private func dismissPDFView() {
    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
  }
  
  @objc private func handleQuoteButtonTap(_ sender: UIButton) {
    // Implementation for quote functionality
    if let selectedText = getSelectedText() {
      handleSentenceSelectedButtonTap(selectedText)
    }
  }
  
  private func getSelectedText() -> String? {
    guard let pdfView = self.pdfView,
          let selection = pdfView.currentSelection else {
      return nil
    }
    return selection.string
  }
  
  @objc private func handleMarkAsDoneButtonTap(_ sender: UIButton) {
    
  }
  
  @objc private func handleInfoButtonTap(_ sender: UIButton) {
    
  }
  
  @objc private func handleShareButtonTap(_ sender: UIButton) {
    // Implementation for sharing
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
            handleSentenceSelectedButtonTap(selectedSentence)
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
  
  func handleSentenceSelectedButtonTap(_ sentence: String) {
    let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      let methodChannel = FlutterMethodChannel(name: "interactive_pdf_viewer", binaryMessenger: messenger)
      methodChannel.invokeMethod("onSelect", arguments: sentence)
    }
  }

  @objc private func handleSaveSelectedButtonTap(_ sender: UIButton) {
    let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      let methodChannel = FlutterMethodChannel(name: "interactive_pdf_viewer", binaryMessenger: messenger)
      methodChannel.invokeMethod("saveSelected", arguments: "")
    }
  }

  @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
    guard let pdfView = gesture.view as? PDFView,
          let currentPage = pdfView.currentPage else { return }
    
    if gesture.direction == .right {
        // Go to previous page
        if let previousPage = pdfView.document?.page(at: pdfView.currentPage!.pageRef!.pageNumber - 1) {
            pdfView.go(to: previousPage)
        }
    } else if gesture.direction == .left {
        // Go to next page
        if let nextPage = pdfView.document?.page(at: pdfView.currentPage!.pageRef!.pageNumber + 1) {
            pdfView.go(to: nextPage)
        }
    }
  }
}
