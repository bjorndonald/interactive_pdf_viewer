import Flutter
import UIKit
import PDFKit

public class InteractivePDFViewerPlugin: NSObject, FlutterPlugin, PDFViewDelegate {
  var currentPage: PDFPage?
  var currentSentenceIndex: Int = 0
  var selectedSentence: String = ""
  var currentSentences: [String] = []
  private var actionsChannel: FlutterMethodChannel?
  private var bottomToolbar: UIToolbar?
  private var backButton: UIButton?
  private weak var pdfView: PDFView?
  private var highlightOnTap: Bool = false
  private var currentPageNumber: Int = 1

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "interactive_pdf_viewer", binaryMessenger: registrar.messenger())
    let instance = InteractivePDFViewerPlugin()
    instance.actionsChannel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openPDF":
      guard let args = call.arguments as? [String: Any],
            let filePath = args["filePath"] as? String,
            let title = args["title"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", 
          message: "Missing or invalid arguments", 
          details: nil))
        return
      }
      
      // Get optional highlight parameter
      self.highlightOnTap = args["highlightOnTap"] as? Bool ?? false
      
      openPDF(filePath: filePath, title: title, result: result)
    case "closePDF":
      closePDFViewer(result: result)
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
    
    // Set the correct selector based on the button type
    switch title {
    case "Quote":
        button.addTarget(self, action: #selector(handleQuoteButtonTap(_:)), for: .touchUpInside)
    case "Done":
        button.addTarget(self, action: #selector(handleMarkAsDoneButtonTap(_:)), for: .touchUpInside)
    case "Info":
        button.addTarget(self, action: #selector(handleInfoButtonTap(_:)), for: .touchUpInside)
    case "Share":
        button.addTarget(self, action: #selector(handleShareButtonTap(_:)), for: .touchUpInside)
    default:
        break
    }
    
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

  private func openPDF(filePath: String, title: String, result: @escaping FlutterResult) {
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
        titleLabel.text = title
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
        pdfView.maxScaleFactor = 4.0  // Maximum zoom level
        pdfView.minScaleFactor = 0.5  // Minimum zoom level
        pdfView.usePageViewController(true)
        pdfView.backgroundColor = .systemBackground
        pdfView.pageShadowsEnabled = false
        pdfView.delegate = self 
         // Set the delegate

         // Register for page change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        // Send initial page number
        if let firstPage = document.page(at: 0) {
            self.currentPage = firstPage
            self.currentPageNumber = 1
            // self.notifyPageChange(1)
        }
        
        // Add zoom gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        pdfView.addGestureRecognizer(pinchGesture)
        
        // Only add tap gesture if highlighting is enabled
        if self.highlightOnTap {
            pdfView.addGestureRecognizer(self.tapGesture)
        }
        
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
        let markAsDoneButton = self.createCircularButton(title: "Done", symbol: "checkmark")
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

  @objc private func pageChanged(_ notification: Notification) {
        guard let pdfView = notification.object as? PDFView,
              let currentPage = pdfView.currentPage else { return }
        
        let pageIndex = pdfView.document?.index(for: currentPage) ?? 0
        print("Page changed to: \(pageIndex + 1)")
        
        // Handle page change logic here
        notifyPageChange(pageIndex + 1)
    }

  @objc private func dismissPDFView() {
    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
  }
  
  @objc private func handleQuoteButtonTap(_ sender: UIButton) {
    // Implementation for quote functionality
   
    if !highlightOnTap {
      if let selectedText = getSelectedText() {
        handleSentenceSelectedButtonTap(selectedText)
      }
    }
    else if !self.selectedSentence.isEmpty {
      handleSentenceSelectedButtonTap(self.selectedSentence)
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
    guard let pdfView = self.pdfView,
          let currentPage = pdfView.currentPage else {
        return
    }
    let pageNumber = pdfView.document?.index(for: currentPage) ?? 0
    let arguments: [String: Any] = ["pageNumber": pageNumber + 1]

    self.actionsChannel?.invokeMethod("markChapterAsDone", arguments: arguments)
  }
  
  @objc private func handleInfoButtonTap(_ sender: UIButton) {
    self.actionsChannel?.invokeMethod("infoButton", arguments: nil)
  }
  
  @objc private func handleShareButtonTap(_ sender: UIButton) {
    guard let pdfView = self.pdfView,
          let currentPage = pdfView.currentPage else {
        return
    }
    let pageNumber = pdfView.document?.index(for: currentPage) ?? 0
    let arguments: [String: Any] = ["pageNumber": pageNumber + 1]
    // Implementation for sharing
    self.actionsChannel?.invokeMethod("shareButton", arguments: arguments)
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
        guard let pdfView = gesture.view as? PDFView else { return }
        
        // Reset zoom on double tap
        UIView.animate(withDuration: 0.3) {
            pdfView.scaleFactor = 1.0
        }
        
        // Clear highlights if any
        if let page = currentPage {
            let annotations = page.annotations
            for annotation in annotations {
                page.removeAnnotation(annotation)
            }
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard self.highlightOnTap,
              let pdfView = gesture.view as? PDFView else { return }
              
        let location = gesture.location(in: pdfView)
        if let page = pdfView.page(for: location, nearest: true) {
            currentPage = page
            if let selectedSentence = selectSentence(at: location, on: page, in: pdfView) {
               
                self.selectedSentence = selectedSentence
                highlightSentence(selectedSentence)
            } else {
               
            }
        } else {
           
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let pdfView = gesture.view as? PDFView else { return }
        
        if gesture.state == .began {
            gesture.scale = pdfView.scaleFactor
        } else if gesture.state == .changed {
            let scale = gesture.scale
            pdfView.scaleFactor = min(max(scale, pdfView.minScaleFactor), pdfView.maxScaleFactor)
        }
    }

    func selectSentence(at location: CGPoint, on page: PDFPage, in pdfView: PDFView) -> String? {
      let pdfPoint = pdfView.convert(location, to: page)
                                
      guard let pageContent = page.string else {
        
        return nil
      }
      // Improved word selection
      guard let tappedWord = getWordAt(point: pdfPoint, on: page, in: pageContent) else {
        return nil
      }

      // Split content into sentences
      let sentences = pageContent.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .map { $0 + "." }
        currentSentences = sentences
        if let index = sentences.firstIndex(where: { $0.contains(tappedWord) }) {
            let selectedSentence = sentences[index]
            self.currentSentenceIndex = index
            
            highlightSentence(selectedSentence)
            self.selectedSentence = selectedSentence
            return selectedSentence + "."
        }
       return tappedWord

    }

    func highlightSentence(_ selectedSentence: String) {
      guard let page = currentPage else { return }
      let annotations = page.annotations

      for annotation in annotations {
        page.removeAnnotation(annotation)
      }
      
      if let selections = page.document?.findString(selectedSentence){
                
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
      
      // Get character index and validate it
      let rawCharacterIndex = page.characterIndex(at: point)
      guard rawCharacterIndex >= 0 && rawCharacterIndex < pageContent.count else {
          return nil
      }
      
      let characterIndex = Int64(rawCharacterIndex)
      
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
    guard let pdfView = self.pdfView,
          let currentPage = pdfView.currentPage else {
        return
    }
    
    // Get the current page number
    let pageNumber = currentPage.pageRef?.pageNumber ?? 0
    
    // Create a dictionary with all the information
    let arguments: [String: Any] = [
        "text": sentence,
        "pageNumber": pageNumber,
        "location": [
            "x": currentPage.bounds(for: .mediaBox).midX,
            "y": currentPage.bounds(for: .mediaBox).midY
        ]
    ]

    self.actionsChannel?.invokeMethod("quote", arguments: arguments)
  }

  // Add these new methods for PDFViewDelegate
  public func pdfViewPageChanged(_ pdfView: PDFView) {
    print("pdfViewPageChanged: \(pdfView.currentPage?.pageRef?.pageNumber ?? 0)")
    self.currentPage = pdfView.currentPage
    handlePageChange(pdfView)
  }
  
  public func pdfView(_ pdfView: PDFView, didGoToPage page: PDFPage) {
    print("didGoToPage: \(page.pageRef?.pageNumber ?? 0)")
    self.currentPage = page
    handlePageChange(pdfView)
  }
  
  private func handlePageChange(_ pdfView: PDFView) {
    print("handlePageChange")
    guard let currentPage = pdfView.currentPage,
          let document = pdfView.document else { return }
    print("handlePageChange: \(currentPage.pageRef?.pageNumber ?? 0)")
    let pageNumber = document.index(for: currentPage) + 1
    if pageNumber != currentPageNumber {
        currentPageNumber = pageNumber
        notifyPageChange(pageNumber)
    }
  }
  
  private func notifyPageChange(_ pageNumber: Int) {
    let arguments: [String: Any] = [
        "pageNumber": pageNumber,
        "totalPages": pdfView?.document?.pageCount ?? 0
    ]
    self.actionsChannel?.invokeMethod("onPageChanged", arguments: arguments)
  }

  private func closePDFViewer(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      if let rootViewController = UIApplication.shared.windows.first?.rootViewController,
         rootViewController.presentedViewController != nil {
        rootViewController.dismiss(animated: true) {
          result(true)
        }
      } else {
        result(FlutterError(code: "NO_PDF_VIEWER",
                           message: "No PDF viewer is currently open",
                           details: nil))
      }
    }
  }

}
