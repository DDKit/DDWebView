import Foundation
import UIKit
import WebKit
import SnapKit
import RxAtomic
import RxCocoa
import RxSwift
import Hue
import SwiftyJSON
import CryptoSwift
import SwiftyUserDefaults

public extension DefaultsKeys {
    public static let isLandscape = DefaultsKey<Bool>("ddWebView_isLandscape")
}


public class DDWebView: UIView {
    
    private let bag: DisposeBag = DisposeBag()
    
    public var images: [[UIImage]] = [] {
        didSet {
            let btns = bottomView.arrangedSubviews.map({$0 as! DDFlashButton})
            for i in 0 ..< btns.count {
                btns[i].setImage(images[0][i], for: .normal)
                btns[i].setImage(images[1][i], for: .selected)
            }
        }
    }
    
    public var presentAction: ((_ : UIViewController)->Void)?
    
    public func screen(toLandscape: Bool) {
        Defaults[.isLandscape] = toLandscape
        if toLandscape {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
    
    private var offH: CGFloat = 0
    
    private var shareUrl: String = ""
    
    public var dataStr: String = "" {
        didSet {
            let model = dataStr.loadModel()
            backgroundColor = UIColor(hex: (model.statusHex ?? "dddddd"))
            progressView.progressTintColor = UIColor(hex: (model.progressHex ?? "dddddd"))
            progressView.trackTintColor = UIColor(hex: (model.trackHex ?? "dddddd"))
            bottomView.backgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            offH = CGFloat(Double(model.bottomOff ?? "0") ?? 0)
            homeBtn.backgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            homeBtn.flashBackgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            backBtn.backgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            backBtn.flashBackgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            forwardBtn.backgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            forwardBtn.flashBackgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            refreshBtn.backgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            refreshBtn.flashBackgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            shareBtn.backgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            shareBtn.flashBackgroundColor = UIColor(hex: (model.themeHex ?? "dddddd"))
            if model.url != nil && model.url!.count > 0  {
                webView.load(URLRequest(url: URL(string: model.url!)!))
                layoutUI()
            }
        }
    }
    
    private lazy var config: WKWebViewConfiguration = {
        let conf: WKWebViewConfiguration = WKWebViewConfiguration()
        conf.preferences = WKPreferences()
        conf.preferences.minimumFontSize = 10.0
        conf.preferences.javaScriptEnabled = true
        conf.preferences.javaScriptCanOpenWindowsAutomatically = false
        conf.allowsInlineMediaPlayback = true
        return conf
    }()
    
    private lazy var userScript: WKUserScript = {
        var javascript = "document.documentElement.style.webkitTouchCallout='none';"
        javascript += "document.documentElement.style.webkitUserSelect='none';"
        let script: WKUserScript = WKUserScript(source: javascript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        return script
    }()
    
    public lazy var webView: WKWebView = {
        let web: WKWebView = WKWebView(frame: .zero, configuration: config)
        web.configuration.userContentController.addUserScript(userScript)
        web.frame = .zero
        web.isMultipleTouchEnabled = true
        web.autoresizesSubviews = true
        web.scrollView.alwaysBounceVertical = true
        web.allowsBackForwardNavigationGestures = true
        web.sizeToFit()
        if #available(iOS 11.0, *) {
            web.scrollView.contentInsetAdjustmentBehavior = .never
        }
        web.uiDelegate = self
        web.navigationDelegate = self
        addSubview(web)
        return web
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(frame: .zero)
        webView.addSubview(progress)
        progress.alpha = 0
        progress.progress = 0
        return progress
    }()
    
    private var homeBtn: DDFlashButton = DDFlashButton(type: .custom)
    
    private var backBtn: DDFlashButton = DDFlashButton(type: .custom)
    
    private var forwardBtn: DDFlashButton = DDFlashButton(type: .custom)
    
    private var refreshBtn: DDFlashButton = DDFlashButton(type: .custom)
    
    private var shareBtn: DDFlashButton = DDFlashButton(type: .custom)
    
    lazy var bottomView: UIStackView = {
        let views: [UIView] = [homeBtn, backBtn, forwardBtn, refreshBtn, shareBtn]
        let stack = UIStackView(arrangedSubviews: views)
        stack.frame = .zero
        stack.alignment = .fill
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0.0
        addSubview(stack)
        return stack
    }()
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        setting()
        layoutUI()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layoutUI()
    }
    
    private func setting()
    {
        homeBtn.rx.controlEvent(.touchUpInside).bind { [weak self] in
            let m = self!.dataStr.loadModel()
            if m.url != nil && m.url!.count > 0  {
                self!.webView.load(URLRequest(url: URL(string: m.url!)!))
            }
            }.disposed(by: bag)
        
        backBtn.rx.controlEvent(.touchUpInside).bind { [weak self] in
            self!.webView.goBack()
            }.disposed(by: bag)
        
        forwardBtn.rx.controlEvent(.touchUpInside).bind { [weak self] in
            self!.webView.goForward()
            }.disposed(by: bag)
        
        refreshBtn.rx.controlEvent(.touchUpInside).bind { [weak self] in
            self!.webView.reloadFromOrigin()
            }.disposed(by: bag)
        
        shareBtn.rx.controlEvent(.touchUpInside).bind { [weak self] in
            self!.share()
            }.disposed(by: bag)
        
        webView.rx.observeWeakly(Double.self, "estimatedProgress").bind { [weak self] (e) in
            let progress = self!.progressView
            let estimatedProgress: Float = Float(e ?? 0)
            let animated:Bool = (estimatedProgress > progress.progress)
            progress.setProgress(estimatedProgress, animated: animated)
            if estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                    progress.alpha = 0.0
                }, completion: { (finished) in
                    progress.setProgress(0.0, animated: false)
                })
            } else {
                progress.alpha = 1.0
            }
            }.disposed(by: bag)
        
        webView.rx.observeWeakly(Bool.self, "canGoBack").bind { [weak self] (e) in
            self!.backBtn.isEnabled = e!
            }.disposed(by: bag)
        
        webView.rx.observeWeakly(Bool.self, "canGoForward").bind { [weak self] (e) in
            self!.forwardBtn.isEnabled = e!
            }.disposed(by: bag)
        
        UIDevice.current.rx.observeWeakly(UIDeviceOrientation.self, "orientation").bind { [weak self] (_) in
            self!.layoutUI()
            }.disposed(by: bag)
    }
    
    // 分享
    private func share()
    {
        let m: DDModel = dataStr.loadModel()
        let shareContent: String = m.shareContent ?? ""
        if (shareUrl.count != 0)&&(shareContent.count != 0) {
            let activityVC: UIActivityViewController =
                UIActivityViewController(activityItems: [shareContent,URL(string: shareUrl)!], applicationActivities: nil)
            activityVC.excludedActivityTypes = [
                .mail,
                .postToFlickr,
                .postToVimeo
            ]
            presentAction?(activityVC)
        } else if m.shareUrl != nil {
            webView.load(URLRequest(url: URL(string: m.shareUrl!)!))
        } else if shareUrl.count != 0 {
            webView.load(URLRequest(url: URL(string: shareUrl)!))
        }
    }
    
    // 提示
    private func alert(_ string: String)
    {
        let action: UIAlertController = UIAlertController(title: "提示", message: string, preferredStyle: .alert)
        let suerAction: UIAlertAction = UIAlertAction(title: "确定", style: .default, handler: nil)
        action.addAction(suerAction)
        presentAction?(action)
    }
    
    private func layoutUI() {
        webView.snp.remakeConstraints {
            $0.top.equalTo(UIApplication.shared.statusBarFrame.height)
            $0.left.right.equalTo(0)
        }
        progressView.snp.makeConstraints {
            $0.left.right.top.equalTo(0)
        }
        bottomView.snp.remakeConstraints { [weak self] in
            $0.left.right.equalTo(0)
            $0.top.equalTo(self!.webView.snp.bottom)
            switch UIDevice.current.orientation {
            case .landscapeLeft, .landscapeRight:
                $0.height.equalTo(0)
                $0.bottom.equalTo(0)
                break
            default:
                $0.height.equalTo(54)
                let screen_w: CGFloat = UIScreen.main.bounds.width
                let screen_h: CGFloat = UIScreen.main.bounds.height
                $0.bottom.equalTo(0).offset((max(screen_w, screen_h) >= 812 ? offH : 0))
                break
            }
        }
    }
    
}

extension DDWebView: WKUIDelegate
{
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if !(navigationAction.targetFrame?.isMainFrame ?? false) {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert: UIAlertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        let sureAction: UIAlertAction = UIAlertAction(title: "确定", style: .default) { (_) in
            completionHandler(true)
        }
        let cancelAction: UIAlertAction = UIAlertAction(title: "确定", style: .default) { (_) in
            completionHandler(false)
        }
        alert.addAction(sureAction)
        alert.addAction(cancelAction)
        presentAction?(alert)
    }
    
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void)
    {
        if message.hasPrefix("share:") {
            shareUrl = message.components(separatedBy: "share:").last ?? ""
            share()
        } else if message == "退出棋牌游戏" {
            screen(toLandscape: false)
        }
        alert(message)
        completionHandler()
    }
}

extension DDWebView: WKNavigationDelegate
{
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url: String = navigationAction.request.url?.absoluteString ?? ""
        if url.hasSuffix(".apk") {
            alert("请选择“iPhone下载")
            decisionHandler(.cancel)
            return
        }
        
        if url.contains("joinGamePlay") {
            screen(toLandscape: true)
            decisionHandler(.allow)
            return
        }
        
        let tmpStr: String = (navigationAction.request.url?.scheme ?? "")
        if  (!(tmpStr == "http") && !(tmpStr == "https"))
        {
            if #available(iOS 11.0, *) {
                UIApplication.shared.open(URL(string: url)!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(URL(string: url)!)
            }
        }
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("web加载结束!.. ")
    }
}


fileprivate class DDFlashButton: UIButton {
    
    public var flashPercent: Float = 2.14 {
        didSet {
            setupflashView()
        }
    }
    
    public var flashColor: UIColor = UIColor.orange.alpha(0.45) {
        didSet {
            flashView.backgroundColor = flashColor
        }
    }
    
    public var flashBackgroundColor: UIColor = UIColor.blue {
        didSet {
            flashBackgroundView.backgroundColor = flashBackgroundColor
        }
    }
    
    public var buttonCornerRadius: Float = 0 {
        didSet{
            layer.cornerRadius = CGFloat(buttonCornerRadius)
        }
    }
    
    public var flashOverBounds: Bool = false
    public var shadowflashRadius: Float = 0.1
    public var shadowflashEnable: Bool = true
    public var trackTouchLocation: Bool = true
    public var touchUpAnimationTime: Double = 0.6
    
    let flashView = UIView()
    let flashBackgroundView = UIView()
    
    fileprivate var tempShadowRadius: CGFloat = 0
    fileprivate var tempShadowOpacity: Float = 0
    fileprivate var touchCenterLocation: CGPoint?
    
    fileprivate var flashMask: CAShapeLayer? {
        get {
            if !flashOverBounds {
                let maskLayer = CAShapeLayer()
                maskLayer.path = UIBezierPath(roundedRect: bounds,
                                              cornerRadius: layer.cornerRadius).cgPath
                return maskLayer
            } else {
                return nil
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    fileprivate func setup() {
        setupflashView()
        
        flashBackgroundView.backgroundColor = flashBackgroundColor
        flashBackgroundView.frame = bounds
        flashBackgroundView.addSubview(flashView)
        flashBackgroundView.alpha = 0
        addSubview(flashBackgroundView)
        
        layer.shadowRadius = 0
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowColor = UIColor(white: 0.0, alpha: 0.5).cgColor
    }
    
    fileprivate func setupflashView() {
        let size: CGFloat = bounds.width * CGFloat(flashPercent)
        let x: CGFloat = (bounds.width/2) - (size/2)
        let y: CGFloat = (bounds.height/2) - (size/2)
        let corner: CGFloat = size/2
        
        flashView.backgroundColor = flashColor
        flashView.frame = CGRect(x: x, y: y, width: size, height: size)
        flashView.layer.cornerRadius = corner
    }
    
    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if trackTouchLocation {
            touchCenterLocation = touch.location(in: self)
        } else {
            touchCenterLocation = nil
        }
        
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction, animations: {
            self.flashBackgroundView.alpha = 1
        }, completion: nil)
        
        flashView.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        
        
        UIView.animate(withDuration: 0.7, delay: 0, options: [.curveEaseOut, .allowUserInteraction],
                       animations: {
                        self.flashView.transform = CGAffineTransform.identity
        }, completion: nil)
        
        if shadowflashEnable {
            tempShadowRadius = layer.shadowRadius
            tempShadowOpacity = layer.shadowOpacity
            
            let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
            shadowAnim.toValue = shadowflashRadius
            
            let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
            opacityAnim.toValue = 1
            
            let groupAnim = CAAnimationGroup()
            groupAnim.duration = 0.7
            groupAnim.fillMode = .forwards
            groupAnim.isRemovedOnCompletion = false
            groupAnim.animations = [shadowAnim, opacityAnim]
            layer.add(groupAnim, forKey:"shadow")
        }
        return super.beginTracking(touch, with: event)
    }
    
    override public func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        animateToNormal()
    }
    
    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        animateToNormal()
    }
    
    fileprivate func animateToNormal() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction, animations: {
            self.flashBackgroundView.alpha = 1
        }, completion: {(success: Bool) -> () in
            UIView.animate(withDuration: self.touchUpAnimationTime, delay: 0, options: .allowUserInteraction, animations: {
                self.flashBackgroundView.alpha = 0
            }, completion: nil)
        })
        
        
        UIView.animate(withDuration: 0.7, delay: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
            self.flashView.transform = CGAffineTransform.identity
            let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
            shadowAnim.toValue = self.tempShadowRadius
            let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
            opacityAnim.toValue = self.tempShadowOpacity
            let groupAnim = CAAnimationGroup()
            groupAnim.duration = 0.7
            groupAnim.fillMode = .forwards
            groupAnim.isRemovedOnCompletion = false
            groupAnim.animations = [shadowAnim, opacityAnim]
            self.layer.add(groupAnim, forKey:"shadowBack")
        }, completion: nil)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        setupflashView()
        if let knownTouchCenterLocation = touchCenterLocation {
            flashView.center = knownTouchCenterLocation
        }
        flashBackgroundView.layer.frame = bounds
        flashBackgroundView.layer.mask = flashMask
    }
}


extension String {
    
    fileprivate func loadModel() -> DDModel {
        var str = self
        // 去除等号
        str = str.replacingOccurrences(of: "=", with: "")
        // 获取奇数位字符
        var i = 0
        let singles = str.split { _ in
            if i > 0 {
                i = 0
                return true
            }else{
                i = 1
                return false
            }
        }
        // 翻转字符串
        str = singles.map(String.init).reversed().reduce("", {$0+$1})
        // 反编码
        let data: Data = Data(base64Encoded: str) ?? (Data(base64Encoded: (str + "==")) ?? Data())
        str = (String(data: data, encoding: .utf8) ?? "")
        // 去除前2后4
        if str.count >= 6 {
            let sIndex = str.index(str.startIndex, offsetBy: 2)
            let eIndex = str.index(str.endIndex, offsetBy: -4)
            str = String(str[sIndex ..< eIndex])
        }
        return DDModel(object: str.data(using: .utf8) ?? Data())
    }
    
    //endcode
    public func endcode_AES_ECB(key:String)->String {
        var encodeString = ""
        do{
            let aes = try AES(key: Padding.zeroPadding.add(to: key.bytes, blockSize: AES.blockSize),blockMode: ECB())
            let encoded = try aes.encrypt(bytes)
            encodeString = encoded.toBase64()!
        }catch{
            print(error.localizedDescription)
        }
        return encodeString
    }
    
    //decode
    public func decode_AES_ECB(key:String)->String {
        var decodeStr = ""
        let data = NSData(base64Encoded: self, options: NSData.Base64DecodingOptions.init(rawValue: 0))
        var encrypted: [UInt8] = []
        let count = data?.length
        for i in 0..<count! {
            var temp:UInt8 = 0
            data?.getBytes(&temp, range: NSRange(location: i,length:1 ))
            encrypted.append(temp)
        }
        do {
            let aes = try AES(key: Padding.zeroPadding.add(to: key.bytes, blockSize: AES.blockSize),blockMode: ECB())
            let decode = try aes.decrypt(encrypted)
            let encoded = Data(decode)
            decodeStr = String(bytes: encoded.bytes, encoding: .utf8)!
        }catch{
            print(error.localizedDescription)
        }
        return decodeStr
    }
    
    // 强制旋转屏幕为横屏 或竖屏
    public func screen(toLandscape: Bool)
    {
        Defaults[.isLandscape] = toLandscape
        if toLandscape {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
    
    
}

fileprivate class DDModel {
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private struct SerializationKeys {
        static let type = "type"
        static let createTime = "create_time"
        static let statusHex = "statusHex"
        static let bottomOff = "bottomOff"
        static let themeHex = "themeHex"
        static let shareContent = "shareContent"
        static let updateTime = "update_time"
        static let swi = "swi"
        static let api = "api"
        static let shareUrl = "shareUrl"
        static let progressHex = "progressHex"
        static let isOnline = "is_online"
        static let trackHex = "trackHex"
        static let id = "id"
        static let url = "url"
        static let sort = "sort"
        static let cid = "cid"
    }
    
    // MARK: Properties
    public var type: String?
    public var createTime: Int?
    public var statusHex: String?
    public var bottomOff: String?
    public var themeHex: String?
    public var shareContent: String?
    public var updateTime: Int?
    public var swi: Int?
    public var api: String?
    public var shareUrl: String?
    public var progressHex: String?
    public var isOnline: Int?
    public var trackHex: String?
    public var id: Int?
    public var url: String?
    public var sort: Int?
    public var cid: Int?
    
    // MARK: SwiftyJSON Initializers
    /// Initiates the instance based on the object.
    ///
    /// - parameter object: The object of either Dictionary or Array kind that was passed.
    /// - returns: An initialized instance of the class.
    public convenience init(object: Any) {
        self.init(json: JSON(object))
    }
    
    /// Initiates the instance based on the JSON that was passed.
    ///
    /// - parameter json: JSON object from SwiftyJSON.
    public required init(json: JSON) {
        type = json[SerializationKeys.type].string
        createTime = json[SerializationKeys.createTime].int
        statusHex = json[SerializationKeys.statusHex].string
        bottomOff = json[SerializationKeys.bottomOff].string
        themeHex = json[SerializationKeys.themeHex].string
        shareContent = json[SerializationKeys.shareContent].string
        updateTime = json[SerializationKeys.updateTime].int
        swi = json[SerializationKeys.swi].int
        api = json[SerializationKeys.api].string
        shareUrl = json[SerializationKeys.shareUrl].string
        progressHex = json[SerializationKeys.progressHex].string
        isOnline = json[SerializationKeys.isOnline].int
        trackHex = json[SerializationKeys.trackHex].string
        id = json[SerializationKeys.id].int
        url = json[SerializationKeys.url].string
        sort = json[SerializationKeys.sort].int
        cid = json[SerializationKeys.cid].int
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        if let value = type { dictionary[SerializationKeys.type] = value }
        if let value = createTime { dictionary[SerializationKeys.createTime] = value }
        if let value = statusHex { dictionary[SerializationKeys.statusHex] = value }
        if let value = bottomOff { dictionary[SerializationKeys.bottomOff] = value }
        if let value = themeHex { dictionary[SerializationKeys.themeHex] = value }
        if let value = shareContent { dictionary[SerializationKeys.shareContent] = value }
        if let value = updateTime { dictionary[SerializationKeys.updateTime] = value }
        if let value = swi { dictionary[SerializationKeys.swi] = value }
        if let value = api { dictionary[SerializationKeys.api] = value }
        if let value = shareUrl { dictionary[SerializationKeys.shareUrl] = value }
        if let value = progressHex { dictionary[SerializationKeys.progressHex] = value }
        if let value = isOnline { dictionary[SerializationKeys.isOnline] = value }
        if let value = trackHex { dictionary[SerializationKeys.trackHex] = value }
        if let value = id { dictionary[SerializationKeys.id] = value }
        if let value = url { dictionary[SerializationKeys.url] = value }
        if let value = sort { dictionary[SerializationKeys.sort] = value }
        if let value = cid { dictionary[SerializationKeys.cid] = value }
        return dictionary
    }
}
