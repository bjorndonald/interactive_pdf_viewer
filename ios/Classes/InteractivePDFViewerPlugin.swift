import Flutter
import UIKit
import PDFKit

public class InteractivePDFViewerPlugin: NSObject, FlutterPlugin, PDFViewDelegate {
  private var actionsChannel: FlutterMethodChannel?
  private weak var pdfView: PDFView?
  private var pdfViewController: UIViewController?
  // private var overlayWindow: UIWindow? // Removed: No longer using a separate overlay window
  private var isMinimized: Bool = false
  private var originalFrame: CGRect = .zero
  private var minimizedFrame: CGRect = .zero
  
  // UI Components
  private var headerView: UIView?
  private var minimizeButton: UIButton?
  private var closeButton: UIButton?
  private var contentContainer: UIView?
  private var bottomToolbar: UIView?
  
  // Minimized view components
  private var minimizedContainer: UIView?
  private var minimizedTitleLabel: UILabel?
  private var minimizedProgressView: UIProgressView?
  private var minimizedMinimizeButton: UIButton?
  private var minimizedCloseButton: UIButton?
  
  // PDF Properties
  private var highlightOnTap: Bool = true
  private var highlightColor: UIColor = UIColor.yellow.withAlphaComponent(0.5)
  private var highlightColorString: String = "#FFEB3B"
  private var currentPageNumber: Int = 1
  private var totalPages: Int = 1
  private var pdfTitle: String = ""
  private var selectedSentence: String = ""
  private var currentSentences: [String] = []
  private var shouldHighlightQuotes: Bool = true

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
      
      self.highlightOnTap = args["highlightOnTap"] as? Bool ?? false
      self.highlightColorString = args["highlightColor"] as? String ?? "#FFEB3B"
      let initialPage = args["initialPage"] as? Int ?? 1
      
      openPDF(filePath: filePath, title: title, initialPage: initialPage, result: result)
    
    case "closePDF":
      closePDFViewer(result: result)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func openPDF(filePath: String, title: String, initialPage: Int, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: filePath)
    
    guard FileManager.default.fileExists(atPath: filePath) else {
      result(FlutterError(code: "FILE_NOT_FOUND",
        message: "The PDF file was not found at path: \(filePath)",
        details: nil))
      return
    }
    
    guard let document = PDFDocument(url: fileURL) else {
      result(FlutterError(code: "INVALID_PDF",
        message: "The file at \(filePath) is not a valid PDF",
        details: nil))
      return
    }
    
    // Store PDF info
    self.pdfTitle = title
    self.totalPages = document.pageCount
    self.currentPageNumber = initialPage
    
    // Set highlight color
    self.highlightColor = UIColor(hex: self.highlightColorString)?.withAlphaComponent(0.5) ?? UIColor.yellow.withAlphaComponent(0.5)
    
    DispatchQueue.main.async {
      self.presentFullScreenModal(document: document, title: title, initialPage: initialPage)
      result(true)
    }
  }
  
  
    // MARK: - Modified Functions for Background Interaction

    
    // MARK: - Modified Functions for Background Interaction

    private func presentFullScreenModal(document: PDFDocument, title: String, initialPage: Int) {
        // Get the current top view controller
        guard let topViewController = getTopViewController() else { return }
        
        // Create main container view
        let containerView = UIView(frame: UIScreen.main.bounds)
        containerView.backgroundColor = .systemBackground
        
        // Create view controller first to get proper safe area
        let pdfViewController = UIViewController()
        pdfViewController.view = containerView
        pdfViewController.modalPresentationStyle = .overFullScreen  // Changed from .fullScreen
        pdfViewController.modalTransitionStyle = .coverVertical
        
        self.pdfViewController = pdfViewController
        
        // Present modally first to get proper safe area insets
        topViewController.present(pdfViewController, animated: true) {
            // Setup UI after presentation to get correct safe area
            self.setupUIComponents(containerView: containerView, title: title, document: document, initialPage: initialPage)
            // Initialize the minimized view here, but keep it hidden
            self.setupMinimizedView()
        }
    }
  
  private func setupMinimizedFrame() {
    // Position minimized view in bottom-right corner with some padding
    let screenBounds = UIScreen.main.bounds
    let minimizedWidth: CGFloat = 300
    let minimizedHeight: CGFloat = 80
    let padding: CGFloat = 16
    
    // Account for safe area insets if applicable, though for a floating view,
    // positioning relative to screen bounds with padding is often sufficient.
    self.minimizedFrame = CGRect(
      x: screenBounds.width - minimizedWidth - padding,
      y: screenBounds.height - minimizedHeight - padding - 100, // Account for safe area / bottom bar
      width: minimizedWidth,
      height: minimizedHeight
    )
  }
  
  private func setupUIComponents(containerView: UIView, title: String, document: PDFDocument, initialPage: Int) {
    // Now we have proper safe area insets
    let safeAreaTop = containerView.safeAreaInsets.top
    let topPadding: CGFloat = 40
    let bottomPadding: CGFloat = 20
    let headerContentHeight: CGFloat = 60
    let totalHeaderHeight = topPadding + headerContentHeight + bottomPadding
    let bottomToolbarHeight: CGFloat = 100
    
    // Create header view
    setupHeaderView(containerView: containerView, title: title, safeAreaTop: safeAreaTop, topPadding: topPadding, bottomPadding: bottomPadding, headerContentHeight: headerContentHeight)
    
    // Create content container - positioned below header
    let contentContainer = UIView(frame: CGRect(
      x: 0,
      y: safeAreaTop + totalHeaderHeight,
      width: UIScreen.main.bounds.width,
      height: UIScreen.main.bounds.height - (safeAreaTop + totalHeaderHeight + bottomToolbarHeight)
    ))
    containerView.addSubview(contentContainer)
    self.contentContainer = contentContainer
    
    // Create bottom toolbar
    setupBottomToolbar(containerView: containerView)
    
    // Create PDF view
    setupPDFView(container: contentContainer, document: document, initialPage: initialPage)
    
    // Store frames for minimize/maximize
    self.originalFrame = containerView.frame
  }
  
  private func setupHeaderView(containerView: UIView, title: String, safeAreaTop: CGFloat, topPadding: CGFloat, bottomPadding: CGFloat, headerContentHeight: CGFloat) {
    let totalHeaderHeight = topPadding + headerContentHeight + bottomPadding
    
    // Position header just below the safe area (status bar) with padding
    let headerView = UIView(frame: CGRect(
        x: 0,
        y: safeAreaTop,
        width: UIScreen.main.bounds.width,
        height: totalHeaderHeight
    ))
    headerView.backgroundColor = .systemGray6
    containerView.addSubview(headerView)
    self.headerView = headerView
    
    // Title label - positioned with top padding
    let titleLabel = UILabel(frame: CGRect(
        x: 60,
        y: topPadding + 16,
        width: UIScreen.main.bounds.width - 120,
        height: 28
    ))
    titleLabel.text = title
    titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
    titleLabel.textAlignment = .center
    titleLabel.textColor = .label
    headerView.addSubview(titleLabel)
    
    // Minimize button - positioned with top padding for easy thumb access
    let minimizeButton = UIButton(frame: CGRect(
        x: 16,
        y: topPadding + 16,
        width: 44,
        height: 44
    ))
    minimizeButton.setTitle("−", for: .normal)
    minimizeButton.setTitleColor(.systemBlue, for: .normal)
    minimizeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
    minimizeButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
    minimizeButton.layer.cornerRadius = 22
    minimizeButton.addTarget(self, action: #selector(handleMinimizeButtonTap), for: .touchUpInside)
    headerView.addSubview(minimizeButton)
    self.minimizeButton = minimizeButton
    
    // Close button - positioned with top padding for easy thumb access
    let closeButton = UIButton(frame: CGRect(
        x: UIScreen.main.bounds.width - 60,
        y: topPadding + 16,
        width: 44,
        height: 44
    ))
    closeButton.setTitle("✕", for: .normal)
    closeButton.setTitleColor(.systemRed, for: .normal)
    closeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
    closeButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
    closeButton.layer.cornerRadius = 22
    closeButton.addTarget(self, action: #selector(dismissPDFView), for: .touchUpInside)
    headerView.addSubview(closeButton)
    self.closeButton = closeButton
    
    // Drag indicator - positioned with top padding
    let dragIndicator = UIView(frame: CGRect(
        x: (UIScreen.main.bounds.width - 40) / 2,
        y: topPadding + 8,
        width: 40,
        height: 4
    ))
    dragIndicator.backgroundColor = .systemGray3
    dragIndicator.layer.cornerRadius = 2
    headerView.addSubview(dragIndicator)
    
    // Add pan gesture to header for dragging
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    headerView.addGestureRecognizer(panGesture)
  }
  
  // NEW: Create and add minimized view to the main application's window
  private func setupMinimizedView() {
      guard let appWindow = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewControllerView = appWindow.windows.first?.rootViewController?.view else { return }
      
      // Ensure minimizedFrame is set up before using it
      setupMinimizedFrame()

      // Create minimized container if it doesn't exist
      if minimizedContainer == nil {
          minimizedContainer = UIView(frame: minimizedFrame)
          minimizedContainer?.backgroundColor = .systemBackground
          minimizedContainer?.layer.cornerRadius = 12
          minimizedContainer?.layer.shadowColor = UIColor.black.cgColor
          minimizedContainer?.layer.shadowOffset = CGSize(width: 0, height: 2)
          minimizedContainer?.layer.shadowRadius = 8
          minimizedContainer?.layer.shadowOpacity = 0.3
          minimizedContainer?.layer.borderWidth = 1
          minimizedContainer?.layer.borderColor = UIColor.systemGray4.cgColor
          rootViewControllerView.addSubview(minimizedContainer!) // Add to the main app's root view
          
          // Minimize/Maximize button (left side)
          let minimizedMinimizeButton = UIButton(frame: CGRect(x: 8, y: 8, width: 32, height: 32))
          minimizedMinimizeButton.setTitle("□", for: .normal)
          minimizedMinimizeButton.setTitleColor(.systemBlue, for: .normal)
          minimizedMinimizeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
          minimizedMinimizeButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
          minimizedMinimizeButton.layer.cornerRadius = 16
          minimizedMinimizeButton.addTarget(self, action: #selector(handleMinimizeButtonTap), for: .touchUpInside)
          minimizedContainer?.addSubview(minimizedMinimizeButton)
          self.minimizedMinimizeButton = minimizedMinimizeButton
          
          // Close button (right side)
          let minimizedCloseButton = UIButton(frame: CGRect(x: 260, y: 8, width: 32, height: 32))
          minimizedCloseButton.setTitle("✕", for: .normal)
          minimizedCloseButton.setTitleColor(.systemRed, for: .normal)
          minimizedCloseButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
          minimizedCloseButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
          minimizedCloseButton.layer.cornerRadius = 16
          minimizedCloseButton.addTarget(self, action: #selector(dismissPDFView), for: .touchUpInside)
          minimizedContainer?.addSubview(minimizedCloseButton)
          self.minimizedCloseButton = minimizedCloseButton
          
          // Title label
          let minimizedTitleLabel = UILabel(frame: CGRect(x: 48, y: 12, width: 204, height: 20))
          minimizedTitleLabel.text = pdfTitle
          minimizedTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
          minimizedTitleLabel.textColor = .label
          minimizedTitleLabel.textAlignment = .center
          minimizedContainer?.addSubview(minimizedTitleLabel)
          self.minimizedTitleLabel = minimizedTitleLabel
          
          // Progress view
          let minimizedProgressView = UIProgressView(frame: CGRect(x: 48, y: 48, width: 204, height: 4))
          minimizedProgressView.progressTintColor = .systemBlue
          minimizedProgressView.trackTintColor = .systemGray4
          minimizedProgressView.layer.cornerRadius = 2
          minimizedProgressView.clipsToBounds = true
          minimizedContainer?.addSubview(minimizedProgressView)
          self.minimizedProgressView = minimizedProgressView
          
          // Update progress
          updateProgress()
          
          // Add tap gesture to minimized container for maximizing
          let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMinimizedTap))
          minimizedContainer?.addGestureRecognizer(tapGesture)
          
          // Add pan gesture to minimized container for dragging
          let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMinimizedPan(_:)))
          minimizedContainer?.addGestureRecognizer(panGesture)
      }
      // Initially hide it, it will be shown during minimizeModal
      minimizedContainer?.isHidden = true
  }
    
  private func updateProgress() {
    let progress = Float(currentPageNumber) / Float(totalPages)
    minimizedProgressView?.setProgress(progress, animated: true)
  }
  
  @objc private func handleMinimizedTap() {
    if isMinimized {
      maximizeModal()
    }
  }
  
  // NEW: Separate pan gesture handler for minimized view
  @objc private func handleMinimizedPan(_ gesture: UIPanGestureRecognizer) {
    guard let minimizedContainer = self.minimizedContainer else { return }
    
    let translation = gesture.translation(in: minimizedContainer.superview)
    let velocity = gesture.velocity(in: minimizedContainer.superview)
    
    switch gesture.state {
    case .changed:
      // Allow dragging the minimized view around
      minimizedContainer.center = CGPoint(
        x: minimizedContainer.center.x + translation.x,
        y: minimizedContainer.center.y + translation.y
      )
      gesture.setTranslation(.zero, in: minimizedContainer.superview)
      
    case .ended:
      let screenBounds = UIScreen.main.bounds
      let containerBounds = minimizedContainer.bounds
      
      // Handle swipe to dismiss
      if velocity.x > 800 || velocity.y < -800 {
        dismissPDFView()
        return
      }
      
      // Snap to nearest edge
      let centerX = minimizedContainer.center.x
      let centerY = minimizedContainer.center.y
      
      // Determine which edge to snap to
      let leftDistance = centerX
      let rightDistance = screenBounds.width - centerX
      let snapToLeft = leftDistance < rightDistance
      
      // Calculate snap position
      let padding: CGFloat = 16
      let snapX = snapToLeft ? 
        containerBounds.width / 2 + padding : 
        screenBounds.width - containerBounds.width / 2 - padding
      
      // Keep Y within bounds
      let minY = containerBounds.height / 2 + 50 // Account for status bar
      let maxY = screenBounds.height - containerBounds.width / 2 - 100 // Adjusted for typical bottom bar
      let clampedY = max(minY, min(maxY, centerY))
      
      // Animate to snap position
      UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
        minimizedContainer.center = CGPoint(x: snapX, y: clampedY)
      }
      
    default:
      break
    }
  }
  
  private func setupBottomToolbar(containerView: UIView) {
    let bottomToolbar = UIView(frame: CGRect(
      x: 0,
      y: UIScreen.main.bounds.height - 100,
      width: UIScreen.main.bounds.width,
      height: 100
    ))
    bottomToolbar.backgroundColor = .systemGray6
    containerView.addSubview(bottomToolbar)
    self.bottomToolbar = bottomToolbar
    
    // Create action buttons
    let quoteButton = createCircularButton(title: "Quote", symbol: "text.quote")
    let clearButton = createCircularButton(title: "Clear", symbol: "trash")
    let infoButton = createCircularButton(title: "Info", symbol: "info.circle")
    let shareButton = createCircularButton(title: "Share", symbol: "square.and.arrow.up")
    
    let buttonWidth: CGFloat = 80
    let totalButtons: CGFloat = 4
    let spacing = (UIScreen.main.bounds.width - (buttonWidth * totalButtons)) / (totalButtons + 1)
    
    let buttons = [quoteButton, clearButton, infoButton, shareButton]
    for (index, button) in buttons.enumerated() {
      button.frame.origin.x = spacing + (buttonWidth + spacing) * CGFloat(index)
      button.frame.origin.y = 10
      bottomToolbar.addSubview(button)
    }
  }
  
  private func createCircularButton(title: String, symbol: String) -> UIView {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    
    // Create circular background
    let circleView = UIView(frame: CGRect(x: 15, y: 0, width: 50, height: 50))
    circleView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
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
    case "Clear":
        button.addTarget(self, action: #selector(handleClearButtonTap(_:)), for: .touchUpInside)
    case "Info":
        button.addTarget(self, action: #selector(handleInfoButtonTap(_:)), for: .touchUpInside)
    case "Share":
        button.addTarget(self, action: #selector(handleShareButtonTap(_:)), for: .touchUpInside)
    default:
        break
    }
    
    circleView.addSubview(button)
    
    // Add label
    let label = UILabel(frame: CGRect(x: 0, y: 55, width: 80, height: 20))
    label.text = title
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 14)
    label.textColor = .black
    containerView.addSubview(label)
    
    return containerView
  }
  
  private func setupPDFView(container: UIView, document: PDFDocument, initialPage: Int) {
    let pdfView = PDFView(frame: container.bounds)
    pdfView.document = document
    pdfView.autoScales = true
    pdfView.maxScaleFactor = 4.0
    pdfView.minScaleFactor = 0.5
    pdfView.usePageViewController(true)
    pdfView.backgroundColor = .systemBackground
    pdfView.pageShadowsEnabled = false
    pdfView.delegate = self
    
    // Go to initial page
    if initialPage > 1 && initialPage <= document.pageCount,
       let page = document.page(at: initialPage - 1) {
      pdfView.go(to: page)
    }
    
    container.addSubview(pdfView)
    self.pdfView = pdfView
    
    // Add tap gesture for text selection
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePDFTap(_:)))
    pdfView.addGestureRecognizer(tapGesture)
  }
  
  private func getTopViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
      return nil
    }
    
    var topViewController = window.rootViewController
    while let presentedViewController = topViewController?.presentedViewController {
      topViewController = presentedViewController
    }
    return topViewController
  }
  
  @objc private func dismissPDFView() {
    // Ensure minimized container is removed if it's currently visible
    if isMinimized {
        minimizedContainer?.removeFromSuperview()
        minimizedContainer = nil
    }
    
    // Dismiss the main PDF view controller
    pdfViewController?.dismiss(animated: true) {
      self.pdfViewController = nil
      self.pdfView = nil
      self.isMinimized = false
    }
  }
  
  @objc private func handleMinimizeButtonTap() {
    if isMinimized {
      maximizeModal()
    } else {
      minimizeModal()
    }
  }
  
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        // This pan gesture should primarily handle dragging the full-screen modal
        // or initiating the minimize action.
        guard let containerView = pdfViewController?.view else { return }
        let translation = gesture.translation(in: containerView.superview)
        let velocity = gesture.velocity(in: containerView.superview)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 { // Only allow downward drag
                let progress = min(translation.y / 200, 1.0)
                let scale = 1.0 - (progress * 0.2)
                containerView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            gesture.setTranslation(.zero, in: containerView.superview)
            
        case .ended:
            if velocity.y > 500 || translation.y > 100 {
                minimizeModal()
            } else {
                // Reset to full screen
                UIView.animate(withDuration: 0.3) {
                    containerView.transform = .identity
                }
            }
            
        default:
            break
        }
    }
  
    private func minimizeModal() {
        guard let pdfVC = pdfViewController else { return }
        
        // 1. Hide the full-screen PDF view controller's view
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: []) {
            pdfVC.view.alpha = 0 // Fade out the main PDF view
            pdfVC.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Optional: scale it down slightly
        } completion: { _ in
            pdfVC.view.isHidden = true // Fully hide after animation
            // Ensure the minimized view is properly setup and added to the main window's hierarchy
            self.setupMinimizedView() // Call this to ensure it's in the hierarchy if not already
            self.minimizedContainer?.isHidden = false // Show the minimized view
            // Snap to the default minimized position or last known drag position if available
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: []) {
                self.minimizedContainer?.frame = self.minimizedFrame // Use the calculated minimized frame
                self.minimizedContainer?.alpha = 1 // Ensure it's fully visible
            }
        }
        
        isMinimized = true
        print("Minimized - Container frame: \(self.minimizedContainer?.frame ?? .zero)")
    }
    
    // Helper function to snap minimized view to screen edges (called from handleMinimizedPan)
    private func snapToEdge() {
        guard let minimizedContainer = self.minimizedContainer else { return }
        
        let screenWidth = UIScreen.main.bounds.width
        let containerCenterX = minimizedContainer.center.x
        
        // Determine which edge is closer
        let snapToRight = containerCenterX > screenWidth / 2
        let newX = snapToRight ? screenWidth - minimizedContainer.frame.width / 2 - 10 : minimizedContainer.frame.width / 2 + 10
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: []) {
            minimizedContainer.center.x = newX
        }
    }
  
    private func maximizeModal() {
        guard let pdfVC = pdfViewController else { return }
        
        // 1. Hide the minimized container
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: []) {
            self.minimizedContainer?.alpha = 0
        } completion: { _ in
            self.minimizedContainer?.isHidden = true
            // Optionally remove from superview if it's only meant to exist when minimized
            // self.minimizedContainer?.removeFromSuperview()
        }
        
        // 2. Show and restore the full-screen PDF view controller's view
        pdfVC.view.isHidden = false // Make it visible before animation
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: []) {
            pdfVC.view.alpha = 1
            pdfVC.view.transform = .identity // Restore original scale
        }
        
        isMinimized = false
    }
  
  private func closePDFViewer(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      // Clean up minimized container if it exists
      if self.minimizedContainer != nil {
        self.minimizedContainer?.removeFromSuperview()
        self.minimizedContainer = nil
      }
      
      if let pdfViewController = self.pdfViewController {
        pdfViewController.dismiss(animated: true) {
          self.pdfViewController = nil
          self.pdfView = nil
          self.isMinimized = false
          result(true)
        }
      } else {
        result(FlutterError(code: "NO_PDF_VIEWER",
                           message: "No PDF viewer is currently open",
                           details: nil))
      }
    }
  }
  
  // MARK: - PDFViewDelegate
  public func pdfViewPageChanged(_ pdfView: PDFView) {
    guard let currentPage = pdfView.currentPage,
          let document = pdfView.document else { return }
    
    let pageNumber = document.index(for: currentPage) + 1
    if pageNumber != currentPageNumber {
      currentPageNumber = pageNumber
      updateProgress()
      
      let arguments: [String: Any] = [
        "pageNumber": pageNumber,
        "totalPages": document.pageCount
      ]
      actionsChannel?.invokeMethod("onPageChanged", arguments: arguments)
    }
  }
  
  // MARK: - Button Actions
  @objc private func handleQuoteButtonTap(_ sender: UIButton) {
    if !highlightOnTap {
      if let selectedText = getSelectedText() {
        handleSentenceSelected(selectedText)
        highlightSentence(selectedText)
      }
    } else if !selectedSentence.isEmpty {
      handleSentenceSelected(selectedSentence)
      highlightSentence(selectedSentence)
    }
    
    // Minimize after quote action
    if !isMinimized {
      minimizeModal()
    }
  }
  
  @objc private func  handleClearButtonTap(_ sender: UIButton) {
    guard let pdfView = self.pdfView,
          let document = pdfView.document else { return }
    
    // Clear all annotations from all pages
    for pageIndex in 0..<document.pageCount {
      if let page = document.page(at: pageIndex) {
        let annotations = page.annotations
        for annotation in annotations {
          page.removeAnnotation(annotation)
        }
      }
    }
    
    actionsChannel?.invokeMethod("clearAllQuotes", arguments: nil)
  }
  
  @objc private func handleInfoButtonTap(_ sender: UIButton) {
    actionsChannel?.invokeMethod("infoButton", arguments: nil)
    
    if !isMinimized {
      minimizeModal()
    }
  }
  
  @objc private func handleShareButtonTap(_ sender: UIButton) {
    guard let pdfView = self.pdfView,
          let currentPage = pdfView.currentPage else { return }
    
    let pageNumber = pdfView.document?.index(for: currentPage) ?? 0
    let arguments: [String: Any] = ["pageNumber": pageNumber + 1]
    actionsChannel?.invokeMethod("shareButton", arguments: arguments)
    
    if !isMinimized {
      minimizeModal()
    }
  }
  
  @objc private func handlePDFTap(_ gesture: UITapGestureRecognizer) {
    guard let pdfView = gesture.view as? PDFView,
          let currentPage = pdfView.currentPage,
          highlightOnTap else { return }
    
    let location = gesture.location(in: pdfView)
    if let sentence = selectSentence(at: location, on: currentPage, in: pdfView) {
      selectedSentence = sentence
    }
  }
  
  // MARK: - Helper Methods
  private func getSelectedText() -> String? {
    guard let pdfView = self.pdfView,
          let selection = pdfView.currentSelection else {
      return nil
    }
    return selection.string
  }
  
  
  
  private func handleSentenceSelected(_ sentence: String) {
    guard let pdfView = self.pdfView,
          let currentPage = pdfView.currentPage else { return }
    
    let pageNumber = currentPage.pageRef?.pageNumber ?? 0
    let arguments: [String: Any] = [
      "text": sentence,
      "pageNumber": pageNumber,
      "location": [
        "x": currentPage.bounds(for: .mediaBox).midX,
        "y": currentPage.bounds(for: .mediaBox).midY
      ]
    ]
    
    actionsChannel?.invokeMethod("quote", arguments: arguments)
  }
  
  private func selectSentence(at location: CGPoint, on page: PDFPage, in pdfView: PDFView) -> String? {
    let pdfPoint = pdfView.convert(location, to: page)
    
    guard let pageContent = page.string else { return nil }
    guard let tappedWord = getWordAt(point: pdfPoint, on: page, in: pageContent) else { return nil }
    
    // Split content into sentences
    let sentences = pageContent.components(separatedBy: CharacterSet(charactersIn: ".!?"))
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .map { $0 + "." }
    
    currentSentences = sentences
    
    if let index = sentences.firstIndex(where: { $0.contains(tappedWord) }) {
      let selectedSentence = sentences[index]
      return selectedSentence
    }
    
    return tappedWord
  }
  
  private func highlightSentence(_ selectedSentence: String) {
    guard let pdfView = self.pdfView,
          let page = pdfView.currentPage,
          shouldHighlightQuotes else { return }
    
    if let selections = page.document?.findString(selectedSentence) {
      if selections.count > 0 {
        let lines = selections[0].selectionsByLine()
        for line in lines {
          let highlight = PDFAnnotation(bounds: line.bounds(for: page), forType: .highlight, withProperties: nil)
          highlight.endLineStyle = .circle
          highlight.color = highlightColor
          highlight.contents = selectedSentence
          page.addAnnotation(highlight)
        }
      }
    }
  }
  
  private func getWordAt(point: CGPoint, on page: PDFPage, in pageContent: String) -> String? {
    let wordRange = 20
    
    let rawCharacterIndex = page.characterIndex(at: point)
    guard rawCharacterIndex >= 0 && rawCharacterIndex < pageContent.count else {
      return nil
    }
    
    let characterIndex = Int64(rawCharacterIndex)
    
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
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}