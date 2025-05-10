import Flutter
import UIKit
import PDFKit
import AVFoundation

public class PDFReaderPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
    private var speechSynthesizer: AVSpeechSynthesizer!
    private var pdfView: PDFView?
    private var currentDocument: PDFDocument?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.pdf_reader/ios", binaryMessenger: registrar.messenger())
        let instance = PDFReaderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    override init() {
        super.init()
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.delegate = self
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "highlightText":
            guard let args = call.arguments as? [String: Any],
                  let pdfPath = args["pdfPath"] as? String,
                  let pageIndex = args["pageIndex"] as? Int,
                  let text = args["text"] as? String,
                  let x = args["x"] as? Double,
                  let y = args["y"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            highlightText(pdfPath: pdfPath, pageIndex: pageIndex, text: text, x: x, y: y, completion: result)
            
        case "speakWithAVSpeech":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String,
                  let rate = args["rate"] as? Double,
                  let pitch = args["pitch"] as? Double,
                  let volume = args["volume"] as? Double,
                  let language = args["language"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            speakWithAVSpeech(text: text, rate: rate, pitch: pitch, volume: volume, language: language, completion: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func highlightText(pdfPath: String, pageIndex: Int, text: String, x: Double, y: Double, completion: @escaping FlutterResult) {
        // Load PDF document if needed
        if currentDocument == nil || currentDocument?.documentURL?.path != pdfPath {
            guard let documentURL = URL(string: pdfPath) else {
                completion(FlutterError(code: "INVALID_PATH", message: "Invalid PDF path", details: nil))
                return
            }
            
            currentDocument = PDFDocument(url: documentURL)
        }
        
        guard let document = currentDocument,
              let page = document.page(at: pageIndex) else {
            completion(FlutterError(code: "PAGE_NOT_FOUND", message: "PDF page not found", details: nil))
            return
        }
        
        // Try to find and highlight the text
        let pdfPoint = CGPoint(x: x, y: y)
        if let selection = page.selectionForLine(at: pdfPoint) {
            let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
            highlight.color = UIColor.yellow.withAlphaComponent(0.5)
            page.addAnnotation(highlight)
            completion(true)
        } else {
            completion(false)
        }
    }
    
    private func speakWithAVSpeech(text: String, rate: Double, pitch: Double, volume: Double, language: String, completion: @escaping FlutterResult) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = Float(rate)
        utterance.pitchMultiplier = Float(pitch)
        utterance.volume = Float(volume)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        speechSynthesizer.speak(utterance)
        completion(true)
    }
    
    // AVSpeechSynthesizerDelegate methods
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // This would be used to highlight the current word being spoken
        // We would need to send this information back to Flutter
        // For a complete implementation, we would use a method channel to send events back to Flutter
    }
}
