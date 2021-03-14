//
//  LoginViewController.swift
//  Messenger
//
//  Created by JEONGSEOB HONG on 2021/03/04.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLogInButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup loginViewController configure
        title = String(describing: type(of: self))
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        
        // 로그인 되었다면 로그인 화면 dismiss. NotificationCenter에서 항시 감시
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,
                                                               object: nil,
                                                               queue: .main
        ) {
            [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLogInButton)
        
        // Add action
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        // Add delegate
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let size = scrollView.width / 3
        
        scrollView.frame = view.bounds
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        facebookLoginButton.frame = CGRect(x: 30,
                                           y: loginButton.bottom + 10,
                                           width: scrollView.width - 60,
                                           height: 52)
        googleLogInButton.frame = CGRect(x: 30,
                                         y: facebookLoginButton.bottom + 10,
                                         width: scrollView.width - 60,
                                         height: 52)
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    // MARK: - 로그인 버튼 클릭 method
    @objc private func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        // 프로그래스 아이콘 표시
        spinner.show(in: view)
        
        // 직접 등록한 유저로그인처리
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            
            // 프로그래스 아이콘 비표시
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let _ = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            // email로 유저정보 긁어오기.  유저 정보는 safeEmail를 key값으로 쓰고있다.
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else { return }
                    
                    // UserDefaults에 로그인한 유저의 name 정보 캐싱
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    
                case .failure(let error):
                    print("Failed to read data with error \(error)")
                }
            })
            
            // UserDefaults에 로그인한 유저의 email 정보 캐싱
            UserDefaults.standard.set(email, forKey: "email")
            
            // 로그인화면 제거
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - 상단부 등록버튼 클릭 method
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // email password 유효성검사 alert표시
    private func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

// MARK: - Facebook SNS이용한 로그인
extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    // 페이스북을 통한 로그인 메인
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        // 페이스북 아이디 비밀번호로 로그인 후, 성공된다면 허가토큰?을 받는다.
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        
        // 페이스북의 유저 정보 취득 준비
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        // 페이스북의 유저 정보 취득 요청
        facebookRequest.start { _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureURL = data["url"] as? String else {
                print ("Failed to get email and name from fb result")
                return
            }
            
            // email, name 정보 UserDefaults에 캐싱
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            // Firebase - Realtime Database에 유저존재 확인
            DatabaseManager.shared.checkUserExists(withEmail: email) { exists in
                // 유저정보가 없을경우(신규)
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    
                    // Firebase - Realtime Database 유저등록
                    DatabaseManager.shared.insertUser(withChatAppUser: chatUser) { success in
                        if success {
                            guard let url = URL(string: pictureURL) else { return }
                            
                            // Downloading data from facebook image
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                guard let data = data else { return }
                                
                                let fileName = chatUser.profilePictureFileName
                                // Firebase - Storage 유저이미지 등록
                                StorageManager.shared.uploadProfilePicture(data: data, fileName: fileName) { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        // url로 받아지기 때문에 재사용을 위해 url정보 캐싱
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                    case .failure(let error):
                                        print("Storage manager error: ", error)
                                    }
                                }
                            }).resume() // URLSession 이상있을때 멈추기
                        }
                    }
                }
            }
            
            // Facebook 허가권 받기
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            //  Facebook 허가로 firebase 로그인 및 Authentication 등록
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may be needed - \(error)")
                    }
                    return
                }
                // 로그인화면 dismiss
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
