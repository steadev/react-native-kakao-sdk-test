extension Encodable {
    
    var toDictionary : [String: Any]? {
        guard let object = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: object, options: []) as? [String:Any] else { return nil }
        return dictionary
    }
}

enum TokenStatus: String {
    case LOGIN_NEEDED
    case ERROR
    case SUCCEED
}

@objc(KakaoSdk)
class KakaoSdk: NSObject {

  public override init() {
        let appKey: String? = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String
        KakaoSDK.initSDK(appKey: appKey!)
  }

  @objc(initializeKakao:rejecter:)
  func initializeKakao(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      tokenAvailability { (status: TokenStatus) in
          resolve([
              "status": status.rawValue
          ])
      }
    }
  }

  @objc(kakaoLogin:rejecter:)
  public func kakaoLogin(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      // 카카오톡 설치 여부 확인
      // if kakaotalk app exists, login with app. else, login with web
      if (UserApi.isKakaoTalkLoginAvailable()) {
          UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
              self.handleKakaoLoginResponse(resolve: resolve, reject: reject, oauthToken: oauthToken, error: error)
          }
      }
      else{
          UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
              self.handleKakaoLoginResponse(resolve: resolve, reject: reject, oauthToken: oauthToken, error: error)
          }
      }
    }
  }
  
  private func handleKakaoLoginResponse(resolve: @escaping RCTPromiseResolveBlock,reject: @escaping RCTPromiseRejectBlock, oauthToken: OAuthToken?, error: Error?) -> Void {
      if error != nil {
          reject("error")
      }
      else {
          resolve([
              "accessToken": oauthToken?.accessToken ?? "",
              "refreshToken": oauthToken?.refreshToken ?? ""
          ])
      }
  }
  
  @objc(kakaoLogout:rejecter:)
  public func kakaoLogout(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      UserApi.shared.logout {(error) in
          if let error = error {
              print(error)
              reject("error")
          }
          else {
              resolve()
          }
      }
    }
  }
  
  
  
  @objc(kakaoUnlink:rejecter:)
  public func kakaoUnlink(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      UserApi.shared.unlink {(error) in
          if let error = error {
              print(error)
              reject("error")
          }
          else {
              resolve()
          }
      }
    }
  }
  
  
  @objc(sendLinkFeed:rejecter:)
  public func sendLinkFeed(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      let title = "" //call.getString("title") ?? ""
      let description = "" //call.getString("description") ?? ""
      let imageUrl = "" // call.getString("imageUrl") ?? ""
      let imageLinkUrl = "" //call.getString("imageLinkUrl") ?? ""
      let buttonTitle = "" //call.getString("buttonTitle") ?? ""
      let imageWidth: Int?//call.getInt("imageWidth")
      let imageHeight: Int?//call.getInt("imageHeight")

      
      
      let link = Link(webUrl: URL(string:imageLinkUrl),
                      mobileWebUrl: URL(string:imageLinkUrl))

      let button = Button(title: buttonTitle, link: link)
      let content = Content(title: title,
                            imageUrl: URL(string:imageUrl)!,
                            imageWidth: imageWidth,
                            imageHeight: imageHeight,
                            description: description,
                            link: link)
      let feedTemplate = FeedTemplate(content: content, social: nil, buttons: [button])

      //메시지 템플릿 encode
      if let feedTemplateJsonData = (try? SdkJSONEncoder.custom.encode(feedTemplate)) {

      //생성한 메시지 템플릿 객체를 jsonObject로 변환
          if let templateJsonObject = SdkUtils.toJsonObject(feedTemplateJsonData) {
              LinkApi.shared.defaultLink(templateObject:templateJsonObject) {(linkResult, error) in
                  if let error = error {
                      print(error)
                      reject("error")
                  }
                  else {

                      //do something
                      guard let linkResult = linkResult else { return }
                      UIApplication.shared.open(linkResult.url, options: [:], completionHandler: nil)
                      
                      resolve()
                  }
              }
          }
      }
    }
  }

  @objc(getUserInfo:rejecter:)
  public func getUserInfo(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      UserApi.shared.me() {(user, error) in
          if let error = error {
              print(error)
              reject("me() failed.")
          }
          else {
              print("me() success.")
              resolve([
                  "value": user?.toDictionary as Any
              ])
          }
      }
    }
  }

  @objc(getFriendList:rejecter:)
  public func getFriendList(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      let offset = 0 // call.getInt("offset")
      let limit = 100 // call.getInt("limit")
      var order = Order.Asc
      // if (call.getString("order")?.uppercased() == "DESC") {
      //     order = Order.Desc
      // }
      TalkApi.shared.friends (
          offset:offset, limit:limit, order: order
      ) {(friends, error) in
          if let error = error {
              print(error)
              reject("getFriendList() failed.")
          }
          else {
              print("getFriendList() success")
              let friendList = friends?.toDictionary
              resolve([
                  "value": (friendList != nil) ? friendList!["elements"] as Any : [] as Any
              ])
          }
      }
    }
  }

  @objc(loginWithNewScopes:rejecter:)
  public func loginWithNewScopes(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) ->  Void {
    DispatchQueue.main.async {
      var scopes = [String]()
      // guard let tobeAgreedScopes = call.getArray("scopes", String.self) else {
      //     reject("scopes agree failed")
      //     return
      // }
      // for scope in tobeAgreedScopes {
      //     scopes.append(scope)
      // }
          
      if scopes.count == 0  {
          resolve()
          return
      }

      //필요한 scope으로 토큰갱신을 한다.
      UserApi.shared.loginWithKakaoAccount(scopes: scopes) { (_, error) in
          if let error = error {
              print(error)
              reject("scopes agree failed")
          }
          else {
              resolve()
          }

      }
    }
  }

  @objc(getUserScopes:rejecter:)
  public func getUserScopes(resolve: @escaping RCTPromiseResolveBlock,
          rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      UserApi.shared.scopes() { (scopeInfo, error) in
          if error != nil {
              reject("get kakao user scope failed : ")
          }
          else {
              let scopeInfoDict = scopeInfo?.toDictionary
              resolve([
                  "value": (scopeInfoDict != nil) ? scopeInfoDict!["scopes"] as Any : [] as Any
              ])
          }
      }
    }
  }

  private func tokenAvailability(completion: @escaping ((TokenStatus) -> Void)) -> Void {
    if (AuthApi.hasToken()) {
        UserApi.shared.accessTokenInfo { (_, error) in
            if let error = error {
                if let sdkError = error as? SdkError, sdkError.isInvalidTokenError() == true  {
                    completion(TokenStatus.LOGIN_NEEDED)
                }
                else {
                    //기타 에러
                    completion(TokenStatus.ERROR)
                }
            }
            else {
                //토큰 유효성 체크 성공(필요 시 토큰 갱신됨)
                completion(TokenStatus.SUCCEED)
            }
        }
    }
    else {
        completion(TokenStatus.LOGIN_NEEDED)
    }
  }
}
