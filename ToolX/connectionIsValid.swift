import AppKit
import Foundation

func connectionIsValid(connection: NSXPCConnection) -> Bool {

  let checker = CodesignChecker()
  var localCertificates: [SecCertificate] = []
  var remoteCertificates: [SecCertificate] = []
  let pid = connection.processIdentifier

  do {
    localCertificates = try checker.getCertificatesSelf()
    remoteCertificates = try checker.getCertificates(forPID: pid)
  } catch let error as CodesignCheckerError {
    NSLog(CodesignCheckerError.handle(error: error))
  } catch let error {
    NSLog("Something unexpected happened: \(error.localizedDescription)")
  }

  NSLog("Local certificates: \(localCertificates)")
  NSLog("Remote certificates: \(remoteCertificates)")

  if !remoteCertificates.isEmpty {

    let policy = SecPolicyCreateBasicX509()

    var optionalTrust: SecTrust?
    let status = SecTrustCreateWithCertificates(
      remoteCertificates as AnyObject,
      policy,
      &optionalTrust)
    guard status == errSecSuccess else {
      NSLog("failed evaluating trust")
      return false
    }

    let trust = optionalTrust!
    var secResult = SecTrustResultType.invalid
    SecTrustGetTrustResult(trust, &secResult)
    if secResult == .proceed || secResult == .unspecified {
      let names = remoteCertificates.map { commonName(cert: $0) }
      let validCert1 = [
        "Apple Development: ragnar.rova@gmail.com (U34QC433V8)",
        "Apple Worldwide Developer Relations Certification Authority", "Apple Root CA",
      ]

      if names == validCert1 {
        NSLog("Found a valid client (fingerprint #1)")
        return true
      }
      let validCert2 = [
        "Developer ID Application: Ragnar Rova (3563RJWBQP)",
        "Developer ID Certification Authority", "Apple Root CA",
      ]
      if names == validCert2 {
        NSLog("Found a valid client (fingerprint #2)")
        return true
      }
      return false
    } else {
      NSLog("Got invalid secResult: \(secResult.rawValue)")
    }
    return false
  }

  return false
}

class ToolXDelegate: NSObject, NSXPCListenerDelegate {
  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection)
    -> Bool
  {
    if !connectionIsValid(connection: newConnection) {

      NSLog("Codesign certificate validation failed")

      return false
    }
    let exportedObject = ToolXService()
    newConnection.exportedInterface = NSXPCInterface(with: ToolXProtocol.self)
    newConnection.exportedObject = exportedObject
    newConnection.resume()
    return true
  }
}

func commonName(cert: SecCertificate) -> String {
  var commonName: CFString?
  SecCertificateCopyCommonName(cert, &commonName)
  return commonName as String? ?? ""
}
