# Checklist App

Personal productivity dashboard that lets you create, prioritize, sort, and complete checklist items while tracking progress on a lightweight graph.

## Features
- Create, edit, delete, and complete checklist entries via a responsive bottom-sheet form.
- Assign Low/Medium/High priorities and sort the list by priority, name, or recency.
- Dashboard card with completion gauge and priority distribution bar chart (powered by `fl_chart`).
- Provider-based state management with a single source of truth and clean data models.

## Project Structure (GetX)
```
lib/
 └─ app/
     ├─ data/
     │   └─ models/         # Todo entity + enums
     └─ modules/
         └─ home/
             ├─ bindings/   # GetX bindings (dependency graph)
             ├─ controllers/# HomeController with reactive logic
             ├─ views/      # HomeView (GetView)
             └─ widgets/    # Dashboard card, list, form
```

## Getting Started
```bash
flutter pub get
flutter run
```
The default seed data demonstrates dashboard and sorting behaviour.

## Testing
| Command | Coverage |
|---------|----------|
| `flutter test` | Unit + widget tests (`TodoController`, smoke UI) |
| `flutter test integration_test -d macos` | End-to-end flow (runs headless on macOS; replace `macos` with your target device) |

## Continuous Integration
`.github/workflows/flutter.yml` runs `flutter analyze`, unit/widget tests, and integration tests on every push/PR via GitHub Actions (macOS runner + Flutter 3.24 stable).

## Demo
If you record a walkthrough, drop the link here (e.g., Loom, YouTube) so graders can quickly preview the experience.
