//
//  AuthService.swift
//  Onboading
//
//  Created by 쩡화니 on 7/21/24.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn // For Google SignIn
import AuthenticationServices // For Apple SignIn
import CryptoKit // For Apple SignIn
import CNNetwork
import Common
import Auth
import Dependencies

protocol AuthServiceType {
  func googleSignIn() async throws
  func googleSignOut() async throws
  func appleSignIn() async throws
  func appleSignOut() async throws
}

struct AuthServiceDependencyKey: DependencyKey {
  static let liveValue: AuthServiceType = AuthServiceImpl.shared
  static let testValue: AuthServiceType = AuthServiceStub()
}

enum AuthServiceError: Error {
    case tokenStorageFailed
}

extension DependencyValues {
  var authService: AuthServiceType {
    get { self[AuthServiceDependencyKey.self] }
    set { self[AuthServiceDependencyKey.self] = newValue }
  }
}


final class AuthServiceStub: AuthServiceType {
  func googleSignIn() {
    
  }
  
  func googleSignOut() {
    
  }
  
  func appleSignIn() {
    
  }
  
  func appleSignOut() {
    
  }
}

final class AuthServiceImpl: NSObject {
  
  private var network: CNNetwork.Network<CNNetwork.AuthAPI>
  private let tokenManager = TokenManager.shared
  
  // Unhashed nonce.
  fileprivate var currentNonce: String?
  
  private override init() {
    network = .init()
  }
  
  /// Firebase 인증 서버에 signIn 요청을 보냅니다.
  private func signInWithFirebase(using credential: FirebaseAuth.AuthCredential) async throws {
    
    let authResult = try await FirebaseAuth.Auth.auth().signIn(with: credential)
    
    let idToken = try await authResult.user.getIDToken()
    
    let jwtToken = try await signInWithCNAuthServer(using: idToken)
    
    try await MainActor.run {
      guard tokenManager.setToken(jwtToken) != nil else {
        throw AuthServiceError.tokenStorageFailed
      }
    }
  }
  
  /// 쿡나우 인증 서버에 signIn 요청을 보냅니다.
  private func signInWithCNAuthServer(using idToken: String) async throws -> JWTToken {
    try await withCheckedThrowingContinuation { continuation in
      network.responseData(.signIn(.init(idToken)), SignInDTO.Response.self) { result in
        switch result {
        case .success(let res):
          let jwtToken = JWTToken.init(accessToken: res.accessToken, refreshToken: res.refreshToken)
          continuation.resume(returning: jwtToken)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  // TODO: 액세스 토큰 유효성 검증
  private func checkAccessTokenWithCNAuthServer(using token: String) async throws -> Bool {
    try await withCheckedThrowingContinuation { continuation in
      
    }
  }
  
  private func signOutWithCNAuthServer() async throws {
    try await withCheckedThrowingContinuation { continuation in
      network.responseData(.signOut, SignOutDTO.Response.self) { result in
        switch result {
        case .success(let res):
          continuation.resume()
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

extension AuthServiceImpl: AuthServiceType {
  
  static let shared: AuthServiceType = AuthServiceImpl()
  
  func googleSignIn() async throws {
    
    
    // As you’re not using view controllers to retrieve the presentingViewController, access it through
    // the shared instance of the UIApplication
    guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
    guard let rootViewController = await windowScene.windows.first?.rootViewController else { return }
    
    guard let clientID = FirebaseApp.app()?.options.clientID else { return }
    
    // Create Google Sign In configuration object.
    let config = GIDConfiguration(clientID: clientID) // GoogleSignIn
    
    GIDSignIn.sharedInstance.configuration = config
    // Start the sign in flow!
    
    let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
    
    guard let idToken = result.user.idToken?.tokenString else {
      //      ("Error during Google Sign-In authentication, \(String(describing: error))")
      return
    }
    
    let credential = GoogleAuthProvider.credential(
      withIDToken: idToken,
      accessToken: result.user.accessToken.tokenString
    )
    
    // Authenticate with Firebase
    try await signInWithFirebase(using: credential)
  }
  
  func googleSignOut() {
    let firebaseAuth = Auth.auth()
    do {
      try firebaseAuth.signOut()
      GIDSignIn.sharedInstance.signOut()
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
    }
  }
  
  func appleSignIn() {
    startSignInWithAppleFlow()
  }
  
  func appleSignOut() {
    
  }
}

/***
 사용자를 Apple 계정에 로그인 한 다음 Apple의 응답에서 `ID 토큰`을 사용해 Firebase `AuthCredential`객체를 만듭니다.
 ***/
private extension AuthServiceImpl {
  
  /// 모든 로그인 요청에 대해 임의의 문자열("nonce")을 생성하여
  /// 앱의 인증 요청에 대한 응답으로 특별히 부여된 ID 토큰을 확인하는 데 사용합니다.
  /// 이 단계는 리플레이 공격을 방지하는 데 중요합니다.
  func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
      fatalError(
        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
      )
    }
    
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    
    let nonce = randomBytes.map { byte in
      // Pick a random character from the set, wrapping around if needed.
      charset[Int(byte) % charset.count]
    }
    
    return String(nonce)
  }
  
  /// 로그인 요청과 함께 nonce의 SHA256 해시를 보내면 Apple이 응답에서 변경하지 않고 전달합니다.
  /// Firebase는 원래 nonce를 해싱하고 Apple이 전달한 값과 비교하여 응답을 검증합니다.
  func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      String(format: "%02x", $0)
    }.joined()
    
    return hashString
  }
  
  
  func startSignInWithAppleFlow() {
    let nonce = randomNonceString()
    currentNonce = nonce
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email] // 이름과 email요청
    request.nonce = sha256(nonce)
    
    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    authorizationController.delegate = self
    authorizationController.presentationContextProvider = self
    authorizationController.performRequests()
  }
}

extension AuthServiceImpl: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    // Retrieve the window to present the Apple Sign-In flow
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      fatalError("Unable to retrieve window scene")
    }
    guard let window = windowScene.windows.first else {
      fatalError("Unable to retrieve window")
    }
    return window
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      guard let nonce = currentNonce else {
        fatalError("Invalid state: A login callback was received, but no login request was sent.")
      }
      guard let appleIDToken = appleIDCredential.identityToken else {
        print("Unable to fetch identity token")
        return
      }
      guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
        print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        return
      }
      // Initialize a Firebase credential, including the user's full name.
      let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                     rawNonce: nonce,
                                                     fullName: appleIDCredential.fullName)
      
      // Sign in with Firebase. (Used Task for Bridging Sync and Async)
      Task {
        try await signInWithFirebase(using: credential)
      }
    }
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
    print("Sign in with Apple errored: \(error)")
  }
}
