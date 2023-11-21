import Foundation

let accessKeyString = "SEU86dDW3Vi-KlxqoJrqcUWfc8vt0HxNuxuyUfnUJyc"
let secretKeyString = "a5FllIZUZDByz-kVOiAwMMqEJ30aZwf5D25eqJQVfAU"
let redirectURIString = "urn:ietf:wg:oauth:2.0:oob"
let accessScopeString = "public+read_user+write_likes"
/// https://api.unsplash.com/
let defaultBaseURLString = "https://api.unsplash.com/"
/// https://unsplash.com/oauth/authorize
let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
/// https://unsplash.com/oauth/token
let unsplashTokenURLString = "https://unsplash.com/oauth/token"

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURL: String
    let authURLString: String
    
    init(accessKey: String, secretKey: String, redirectURI: String, accessScope: String, authURLString: String, defaultBaseURL: String) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.redirectURI = redirectURI
        self.accessScope = accessScope
        self.defaultBaseURL = defaultBaseURL
        self.authURLString = authURLString
    }
    
    static var standard: AuthConfiguration {
        return AuthConfiguration(accessKey: accessKeyString,
                                 secretKey: secretKeyString,
                                 redirectURI: redirectURIString,
                                 accessScope: accessScopeString,
                                 authURLString: unsplashAuthorizeURLString,
                                 defaultBaseURL: defaultBaseURLString)
    }
}
