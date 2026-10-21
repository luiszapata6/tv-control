import Foundation
import Security

enum IdentityError: Error { case badPem, badKey, keychain(OSStatus), notFound }

/// Turns the PEM certificate + key the Flutter app generated into a
/// SecIdentity for TLS, via this process's own keychain (iOS has no API to
/// pair a key and a certificate in memory).
enum TVIdentity {
    private static let tag = Data("com.luiszapata.tvcontrol.client-key".utf8)
    private static let label = "TV Control client"
    private static var cache: (pem: String, identity: SecIdentity)?
    private static let lock = NSLock()

    static func identity(for tv: SharedTV) throws -> SecIdentity {
        lock.lock()
        defer { lock.unlock() }
        if let c = cache, c.pem == tv.certificatePem { return c.identity }
        let certDer = try der(fromPem: tv.certificatePem)
        let keyDer = try der(fromPem: tv.privateKeyPem)
        if let found = findIdentity(certDer: certDer) {
            cache = (tv.certificatePem, found)
            return found
        }
        guard let cert = SecCertificateCreateWithData(nil, certDer as CFData) else { throw IdentityError.badPem }
        let attrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyDer as CFData, attrs as CFDictionary, &error) else {
            throw IdentityError.badKey
        }
        // Replace whatever an older pairing left behind.
        SecItemDelete([kSecClass as String: kSecClassKey, kSecAttrApplicationTag as String: tag] as CFDictionary)
        SecItemDelete([kSecClass as String: kSecClassCertificate, kSecAttrLabel as String: label] as CFDictionary)
        var status = SecItemAdd([
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: key,
            kSecAttrApplicationTag as String: tag,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ] as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else { throw IdentityError.keychain(status) }
        status = SecItemAdd([
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: cert,
            kSecAttrLabel as String: label,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ] as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else { throw IdentityError.keychain(status) }
        guard let identity = findIdentity(certDer: certDer) else { throw IdentityError.notFound }
        cache = (tv.certificatePem, identity)
        return identity
    }

    private static func findIdentity(certDer: Data) -> SecIdentity? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching([
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ] as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [SecIdentity] else { return nil }
        for identity in items {
            var cert: SecCertificate?
            if SecIdentityCopyCertificate(identity, &cert) == errSecSuccess, let cert,
               SecCertificateCopyData(cert) as Data == certDer {
                return identity
            }
        }
        return nil
    }

    static func der(fromPem pem: String) throws -> Data {
        let body = pem
            .components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") }
            .joined()
        guard let data = Data(base64Encoded: body), !data.isEmpty else { throw IdentityError.badPem }
        return data
    }
}
