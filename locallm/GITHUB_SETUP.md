# GitHub Setup & Automated Release Guide

This guide explains how to push this project to GitHub and automatically build **Release APK**, **AAB (App Bundle)**, and **iOS IPA** using GitHub Actions.

---

## 1. What Has Been Added

1. **`.gitignore` (Root and `locallm/`)**:
   - Ignores large model files (`*.gguf`, `*.bin`, `*.safetensors`, `*.onnx`).
   - Ignores build artifacts (`/build/`, `.dart_tool/`, `.gradle/`, `.cxx/`).
   - Ignores local machine paths (`local.properties`).
   - Ignores signing keys and secrets (`*.keystore`, `*.jks`, `key.properties`, `.env`).
   - Ignores iOS Pods, ephemeral frameworks, and prebuilt native binaries.

2. **GitHub Actions Workflow (`.github/workflows/release.yml`)**:
   - **Android Job (`build-android`)**:
     - Runs on `ubuntu-latest`.
     - Automatically sets up Java 17, Android NDK (r27b), and Flutter.
     - Builds **`locallm-release.apk`** and **`locallm-release.aab`**.
   - **iOS Job (`build-ios`)**:
     - Runs on `macos-14`.
     - Automatically compiles the native `llama.cpp` iOS library (`libllama_ios.a`).
     - Builds the iOS release without codesign requirements and packages it into an installable **`locallm-ios-unsigned.ipa`**.
   - **Release Job (`release`)**:
     - Automatically creates a GitHub Release with version notes.
     - Uploads the APK, AAB, and IPA files directly to the release page.

---

## 2. First-Time Git Push to GitHub

Open your terminal in this repository directory and run:

```bash
# 1. Initialize git (if not already done)
git init

# 2. Add all source files (protected by .gitignore)
git add .

# 3. Create your initial commit
git commit -m "feat: Initial commit of LocalLM with GitHub Release workflow"

# 4. Rename default branch to main
git branch -M main

# 5. Link your GitHub repository (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git

# 6. Push to GitHub
git push -u origin main
```

---

## 3. How to Trigger Automated Builds & Releases

There are two ways to trigger a release:

### Method A: By Pushing a Git Tag (Recommended)

Whenever you are ready to publish a new version (e.g. `v1.0.0`):

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will immediately start building:
1. Android Release APK (`locallm-release.apk`)
2. Android App Bundle (`locallm-release.aab`)
3. iOS IPA (`locallm-ios-unsigned.ipa`)
4. A new GitHub Release under `v1.0.0` will be created with all downloads attached!

---

### Method B: Manual Trigger from GitHub UI

1. Open your repository on GitHub.
2. Go to the **Actions** tab.
3. Select **"Build & Release (APK & IPA)"** from the left sidebar.
4. Click **Run workflow**.
5. Select whether to build Android, iOS, and whether to publish the release.
6. Click **Run workflow**.

---

## 4. How Users Can Install the Outputs

- **Android (`locallm-release.apk`)**:
  - Download directly to any Android device and tap to install (enable "Install unknown apps").
- **Android Play Store (`locallm-release.aab`)**:
  - Ready for Google Play Console upload.
- **iOS (`locallm-ios-unsigned.ipa`)**:
  - Can be installed using **AltStore**, **SideStore**, **Sideloadly**, or **TrollStore** without a paid Apple Developer account.
  - Can be signed with an enterprise or developer certificate using standard iOS signing tools.
