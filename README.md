<p align="center">
  <img src="assets/icon.jpg" alt="Talos Icon" width="150" height="150" />
</p>

# What is Talos?

> [!WARNING]
> **Development Status**: This project is currently in active development and is **not stable yet**. Features and functionality are subject to change.

Think of Talos as an intelligent automaton rather than a dumb script runner. It organizes our tests into a structured hierarchy (Project > Feature > Test Case) and uses an LLM to "drive" the browser or emulator.

Talos fundamentally changes how we approach Quality Assurance by analyzing both your Source Code and your Figma Designs using AI. It doesn't just execute instructions; it discovers test scenarios on its own and verifies them against your design truth.

## Why Talos is better than Selenium/Cypress:

- **It’s an Agent, not a Script**: We write tests using natural language, like "Login and update profile." Talos figures out the selectors, clicks, and inputs automatically. If a developer renames a CSS class or moves a button, Talos doesn't care—it finds the element anyway using visual context.
- **AI-Powered Discovery**: Talos analyzes your codebase and Figma files to understand your application's logic. In addition to running the tests you define, it can autonomously discover edge cases and suggest new tests, ensuring coverage you might have overlooked.
- **Readable by Everyone**: Because tests are defined using Natural Language (NLP), anyone—Product Managers, Designers, or Stakeholders—can read a test case and instantly understand exactly what is being tested. No more deciphering complex code or XPATH selectors.
- **Figma as the Source of Truth**: Talos pulls baseline images directly from your Figma files. It doesn't just check if the button works; it checks if the button looks right. If the implementation drifts from the design, Talos blocks the merge.
- **Platform Agnostic**: Using a generic "Launch Configuration" (similar to VS Code), Talos can test your Flutter app, React dashboard, and API endpoints in a single unified run.
- **Atomic State Management**: It enforces strict Setup and Teardown protocols at both the Feature and Test Case levels. This eliminates flaky "element not found" errors caused by dirty database states or leftover UI modals.

## Comparison with Traditional Tools

Talos isn't just a "wrapper" around existing tools; it is a fundamental shift in how testing works. Here is how it compares to the tools you likely use today.

### 1. Talos vs. Selenium / Cypress

**The Problem with Selenium**: It relies on selectors (IDs, XPaths, CSS Classes).

- **Scenario**: A developer changes `<button id="submit">` to `<div class="btn-submit">`.
- **Selenium Result**: CRASH. The test fails instantly because the ID is gone. You spend hours fixing "brittle" code.

**The Talos Advantage**: Talos uses Vision.

- **Talos Result**: SUCCESS. It sees a blue rectangle that says "Submit" and clicks it, just like a human user would. It adapts to code refactors automatically.

### 2. Talos vs. Flutter Integration Test

**The Problem with Flutter Tests**: They are Code-Only and Siloed.

- **Scenario**: You want to verify that the implemented screen matches the Designer's mockup.
- **Flutter Result**: You have to manually write assertions for padding, colors, and fonts in Dart code. It is tedious, error-prone, and hard to read for non-developers.

**The Talos Advantage**: Talos is Design-Aware.

- **Talos Result**: It pulls the actual image from Figma and overlays it on the running app. It highlights visual bugs (wrong font, 2px misalignment) that code-based tests completely miss. Plus, your Product Manager can read the test steps in English, not Dart.

### Comparison Matrix

| Feature             | Talos (AI Agent)                    | Selenium / Cypress                  | Flutter Integration Test     |
| :------------------ | :---------------------------------- | :---------------------------------- | :--------------------------- |
| **Test Definition** | Natural Language (NLP)              | JavaScript / Java / Python Code     | Dart Code                    |
| **Resilience**      | Self-Healing (Adapts to UI changes) | Brittle (Breaks on ID/Class change) | Rigid (Widget Key dependent) |
| **Validation**      | Visual (Figma) + Functional         | Functional Only                     | Functional Only              |
| **Setup/Teardown**  | Enforced Atomic State               | Manual / Often Flaky                | Manual / Boilerplate Heavy   |
| **Cross-Platform**  | Universal (Web, Mobile, API)        | Mostly Web                          | Flutter Only                 |
| **Maintenance**     | Low (AI fixes minor issues)         | High (Constant script updates)      | Medium (Tied to codebase)    |

### Summary

- Use **Selenium** if you enjoy maintaining broken scripts every time a div changes.
- Use **Flutter Integration Tests** if you only care about logic and don't mind writing verbose Dart code that designers can't read.
- Use **Talos** if you want an autonomous agent that tests the User Experience, verifies the Visual Design, and heals itself when code changes.

## Architecture

Talos runs locally on your machine, consisting of two main components talking to each other:

1.  **[Talos CLI (React + Electron)](https://github.com/Talos-Tester-AI/talos-ai)**: The brain and the face. A desktop application where you define your features, write test cases in natural language, and watch the live execution. It holds your test data locally.
2.  **[Talos Agent (Python)](https://github.com/Talos-Tester-AI/talos-agent)**: The hands. A lightweight local service that connects to your Android device (via ADB) to perform the actions and capture screenshots.

## Installation & Quick Start

You will need to run both the Agent and the CLI.

### Prerequisites

- Node.js (v18+)
- Python 3.9+
- ADB (Android Debug Bridge) installed and in PATH
- An Android device connected via USB or an emulator running.

### 1. Start the Agent (Python)

The agent acts as the bridge to your device.

```bash
git clone https://github.com/Talos-Tester-AI/talos-agent.git
cd talos-agent
python -m venv venv
source venv/bin/activate  # or .\venv\Scripts\activate on Windows
pip install -r requirements.txt
./run_agent.sh
```

The agent will start on port 8000.

### 2. Start the App (CLI)

The CLI is the main interface.

```bash
git clone https://github.com/Talos-Tester-AI/talos-ai.git
cd talos-ai
npm install
npm run dev
```

This will launch the Talos desktop application.

## 🗺️ Roadmap & Goals

| Feature                      |     Status     |
| :--------------------------- | :------------: |
| **Android Agent (DroidRun)** |  ✅ Completed  |
| **Web Support**              | 🚧 In Progress |
| **iOS Support**              |   🔮 Future    |
| **Kubernetes Environment**   |   🔮 Future    |
| **GitHub Integration**       |   🔮 Future    |
| **CI/CD Integration**        |   🔮 Future    |
