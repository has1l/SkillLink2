//
//  OnboardingViewModel.swift
//  Llinks
//

import Foundation
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0

    init() {
        // Пустой инициализатор
    }
}
