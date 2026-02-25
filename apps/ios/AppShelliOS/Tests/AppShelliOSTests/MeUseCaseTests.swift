import XCTest
@testable import AppShelliOS

@MainActor
final class MeUseCaseTests: XCTestCase {
    func testLoadMeRootDataSuccess() async {
        let appState = makeAppState()

        await appState.loadMeRootData()

        XCTAssertNotNil(appState.meProfile)
        XCTAssertFalse(appState.messageList.isEmpty)
        XCTAssertFalse(appState.exchangeRates.isEmpty)
        XCTAssertNil(appState.errorMessage(.meRoot))
    }

    func testLoadMeRootDataFailureSetsError() async {
        let appState = makeAppState(.error)

        await appState.loadMeRootData()

        XCTAssertNotNil(appState.errorMessage(.meRoot))
    }

    func testLoadMessagesAppendMergesWithoutDuplicates() async {
        let appState = makeAppState()

        await appState.loadMessages(page: 1, append: false)
        let firstCount = appState.messageList.count
        await appState.loadMessages(page: 2, append: true)

        XCTAssertEqual(firstCount, appState.messageList.count)
        XCTAssertNil(appState.errorMessage(.meMessageList))
    }

    func testMarkMessageReadSuccess() async {
        let appState = makeAppState()

        await appState.markMessageRead(id: "1")

        XCTAssertNil(appState.errorMessage(.meMessageRead))
    }

    func testMarkMessageReadFailureShowsToast() async {
        let appState = makeAppState(.error)

        await appState.markMessageRead(id: "1")

        XCTAssertEqual(appState.toast?.message, "Failed to mark as read")
        XCTAssertNotNil(appState.errorMessage(.meMessageRead))
    }

    func testMarkAllMessagesReadSuccess() async {
        let appState = makeAppState()

        await appState.markAllMessagesRead()

        XCTAssertEqual(appState.toast?.message, "Marked all as read")
        XCTAssertNil(appState.errorMessage(.meMessageReadAll))
    }

    func testCreateAddressBookSuccess() async {
        let appState = makeAppState()
        await appState.loadAddressBooks()
        let oldCount = appState.addressBooks.count

        let ok = await appState.createAddressBook(
            name: "new",
            walletAddress: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            chainType: "EVM"
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(appState.addressBooks.count, oldCount + 1)
    }

    func testCreateAddressBookFailure() async {
        let appState = makeAppState(.error)

        let ok = await appState.createAddressBook(
            name: "new",
            walletAddress: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            chainType: "EVM"
        )

        XCTAssertFalse(ok)
        XCTAssertEqual(appState.toast?.message, "Address BookAddFailed")
        XCTAssertNotNil(appState.errorMessage(.meAddressbookCreate))
    }

    func testUpdateAddressBookSuccess() async {
        let appState = makeAppState()
        await appState.loadAddressBooks()
        guard let first = appState.addressBooks.first else {
            return XCTFail("missing addressbook")
        }

        let ok = await appState.updateAddressBook(
            id: String(first.id ?? 1),
            name: "updated",
            walletAddress: first.walletAddress ?? "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            chainType: "EVM"
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(appState.toast?.message, "Address book updated successfully")
    }

    func testDeleteAddressBookSuccessRemovesItem() async {
        let appState = makeAppState()
        await appState.loadAddressBooks()
        guard let first = appState.addressBooks.first, let id = first.id else {
            return XCTFail("missing addressbook")
        }

        await appState.deleteAddressBook(id: String(id))

        XCTAssertFalse(appState.addressBooks.contains(where: { $0.id == id }))
        XCTAssertEqual(appState.toast?.message, "Address BookDeleteSucceeded")
    }

    func testUpdateAvatarFailureUsesSimplifiedError() async {
        let appState = makeAppState(.error)

        await appState.updateAvatar(fileData: Data([1, 2, 3]), fileName: "a.jpg", mimeType: "image/jpeg")

        XCTAssertNotNil(appState.errorMessage(.meProfileAvatar))
        XCTAssertNotNil(appState.toast?.message)
    }

    func testLoadExchangeRatesFailureSetsError() async {
        let appState = makeAppState(.error)

        await appState.loadExchangeRates()

        XCTAssertNotNil(appState.errorMessage(.meSettingsRates))
    }
}
