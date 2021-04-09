import UIKit
import ObjectMapper
import FirebaseMessaging

//MARK:- CUSTOM DELEGATES
protocol LoginVCDelegate {
    func didLoginSuccessfully()
    func didTapSignUpButtonOnLoginVC()
}

class LoginVC: UIViewController {

    //MARK: - OUTLETS
    @IBOutlet weak var userNameTxtFld: UITextField!
    @IBOutlet weak var passwordTxtFld: UITextField!
    
    //MARK: - GLOBAL VARIABLES
    var delegate : LoginVCDelegate!
    var isComingFromProfileScreen = false
    var loginType = "email"
    
    //MARK: - VIEW CONTROLLER LIFE CYCLE FUNCTIONS
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCustomPlaceHolderToTextFlds()
        self.userNameTxtFld.delegate = self
        self.passwordTxtFld.delegate = self
    }
    
    /**
    * Function to add custom placeholder on text fields.
    */
    func addCustomPlaceHolderToTextFlds() {
        userNameTxtFld.attributedPlaceholder = NSAttributedString(string: "EMAIL/PHONE",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        passwordTxtFld.attributedPlaceholder = NSAttributedString(string: "PASSWORD",
               attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
    
    /**
     * Function to validate user input.
     */
    func validateInput() -> Bool {
        if self.userNameTxtFld.text?.trim().isEmpty == true || self.passwordTxtFld.text?.trim().isEmpty == true  {
            self.showAlertView(title: "Error", msg: "Please enter all the details")
            return false
        }
        return true
    }
    
    /**
     * Function to navigate to Email/Phone VC when user taps on forgot password
     */
    func navigateToEmailPhoneVCWhenForgotPass() {
        let destinationVC = self.storyboard?.instantiateViewController(withIdentifier: EmailPhoneWhenForgotPassVC.className) as! EmailPhoneWhenForgotPassVC
        let nav = UINavigationController(rootViewController: destinationVC)
        nav.navigationBar.isHidden = true
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
        
    }
    
    //MARK:- BUTTON ACTIONS
    @IBAction func submitBtnTapped(_ sender: UIButton) {
        if validateInput() {
            let deviceId = Messaging.messaging().fcmToken
            let dict = [self.loginType:self.userNameTxtFld.text!, "password":self.passwordTxtFld.text!,"signup_type":self.loginType,"device_token":deviceId] as [String : Any]
            self.serviceLoginAPI(paras: dict as Dictionary<String, Any>)
        }
    }
    
    @IBAction func signUpBtnTapped(_ sender: UIButton) {
        if isSubscriptionExpired() == false {
            self.showAlertView(title: "Error", msg: "You already have a subscription. Please login.")
            return
        }
        else {
            self.delegate.didTapSignUpButtonOnLoginVC()
        }
    }
    
    @IBAction func crossBtnTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func forgotPasswordBtnTapped(_ sender: UIButton) {
        self.navigateToEmailPhoneVCWhenForgotPass()
    }
    
}

    //MARK:- WEB SERVICES
extension LoginVC {
    /**
     * API call to login user
     */
    func serviceLoginAPI(paras:Dictionary<String,Any>) {
        self.showProgressHUD()
        APIManager.shared.request(url: API.login, method: .post, parameters: paras, completionCallback: { (_ ) in
            self.hideProgressHUD()
        }, success: { (json) in
            if let json = json["data"] as? [String:Any] {
                if let userModel = Mapper<UserModel>().map(JSONObject: json) {
                    self.loginDelegate.didLoginSuccessfully()
                    NotificationCenter.default.post(name: .didLogin, object: nil)
                    globalUserDetail = userModel
                    globalSearchHistory = [String]()
                }
            }
        }) { (error) in
            self.showAlertView(title: "Error", msg: error!)
        }
    }
}

    
    //MARK: - TEXT FIELD DELGATES
extension LoginVC : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.userNameTxtFld {
            if textField.text!.isValidEmail {
                self.loginType = "email"
            }
            else {
                if textField.text!.isNumeric {
                    self.loginType = "mobile"
                }
                else {
                    self.loginType = "email"
                }
            }
        }
    }
}
    

