# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Llinks is an iOS application built with SwiftUI and SwiftData. It's a native iOS app targeting iOS 26.2+ using Xcode 26.2.

**Bundle Identifier**: `squad52.dev.Llinks`
**Development Team**: `2NXN9F6VAY`
**Swift Version**: 5.0

## Build and Test Commands

### Building the app
```bash
# Build for iOS device
xcodebuild -project Llinks.xcodeproj -scheme Llinks -configuration Debug build

# Build for iOS Simulator (specify a destination)
xcodebuild -project Llinks.xcodeproj -scheme Llinks -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Running tests
```bash
# Run unit tests
xcodebuild test -project Llinks.xcodeproj -scheme Llinks -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test suite
xcodebuild test -project Llinks.xcodeproj -scheme Llinks -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LlinksTests

# Run UI tests
xcodebuild test -project Llinks.xcodeproj -scheme Llinks -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LlinksUITests
```

### Opening in Xcode
```bash
open Llinks.xcodeproj
```

## Architecture

### SwiftData Integration
The app uses SwiftData for persistence with a `ModelContainer` configured in `LlinksApp.swift`. The container is shared across the app via the `.modelContainer()` modifier.

- **Schema definition**: Defined in `LlinksApp.swift:13-16` with registered models
- **Persistence**: Stored on disk (not in-memory) via `ModelConfiguration`
- **Model context**: Available via `@Environment(\.modelContext)` in views
- **Queries**: Use `@Query` property wrapper to fetch data reactively

### Data Models
Models are Swift classes marked with `@Model` macro (SwiftData):
- `Item.swift`: Example model with `timestamp` property
- Models must be registered in the schema in `LlinksApp.swift`

### View Structure
- **App entry**: `LlinksApp.swift` - defines the main app structure and SwiftData container
- **Main view**: `ContentView.swift` - uses `NavigationSplitView` with master-detail layout
- The app follows SwiftUI's declarative view pattern

### Swift Concurrency
The project uses modern Swift concurrency features:
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` - views default to MainActor isolation

## Code Conventions

### SwiftData Model Pattern
When creating new models:
1. Import `Foundation` and `SwiftData`
2. Mark class with `@Model` macro
3. Register in schema in `LlinksApp.swift:14-15`
4. Use `@Query` in views to fetch data
5. Use `modelContext.insert()` to add, `modelContext.delete()` to remove

### View Pattern
Views should:
- Access model context via `@Environment(\.modelContext)`
- Use `@Query` for reactive data fetching
- Wrap mutations in `withAnimation` for smooth transitions
- Include `#Preview` for Xcode preview support
