
import UIKit
import WebKit

protocol APWebVCDelegate {
    func backToShareUploadVC()
    func returnTokenToShareUploadVC(_ token: String, username: String, userID: String)
}

class APWebVC: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var mWKWebView: WKWebView!
    @IBOutlet weak var titleHeader: UILabel!
    var urlString : String?
    var titleString : String = ""
    var delegate : APWebVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleHeader.text = titleString
        titleHeader.textColor = UIColor.white
        titleHeader.textAlignment = .center
        
        mWKWebView.navigationDelegate = self
        loadAddress()
    }
    
    func loadAddress(){
        if let url = URL(string: urlString!) {
            let request = URLRequest(url: url)
            mWKWebView.load(request)
        }
    }
    
    @IBAction func onBack(_ sender: Any) {
        mWKWebView.stopLoading()
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK:- WKNavigationDelegate Methods
    
    //Equivalent of shouldStartLoadWithRequest:
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var action: WKNavigationActionPolicy?
        
        defer {
            decisionHandler(action ?? .allow)
        }
        
        guard let request = navigationAction.request.url?.absoluteString else { return }
        checkRequestForCallbackURL(request)
    }
    
    //Equivalent of webViewDidStartLoad:
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        TBLoaderView.show()
        print("didStartProvisionalNavigation - webView.url: \(String(describing: webView.url?.description))")
    }
    
    //Equivalent of didFailLoadWithError:
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        TBLoaderView.hide()
        let nserror = error as NSError
        if nserror.code != NSURLErrorCancelled {
            webView.loadHTMLString("Page Not Found", baseURL: URL(string: urlString!))
        }
    }
    
    //Equivalent of webViewDidFinishLoad:
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        TBLoaderView.hide()
        print("didFinish - webView.url: \(String(describing: webView.url?.description))")
        
    }
}
//Mark: HANDLE IG AUTH
extension APWebVC {
    func checkRequestForCallbackURL(_ requestURLString: String) {
        print(requestURLString)
        if requestURLString.hasPrefix(API.INSTAGRAM_REDIRECT_URI) {
            let token = StringsHelper().getQueryStringParameter(url: requestURLString, param:"access_token")
            let userID = StringsHelper().getQueryStringParameter(url: requestURLString, param:"user_id")
            handleAuth(authToken: token!, userID: userID!)
        }
    }
    
    func handleAuth(authToken: String, userID: String) {
        API.INSTAGRAM_ACCESS_TOKEN = authToken
        print("Instagram authentication token ==", authToken)
        APIManager.sharedInstance.getInstagramUserInfo(authToken, user_id: userID) { (status, username) in
            if status {
                self.delegate?.returnTokenToShareUploadVC(authToken, username: username, userID: userID)
                self.performSegueToReturnBack()
            }
            else {
                self.performSegueToReturnBack()
            }
        }
    }
}
