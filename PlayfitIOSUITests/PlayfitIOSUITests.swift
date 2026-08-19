import XCTest

final class PlayfitIOSUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Launches with `-playfit-ui-testing`, which skips the network load and always
    /// lands on the intro screen (`playfit.intro.start`), or with `seeded: true`
    /// (`-playfit-ui-testing-seeded`), which marks onboarding complete in-memory and
    /// lands directly on the main tab bar with an empty pool/picks — both offline and
    /// deterministic, matching the pattern already used by the two smoke tests below.
    private func launch(seeded: Bool = false) {
        app.launchArguments = [
            seeded ? "-playfit-ui-testing-seeded" : "-playfit-ui-testing",
            "-UIAccessibilityReduceMotionEnabled", "YES",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()
    }

    func testLaunchReachesAUsableRootStateWithAccessibilitySettings() {
        launch()
        let identifiers = [
            "playfit.startup.loading",
            "playfit.startup.error",
            "playfit.intro.start",
            "playfit.main.tabs",
        ]

        let reachedRootState = waitUntil(timeout: 20) {
            identifiers.contains { self.app.descendants(matching: .any)[$0].exists }
        }

        XCTAssertTrue(reachedRootState, "The app did not expose a recognized root state")
    }

    func testPrimaryControlsMeetMinimumTapHeight() throws {
        launch()
        let reachedIntro = waitUntil(timeout: 20) {
            self.app.buttons["playfit.intro.start"].exists || self.app.tabBars.firstMatch.exists
        }
        try XCTSkipUnless(reachedIntro, "Account state did not expose intro or main tabs")

        if app.buttons["playfit.intro.start"].exists {
            XCTAssertGreaterThanOrEqual(app.buttons["playfit.intro.start"].frame.height, 44)
            XCTAssertGreaterThanOrEqual(app.buttons["playfit.intro.signin"].frame.height, 44)
        } else {
            XCTAssertGreaterThanOrEqual(app.tabBars.firstMatch.frame.height, 44)
        }
    }

    func testIntroControlsExposeDescriptiveAccessibilityLabels() throws {
        launch()
        let startButton = app.buttons["playfit.intro.start"]
        try XCTSkipUnless(waitUntil(timeout: 20) { startButton.exists }, "Intro screen did not appear")

        XCTAssertFalse(startButton.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(app.buttons["playfit.intro.signin"].label.localizedCaseInsensitiveContains("sign"))
    }

    // MARK: - Onboarding (reachable from Intro without seeding)

    func testOnboardingPlatformsStepReachableFromIntro() throws {
        launch()
        let startButton = app.buttons["playfit.intro.start"]
        try XCTSkipUnless(waitUntil(timeout: 20) { startButton.exists }, "Intro screen did not appear")

        startButton.tap()

        let platformsTitle = app.staticTexts["Where do you play?"]
        XCTAssertTrue(waitUntil(timeout: 10) { platformsTitle.exists }, "Onboarding did not reach the platforms step")
    }

    // MARK: - Auth sheet (reachable from Intro without seeding)

    func testAuthSheetReachableFromIntroAndOffersForgotPassword() throws {
        launch()
        let signInButton = app.buttons["playfit.intro.signin"]
        try XCTSkipUnless(waitUntil(timeout: 20) { signInButton.exists }, "Intro screen did not appear")

        signInButton.tap()

        let welcomeTitle = app.staticTexts["Welcome to Playfit"]
        XCTAssertTrue(waitUntil(timeout: 10) { welcomeTitle.exists }, "Sign-in sheet did not present the options view")

        let continueWithEmail = app.buttons["Continue with Email"]
        XCTAssertTrue(waitUntil(timeout: 5) { continueWithEmail.exists })
        continueWithEmail.tap()

        let forgotPassword = app.buttons["Forgot password?"]
        XCTAssertTrue(waitUntil(timeout: 5) { forgotPassword.exists }, "Forgot password control is missing from the sign-in form")
    }

    // MARK: - Main tabs (seeded, offline)

    func testMainTabsAreReachableWhenSeeded() throws {
        launch(seeded: true)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitUntil(timeout: 20) { tabBar.exists }, "Seeded launch did not reach the main tab bar")

        for label in ["Play Next", "Picks", "Taste", "Settings"] {
            XCTAssertTrue(tabBar.buttons[label].exists, "Missing tab bar item: \(label)")
        }
    }

    func testPicksEmptyStateShowsExpectedCopyWhenSeeded() throws {
        launch(seeded: true)
        let tabBar = app.tabBars.firstMatch
        try XCTSkipUnless(waitUntil(timeout: 20) { tabBar.exists }, "Seeded launch did not reach the main tab bar")

        tabBar.buttons["Picks"].tap()

        let emptyState = app.staticTexts["No saved picks yet"]
        XCTAssertTrue(waitUntil(timeout: 10) { emptyState.exists }, "Picks empty state copy did not appear")
    }

    func testTasteMenuNavigatesToMapAndTraitsListWhenSeeded() throws {
        launch(seeded: true)
        let tabBar = app.tabBars.firstMatch
        try XCTSkipUnless(waitUntil(timeout: 20) { tabBar.exists }, "Seeded launch did not reach the main tab bar")

        tabBar.buttons["Taste"].tap()

        let mapRow = app.staticTexts["Interactive Affinity Map"]
        let traitsRow = app.staticTexts["Traits List"]
        XCTAssertTrue(waitUntil(timeout: 10) { mapRow.exists }, "Missing Taste menu row: Interactive Affinity Map")
        XCTAssertTrue(traitsRow.exists, "Missing Taste menu row: Traits List")

        traitsRow.tap()
        let traitsDescription = app.staticTexts["An accessible text view of the evidence shown in the map."]
        XCTAssertTrue(waitUntil(timeout: 10) { traitsDescription.exists }, "Traits List screen did not open")

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(waitUntil(timeout: 10) { mapRow.exists }, "Did not return to the Taste menu")

        mapRow.tap()
        let mapDescription = app.staticTexts["Visual graph of your gaming traits."]
        XCTAssertTrue(waitUntil(timeout: 10) { mapDescription.exists }, "Interactive Affinity Map screen did not open")
    }

    func testSettingsMenuShowsExpectedSectionsWhenSeeded() throws {
        launch(seeded: true)
        let tabBar = app.tabBars.firstMatch
        try XCTSkipUnless(waitUntil(timeout: 20) { tabBar.exists }, "Seeded launch did not reach the main tab bar")

        tabBar.buttons["Settings"].tap()

        for label in ["App Appearance", "Your Platforms", "Data & Privacy"] {
            XCTAssertTrue(waitUntil(timeout: 10) { self.app.staticTexts[label].exists }, "Missing Settings row: \(label)")
        }

        app.staticTexts["App Appearance"].tap()
        for label in ["Light", "Dark", "System"] {
            XCTAssertTrue(waitUntil(timeout: 10) { self.app.staticTexts[label].exists }, "Missing appearance option: \(label)")
        }
    }

    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return condition()
    }
}
