// Prints the base64 public key of the Sparkle EdDSA private key file given as the only
// argument (base64 of the 32-byte seed), so scripts/release.sh can compare it with the
// app's SUPublicEDKey before signing anything with it.
import CryptoKit
import Foundation

let path = CommandLine.arguments[1]
guard
    let text = try? String(contentsOfFile: path, encoding: .utf8),
    let seed = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)),
    let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: seed)
else {
    FileHandle.standardError.write(Data("\(path) is not a base64 Ed25519 seed\n".utf8))
    exit(1)
}
print(key.publicKey.rawRepresentation.base64EncodedString())
