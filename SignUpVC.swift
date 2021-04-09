import UIKit
import ObjectMapper
import StoreKit
import FirebaseMessaging

//MARK: - CUSTOM DELEGATES
protocol SignUpVCDelegate : class {
    func didRegisterUser()
}

class SignUpVC: UIViewController {
    
    //MARK:- OUTLETS
    @IBOutlet weak var nameTxtFld: UITextField!
    @IBOutlet weak var emailTxtFld: UITextField!
    @IBOutlet weak var passwordTxtFld: UITextField!
    @IBOutlet weak var iAgreeBtnOutl: UIButton!
    @IBOutlet weak var termsBtnOutl: UIButton!
    @IBOutlet weak var privacyPolicyBtnOutl: UIButton!
    @IBOutlet weak var backBtnOutl: UIButton!
    @IBOutlet weak var eyeBtnOutl: UIButton!
    //MARK: - CLASS VARIABLES
    /**
     * Declaring and/or initialising class variables
     */
    var isAgreed : Bool = false
    var showPassword : Bool = false
    var delegate : SignUpVCDelegate!
    var chosenPlanId : Int?
    var isEmailIdAvailable = false
    var userDetialsDict = [String:Any]()
    var chosenPlanPrice : String?
    var isSubscriptionAvailable : Bool = false
//MARK:- VIEW CONTROLLER LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
        self.nameTxtFld.delegate = self
        self.emailTxtFld.delegate = self
        self.passwordTxtFld.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = false
    }
    

    //MARK:- CUSTOM FUNCTIONS
    /**
     * Function to add attributed/custom placeholder texts and titles
     * to text fields and buttons
     */
    func configureUI() {
        nameTxtFld.attributedPlaceholder = NSAttributedString(string: "Name",
                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        emailTxtFld.attributedPlaceholder = NSAttributedString(string: "Email",
                                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        passwordTxtFld.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        
        let yourAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,.foregroundColor: UIColor.white,.font: UIFont.systemFont(ofSize: 14,weight: .medium)]
        
        let attributeString = NSMutableAttributedString(string: "Terms of Service",
                                                        attributes: yourAttributes)
        termsBtnOutl.setAttributedTitle(attributeString, for: .normal)
        
        let attributeString2 = NSMutableAttributedString(string: "Privacy Policy",
                                                         attributes: yourAttributes)
        privacyPolicyBtnOutl.setAttributedTitle(attributeString2, for: .normal)
        
    }
    
    /**
     * Function to validate user input
     */
    func checkInputValidation() -> Bool {
        if self.nameTxtFld.text!.trim().isEmpty == true  || self.emailTxtFld.text!.trim().isEmpty == true  ||  self.passwordTxtFld.text!.trim().isEmpty == true    {
            self.showAlertView(title: "Error", msg: "Make sure to fill all the details")
            return false
        }
            
        else if self.emailTxtFld.text?.isValidEmail == false {
            self.showAlertView(title: "Error", msg: "You must enter a valid email address")
            return false
        }
            
        else if self.passwordTxtFld.text!.count < 8 {
            self.showAlertView(title: "Error", msg: "The password should be atleast 8 characters long")
            return false
        }
            
        else if self.passwordTxtFld.text!.validatePassword == false {
            self.showAlertView(title: "Error", msg: "The password must contain an uppercase letter, a number and a special character")
            return false
        }
            
        else if !isAgreed {
            self.showAlertView(title: "Error", msg: "You must agree to receive updates from BarBaar")
            return false
        }
        return true
    }
    
    /**
     * Function to navigate to OTP Verification VC
     */
    func navigateToVerifyOtpVC(userDetails: [String:Any], userModel:UserModel?) {
        let destinationVC = self.storyboard?.instantiateViewController(withIdentifier: VerifyOtpVC.className) as! VerifyOtpVC
          destinationVC.typeOfSignUpMethod = .email
        destinationVC.userModel = userModel
        destinationVC.userDetials = userDetails
        destinationVC.chosenPlanPrice = self.chosenPlanPrice
        self.navigationController?.pushViewController(destinationVC, animated: true)
    }
    
    /**
      * Function to navigate to Web View VC
      */
    func navigateToWebViewVC(titleText: String) {
        let destinationVC = self.storyboard?.instantiateViewController(withIdentifier: WebViewVC.className) as! WebViewVC
        destinationVC.navBarTitleText = titleText
        destinationVC.modalPresentationStyle = .fullScreen
        self.present(destinationVC, animated: true, completion: nil)
    }
    
    //MARK:- BUTTON ACTIONS

    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func crossBtnTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func termsOfServiceTapped(_ sender: UIButton) {
         self.navigateToWebViewVC(titleText: "Terms of Service")
    }
    
    @IBAction func privacyPolicyTapped(_ sender: UIButton) {
        self.navigateToWebViewVC(titleText: "Privacy Policy")
    }
    
    @IBAction func signUpBtnTapped(_ sender: UIButton) {
        if self.checkInputValidation() {
            let name = self.nameTxtFld.text
            let email = self.emailTxtFld.text
            let password = self.passwordTxtFld.text
            let deviceType = "ios"
            let deviceId = Messaging.messaging().fcmToken
            let type = "email"
            self.userDetialsDict = ["name":name as Any,"email":email as Any,"password":password as Any,"device_token":deviceId,"device_type":deviceType,"plan_id":self.chosenPlanId, "signup_type":type] as [String : Any]
            self.serviceSignUpAPI(paras: self.userDetialsDict)
            
        }
        else {
          self.showAlertView(title: "Error", msg: "Please make sure to enter all the details.")
        }
    }
    
    @IBAction func eyeBtnTapped(_ sender: UIButton) {
        showPassword = !showPassword
        if showPassword {
            self.eyeBtnOutl.setBackgroundImage(#imageLiteral(resourceName: "icon_eye"), for: .normal)
            self.passwordTxtFld.isSecureTextEntry = false
        }
        else {
            self.eyeBtnOutl.setBackgroundImage(#imageLiteral(resourceName: "icon_eyeSlash"), for: .normal)
            self.passwordTxtFld.isSecureTextEntry = true
        } }
    
    
    @IBAction func iAgreeCheckBoxTapped(_ sender: UIButton) {
        isAgreed = !isAgreed
        if isAgreed {
            if #available(iOS 13.0, *) {
                iAgreeBtnOutl.setBackgroundImage(UIImage(systemName: "checkmark.square"), for: .normal)
            } else {
               iAgreeBtnOutl.setBackgroundImage(UIImage(systemName: "icon_checkmark_square"), for: .normal)
            }
        }
        else {
            if #available(iOS 13.0, *) {
                iAgreeBtnOutl.setBackgroundImage(UIImage(systemName: "square"), for: .normal)
            } else {
             iAgreeBtnOutl.setBackgroundImage(UIImage(systemName: "icon_square"), for: .normal)
            }
        }
    }
    
    //MARK:- WEB SERVICES
    /**
     * API call to check email validity
     */
    func serviceCheckEmailValidityAPI(email:String) {
        self.showProgressHUD()
        APIManager.shared.request(url: API.checkEmailValidity + email, method: .get, completionCallback: { (_ ) in
        }, success: { (json) in
            if let json = json as? [String:Any] {
                if json["error"] as? Bool != true {
                    self.serviceSignUpAPI(paras: self.userDetialsDict)
                } else {
                    self.hideProgressHUD()
                }
            }
        }) { (error) in
            self.hideProgressHUD()
            self.isEmailIdAvailable = false
            self.showAlertView(title: "Error", msg: error!)
        }
    }
    
    /**
     * API call to sign up user
     */
    func serviceSignUpAPI(paras:Dictionary<String,Any>) {
        self.showProgressHUD()
        APIManager.shared.request(url: API.register, method: .post, parameters: paras, completionCallback: { (_ ) in
            self.hideProgressHUD()
        }, success: { (json) in
            if let json = json["data"] as? [String:Any] {
                if let userModell = Mapper<UserModel>().map(JSONObject: json) {
                    self.navigateToVerifyOtpVC(userDetails: self.userDetialsDict, userModel: userModell)
                }
            }
        }) { (error) in
            self.showAlertView(title: "Error", msg: error!)
        }
    }
}

//MARK: - TEXT FIELD DELEGATES
extension SignUpVC : UITextFieldDelegate {
   
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.nameTxtFld {
            let allowedCharacter = CharacterSet.letters
            let allowedCharacter1 = CharacterSet.whitespaces
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacter.isSuperset(of: characterSet) || allowedCharacter1.isSuperset(of: characterSet)
        }
        else {
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}






