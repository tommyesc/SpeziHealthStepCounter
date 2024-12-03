//
// This source file is part of the CS342 App based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import SpeziAccount
import SpeziScheduler
import SpeziSchedulerUI
import SpeziViews
import SwiftUI

struct ScheduleView: View {
    @Environment(Account.self) private var account: Account?
    @Environment(CS342AppScheduler.self) private var scheduler: CS342AppScheduler

    @State private var presentedEvent: Event?
    @Binding private var presentingAccount: Bool

    
    var body: some View {
        @Bindable var scheduler = scheduler

        NavigationStack {
            TodayList { event in
                InstructionsTile(event) {
                    EventActionButton(event: event, "Start Questionnaire") {
                        presentedEvent = event
                    }
                }
            }
                .navigationTitle("Schedule")
                .viewStateAlert(state: $scheduler.viewState)
                .sheet(item: $presentedEvent) { event in
                    EventView(event)
                }
                .toolbar {
                    if account != nil {
                        AccountButton(isPresented: $presentingAccount)
                    }
                }
        }
    }
    
    
    init(presentingAccount: Binding<Bool>) {
        self._presentingAccount = presentingAccount
    }
}


#if DEBUG
#Preview("ScheduleView") {
    @Previewable @State var presentingAccount = false

    ScheduleView(presentingAccount: $presentingAccount)
        .previewWith(standard: CS342AppStandard()) {
            Scheduler()
            CS342AppScheduler()
            AccountConfiguration(service: InMemoryAccountService())
        }
}
#endif