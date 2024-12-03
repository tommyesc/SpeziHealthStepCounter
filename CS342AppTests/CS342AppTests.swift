//
// This source file is part of the CS342 App based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@testable import CS342App
import XCTest


class CS342AppTests: XCTestCase {
    @MainActor
    func testContactsCount() throws {
        XCTAssertEqual(Contacts(presentingAccount: .constant(true)).contacts.count, 1)
    }
}
