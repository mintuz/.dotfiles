# Development Guidelines for Claude

## Core Philosophy

I follow Test-Driven Development (TDD) with a strong emphasis on behavior-driven testing and functional programming principles. All work should be done in small, incremental changes that maintain a working state throughout development.

## Quick Reference

**Key Principles:**

- Write tests first (TDD).
- Test behavior, not implementation.
- Avoid MVVM Design Patterns.
- App Intents Driven Development.

**Preferred Tools:**

- **Language**: Swift
- **UI**: SwiftUI
- **Database**: SwiftData
- **State Management**: Prefer SwiftUI state primitives.

**Preferred Libraries:**

- **Routing**: AppRouter - https://github.com/Dimillian/AppRouter
- **Networking**: Alamofire - https://github.com/Alamofire/Alamofire

## Architecture

### SwiftUI

**Avoid MVVM Design Patterns**
Keep it simple. I will tell you when I need to use MVVM. I would prefer by default if you use SwiftUI primitives for UI state. @State, @Binding, @Environment, etc.

**Colors**
Assume I have included a Colors.xcassets file in the project. Use it instead of creating your own colors.

Colors are based on the Tailwind CSS color palette. Make sure the combination of colors you use are accessible and contrast well.

```
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .foregroundStyle(Color.slate500)
            .background(Color("Slate100"))
    }
}
```

**Resources:**

- https://tailwindcss.com/docs/colors

### App Intent Driven Development

Define actions as app intents by default allowing them to be connected to any system-service in the future. Use the AppIntent Protocol.

**App Intent Example**

```
import AppIntents

struct CreateIntent: AppIntent {

  static let title = LocalizedStringResource("Add New Item")
  static let openAppWhenRun = true

  @Parameter(title: "Title")
  var title: String

  init() {}
  init(title: String) {
    self.title = title
  }

  @MainActor func perform() throws -> some IntentResult {
    /* Main body of the intent */
  }
}
```

**App Intent SwiftUI Usage Example**

```
Button(intent: CreateIntent(title: "New Item")) {
  Text("Add New Item")
}
```

**App Intent Dependency Injection**
The app intent may require access to a shared state between the app and the intent.

This can be achieved by using the AppDependencyManager within the Main struct of the app.

```
init() {
    _sessionManager = State(initialValue: SessionManager.shared)
    AppDependencyManager.shared.add(dependency: SessionManager.shared)
}
```

**Resources:**

- https://developer.apple.com/documentation/appintents
- https://www.avanderlee.com/swift/app-intent-driven-development

### Routing

Make use of AppRouter (https://github.com/Dimillian/AppRouter) for all navigation.

**Simple Navigation without Tabs**

```
import SwiftUI
import AppRouter

// 1. Define your destination and sheet types
enum Destination: DestinationType {
    case detail(id: String)
    case settings
    case profile(userId: String)
}

enum Sheet: SheetType {
    case compose
    case settings

    var id: Int { hashValue }
}

// 2. Use SimpleRouter
struct ContentView: View {
    @State private var router = SimpleRouter<Destination, Sheet>()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .environment(router)
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .detail(let id):
            DetailView(id: id)
        case .settings:
            SettingsView()
        case .profile(let userId):
            ProfileView(userId: userId)
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .compose:
            ComposeView()
        case .settings:
            SettingsSheet()
        }
    }
}

// 3. Navigate from anywhere in your app
struct HomeView: View {
    @Environment(SimpleRouter<Destination, Sheet>.self) private var router

    var body: some View {
        VStack {
            Button("Go to Detail") {
                router.navigateTo(.detail(id: "123"))
            }

            Button("Show Compose Sheet") {
                router.presentSheet(.compose)
            }
        }
    }
}
```

**Navigation with Tabs**

```
import AppRouter

enum AppTab: String, TabType, CaseIterable {
    case home, profile, settings

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .profile: return "person"
        case .settings: return "gear"
        }
    }
}

enum Destination: DestinationType {
    case detail(id: String)
    case list
    case profile(userId: String)
}

enum Sheet: SheetType {
    case settings
    case profile
    case compose

    var id: Int { hashValue }
}

struct ContentView: View {
    @State private var router = Router<AppTab, Destination, Sheet>(initialTab: .home)

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack(path: $router[tab]) {
                    HomeView()
                        .navigationDestination(for: Destination.self) { destination in
                            destinationView(for: destination)
                        }
                }
                .tabItem {
                    Label(tab.rawValue.capitalized, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .detail(let id):
            DetailView(id: id)
        case .list:
            ListView()
        case .profile(let userId):
            ProfileView(userId: userId)
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .settings:
            SettingsView()
        case .profile:
            ProfileSheet()
        case .compose:
            ComposeView()
        }
    }
}
```

## Working with Claude

### Expectations

When working with my code:

1. **Ultrathink** before making any edits
2. **Understand the full context** of the code and requirements
3. **Ask clarifying questions** when requirements are ambiguous
4. **Think from first principles** - don't make assumptions
5. **Follow TDD** - always write or modify tests first

### Code Changes

When suggesting or making changes:

- Respect the existing patterns and conventions
- Maintain test coverage for all behavior changes
- Follow TDD - write or modify tests first
- Keep changes small and incremental
- Provide rationale for significant design decisions

### Communication

- Be explicit about trade-offs in different approaches
- Explain the reasoning behind significant design decisions
- Flag any deviations from these guidelines with justification
- Suggest improvements that align with these principles
- When unsure, ask for clarification rather than assuming

## Summary

The key is to write clean, testable, functional code that evolves through small, safe increments. Every change should be driven by a test that describes the desired behavior, and the implementation should be the simplest thing that makes that test pass. When in doubt, favor simplicity and readability over cleverness.
