import XCTest
import CoreRuntime
@testable import SecurityCore

final class TxConfirmationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.reset()
    }

    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    func testTransactionReceiptParsesStatusAndBlockNumber() async throws {
        URLProtocolStub.responses = [
            .success(
                [
                    "jsonrpc": "2.0",
                    "id": 1,
                    "result": [
                        "transactionHash": "0xabc",
                        "blockNumber": "0x10",
                        "status": "0x1",
                    ],
                ]
            ),
        ]

        let client = try makeClient()
        let receipt = try await client.transactionReceipt(txHash: "0xabc")

        XCTAssertEqual(receipt?.txHash, "0xabc")
        XCTAssertEqual(receipt?.blockNumber, 16)
        XCTAssertEqual(receipt?.status, 1)
    }

    func testWaitForTransactionConfirmationPendingThenSuccess() async throws {
        URLProtocolStub.responses = [
            .success(
                [
                    "jsonrpc": "2.0",
                    "id": 1,
                    "result": NSNull(),
                ]
            ),
            .success(
                [
                    "jsonrpc": "2.0",
                    "id": 1,
                    "result": [
                        "transactionHash": "0xdef",
                        "blockNumber": "0x2a",
                        "status": "0x1",
                    ],
                ]
            ),
        ]

        let client = try makeClient()
        let confirmation = try await client.waitForTransactionConfirmation(
            WaitTxConfirmationRequest(
                txHash: "0xdef",
                chainId: 1029,
                timeoutSeconds: 1,
                pollIntervalSeconds: 0.01
            )
        )

        XCTAssertEqual(confirmation.txHash, "0xdef")
        XCTAssertEqual(confirmation.blockNumber, 42)
        XCTAssertEqual(confirmation.status, 1)
    }

    func testWaitForTransactionConfirmationTimeout() async throws {
        URLProtocolStub.fallback = .success(
            [
                "jsonrpc": "2.0",
                "id": 1,
                "result": NSNull(),
            ]
        )

        let client = try makeClient()

        do {
            _ = try await client.waitForTransactionConfirmation(
                WaitTxConfirmationRequest(
                    txHash: "0x123",
                    chainId: 1029,
                    timeoutSeconds: 0.08,
                    pollIntervalSeconds: 0.01
                )
            )
            XCTFail("expected timeout")
        } catch let error as EVMRPCError {
            switch error {
            case let .transactionConfirmationTimeout(txHash):
                XCTAssertEqual(txHash, "0x123")
            default:
                XCTFail("unexpected error: \(error)")
            }
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    private func makeClient() throws -> EVMRPCClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        return try EVMRPCClient(chainId: 1029, session: session)
    }
}

private final class URLProtocolStub: URLProtocol {
    enum StubResult {
        case success([String: Any])
        case failure(Error)
    }

    static var responses: [StubResult] = []
    static var fallback: StubResult?
    private static var responseIndex = 0
    private static let lock = NSLock()

    static func reset() {
        lock.lock()
        responses = []
        fallback = nil
        responseIndex = 0
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.absoluteString.contains("rpc.bt.io") == true
            || request.url?.absoluteString.contains("pre-rpc.bt.io") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let result: StubResult? = {
            Self.lock.lock()
            defer { Self.lock.unlock() }
            if Self.responseIndex < Self.responses.count {
                let item = Self.responses[Self.responseIndex]
                Self.responseIndex += 1
                return item
            }
            return Self.fallback
        }()

        guard let result else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        switch result {
        case let .success(json):
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: [])
                let response = HTTPURLResponse(
                    url: request.url ?? URL(string: "https://pre-rpc.bt.io/")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
