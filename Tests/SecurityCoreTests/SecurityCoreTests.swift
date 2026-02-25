import XCTest
import Web3Core
import CoreRuntime
@testable import SecurityCore

final class SecurityCoreTests: XCTestCase {
    
    var keyStore: KeyStoreService!
    var signer: TransactionSigner!
    
    override func setUp() {
        super.setUp()
        keyStore = KeyStoreService()
        signer = TransactionSigner()
    }
    
    override func tearDown() {
        keyStore = nil
        signer = nil
        super.tearDown()
    }

    func testCreateAccount() throws {
        let address: String
        do {
            address = try keyStore.createAccount()
        } catch {
            throw XCTSkip("Keychain unavailable, skipping this test case: \(error)")
        }
        XCTAssertFalse(address.isEmpty, "Created address should not be empty")
        XCTAssertTrue(address.hasPrefix("0x"), "Address should start with 0x")
        XCTAssertEqual(address.count, 42, "Address should be 42 characters long")
    }
    
    func testSignTransaction() throws {
        // Generate a temporary private key for testing
        let privateKey = SECP256K1.generatePrivateKey()!
        let fromAddress = Utilities.publicToAddress(Utilities.privateToPublic(privateKey)!)!.address
        
        // Construct a dummy transaction request
        let req = SendTxRequest(
            source: .system(name: "test"),
            from: Address(fromAddress),
            to: Address("0x742d35Cc6634C0532925a3b844Bc454e4438f44e"),
            value: "1000000000000000000", // 1 ETH
            data: nil,
            chainId: 1
        )
        
        let signedTx = try signer.signLegacyTransaction(
            req,
            privateKey: privateKey,
            nonce: "0",
            gasPrice: "20000000000",
            gasLimit: "21000"
        )
        
        XCTAssertFalse(signedTx.rawTransactionHex.isEmpty)
        XCTAssertFalse(signedTx.txHashHex.isEmpty)
        XCTAssertTrue(signedTx.rawTransactionHex.hasPrefix("0x"))
    }
}
