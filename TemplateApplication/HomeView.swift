//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import SpeziAccount
import SwiftUI


struct HomeView: View {
    enum Tabs: String {
        case schedule
        case contact
    }

    @AppStorage(StorageKeys.homeTabSelection) private var selectedTab = Tabs.schedule
    @AppStorage(StorageKeys.tabViewCustomization) private var tabViewCustomization = TabViewCustomization()

    @State private var presentingAccount = false
    @State private var showingStepCount = false

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                Tab("Schedule", systemImage: "list.clipboard", value: .schedule) {
                    ScheduleView(presentingAccount: $presentingAccount)
                }
                .customizationID("home.schedule")
                
                Tab("Contacts", systemImage: "person.fill", value: .contact) {
                    Contacts(presentingAccount: $presentingAccount)
                }
                .customizationID("home.contacts")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: StepCountView()) {
                        Image(systemName: "figure.walk")
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tabViewCustomization($tabViewCustomization)
            .sheet(isPresented: $presentingAccount) {
                AccountSheet(dismissAfterSignIn: false)
            }
            .accountRequired(!FeatureFlags.disableFirebase && !FeatureFlags.skipOnboarding) {
                AccountSheet()
            }
        }
    }
}


#if DEBUG
#Preview {
    var details = AccountDetails()
    details.userId = "lelandstanford@stanford.edu"
    details.name = PersonNameComponents(givenName: "Leland", familyName: "Stanford")
    
    return HomeView()
        .previewWith(standard: TemplateApplicationStandard()) {
            TemplateApplicationScheduler()
            AccountConfiguration(service: InMemoryAccountService(), activeDetails: details)
        }
}
#endif
