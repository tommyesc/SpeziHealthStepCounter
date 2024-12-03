//
//  StepCountView.swift
//  TemplateApplication
//
//  Created by thomas escudero on 11/30/24.
//

import Foundation
import SwiftUI
import SpeziHealthKit
import HealthKit

struct StepCountCard: View {
    let stepCount: Double
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.walk")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Steps Today")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("\(Int(stepCount))")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
        .padding()
    }
}

struct StepCountActionButtons: View {
    let isLoading: Bool
    let onRefresh: () -> Void
    let onAddTestData: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)
            
            #if DEBUG
            Button(action: onAddTestData) {
                Label("Add Test Data", systemImage: "plus.circle")
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)
            #endif
        }
    }
}

struct StepCountView: View {
    @Environment(HealthKit.self) private var healthKit
    @State private var stepCount: Double = 0
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    private let healthStore = HKHealthStore()

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                StepCountCard(stepCount: stepCount, errorMessage: errorMessage)
                
                StepCountActionButtons(
                    isLoading: isLoading,
                    onRefresh: fetchStepCount,
                    onAddTestData: addTestData
                )
            }
            
            Spacer()
        }
        .navigationTitle("Step Count")
        .onAppear {
            requestAuthorization()
        }
    }

    private func fetchStepCount() {
        isLoading = true
        errorMessage = nil
        
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device."
            isLoading = false
            return
        }

        // Define the quantity type for step count
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            errorMessage = "Unable to create step count quantity type."
            isLoading = false
            return
        }

        // Define the date range (e.g., today)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        // Create the query
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch step count: \(error.localizedDescription)"
                    return
                }

                guard let sum = result?.sumQuantity() else {
                    self.stepCount = 0.0
                    self.errorMessage = "No steps recorded yet today. Start walking or use the Health app to add steps."
                    return
                }

                // Get the total steps
                self.stepCount = sum.doubleValue(for: HKUnit.count())
                self.errorMessage = nil
            }
        }

        // Execute the query
        healthStore.execute(query)
    }

    private func requestAuthorization() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            errorMessage = "Step count type is not available."
            return
        }

        let typesToRead: Set<HKSampleType> = [stepType]
        let typesToShare: Set<HKSampleType> = [stepType]
        
        // Check current authorization status
        let authStatus = healthStore.authorizationStatus(for: stepType)
        print("Current authorization status: \(authStatus.rawValue)")
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
                print("Authorization request completed")
                // Verify new authorization status
                let newStatus = healthStore.authorizationStatus(for: stepType)
                print("New authorization status: \(newStatus.rawValue)")
                await MainActor.run {
                    fetchStepCount()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to get HealthKit authorization: \(error.localizedDescription)"
                }
                print("Authorization error: \(error)")
            }
        }
    }
}

#if DEBUG
extension StepCountView {
    private func addTestData() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Check authorization status before proceeding
        let authStatus = healthStore.authorizationStatus(for: stepType)
        print("Authorization status for adding test data: \(authStatus.rawValue)")
        
        guard authStatus == .sharingAuthorized else {
            print("Need to request authorization first")
            requestAuthorization()
            return
        }
        
        // Create a random number of steps between 1000 and 10000
        let stepsCount = Double(Int.random(in: 1000...10000))
        let stepsQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: stepsCount)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let sample = HKQuantitySample(type: stepType,
                                    quantity: stepsQuantity,
                                    start: startOfDay,
                                    end: now)
        
        healthStore.save(sample) { (success, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to save test data: \(error.localizedDescription)")
                    self.errorMessage = "Failed to save test data: \(error.localizedDescription)"
                } else {
                    print("Successfully saved \(Int(stepsCount)) test steps")
                    // Wait a brief moment before fetching updated data
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.fetchStepCount()
                    }
                }
                self.isLoading = false
            }
        }
    }
}
#endif

struct StepCountView_Previews: PreviewProvider {
    static var previews: some View {
        StepCountView()
            .environment(HealthKit())
    }
}
