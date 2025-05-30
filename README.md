# CamWork — Professional Photo & Video Management Suite

CamWork is a cross-platform desktop application implemented in Flutter, designed to automate the end-to-end organization of photographic and video assets. It provides a unified graphical interface for dependency management, configuration, metadata-driven import, RAW separation, duplicate detection, “private” folder extraction, and statistical reporting.

---

## 1. Installation and Dependency Management

* **Interactive Mode**:
  On first launch (or without the `--silent` flag), CamWork performs a pre-flight check for required tools (Python, ExifTool, Flutter). Any missing component triggers a modal dialog offering “Cancel” or “Download,” opening the official install page for each missing dependency.

* **Silent Mode**:
  When launched with `--silent`, dependencies are validated without UI. Any missing dependency causes the application to exit with an error code, enabling integration into automated deployment or CI/CD pipelines.

---

## 2. First-Run Configuration

* **Root Folder Selection**
  The user is prompted to select a project root directory. This path is stored in persistent settings (via SharedPreferences).
* **Directory Initialization**
  Upon saving the root, CamWork creates the following subdirectories if they do not already exist:

  * `CAMERAS/` (root for camera model folders)
  * `logs/` (application logs)
  * `pdf/` (PDF summaries and reports)
  * `metadata/` (JSON files for mappings and hash registry)

---

## 3. Settings and Mappings

* **Settings Page**
  Provides controls to:

  1. Change or clear the saved root folder.
  2. Navigate to the Model–Folder Mappings page.

* **Model–Folder Mappings Page**
  Displays all EXIF camera-model → destination-folder mappings. Supports:

  * **Create** or **Edit** a single mapping via dialog.
  * **Delete** any existing mapping.
  * **Import** mappings from:

    * A comma-separated text input (e.g. `Canon EOS 80D:Canon, Nikon D750:Nikon`).
    * A CSV file where each line is `Model,Folder`.

All mapping changes are persisted to `metadata/model_mapping.json`.

---

## 4. Photo Import Workflow

1. **Source Selection**
   User chooses a source directory (e.g. an SD card) via native folder picker.
2. **Dry-Run Option**
   When enabled, the import preview is logged but no files are moved.
3. **Hash-Based Deduplication**
   A SHA-256 registry tracks processed files in `metadata/hash_registry.json`; previously imported files are skipped.
4. **EXIF-Based Folder Assignment**

   * The application invokes ExifTool to read `Model` and `DateTimeOriginal`.
   * New models prompt the user to select or create a target folder under `CAMERAS/`.
   * Files are moved into `CAMERAS/<Model>/<YYYY.MM>/`, with early-morning first-day images assigned to the previous month.
5. **Progress and Logging**

   * A progress bar updates in real time.
   * A scrollable log pane records each action and writes to `logs/import_<timestamp>.log`.
6. **Error Aggregation**
   Any file-processing errors are collected; at completion an “N errors occurred” dialog appears with options to retry or dismiss.

---

## 5. RAW File Separation

* **Scope**: Traverses every subfolder inside each `CAMERAS/<Model>/<YYYY.MM>/`.
* **RAW Detection**: Identifies RAW extensions (`.CR2`, `.ARW`, etc.) and moves them into a `RAW/` subfolder within the same thematic directory.
* **UI**: Progress indicator and detailed logs.

---

## 6. Duplicate Detection and Removal

1. **Scan**: For each camera model folder (excluding `PRIVATE/`), files are grouped by filename (case-insensitive).
2. **Hash Comparison**: Within groups larger than one, SHA-256 is computed to identify true duplicates.
3. **Results View**:

   * Main list shows each duplicate group with two thumbnail previews and group size.
   * “Preview & Delete” opens a dialog displaying images in side-by-side pairs.
4. **Deletion**: Clicking the trash icon under any preview deletes that file immediately; groups with fewer than two files automatically disappear.

---

## 7. “Private” Folder Extraction

* **Detection**: Any folder whose name contains “(X)” under `CAMERAS/`.
* **Replication**: Recursively copies matching folders into `CAMERAS/PRIVATE/`, preserving their internal structure. Existing destinations are skipped to prevent data loss.

---

## 8. Statistical Reporting (Experimental)

* **Metrics**: Counts by model, file type, and month.
* **Output**: Generates a formatted PDF report in `pdf/statistics_<timestamp>.pdf`, including tables and charts.

---

## 9. Global Error Handling and Logging

* **Centralized Dialogs** for multiple errors.
* **Retry** buttons for recoverable errors (e.g. network drives waking up).
* **Persistent LoggingService** writes timestamped entries to `logs/`.

---

## 10. Project Structure

```
lib/
 ├─ main.dart                        # AppLauncher + CamWorkApp
 ├─ pages/
 │   ├─ settings_page.dart
 │   ├─ mapping_page.dart
 │   ├─ import_photos_page.dart
 │   ├─ separate_raw_page.dart
 │   ├─ search_duplicates_page.dart
 │   ├─ copy_private_page.dart
 │   └─ statistics_page.dart
 ├─ services/
 │   ├─ installer_service.dart
 │   ├─ config_service.dart
 │   ├─ logging_service.dart
 │   ├─ mapping_service.dart
 │   ├─ import_service.dart
 │   ├─ raw_service.dart
 │   ├─ duplicate_service.dart
 │   ├─ private_service.dart
 │   └─ stats_service.dart
 └─ utils/                           # Helpers for ExifTool, PDF, charts, etc.

assets/
 └─ logo.png

pubspec.yaml
README.md
```

---

## 11. How to Run

1. Ensure Flutter desktop support is enabled.

2. Install Python 3.6+ and ExifTool on your PATH.

3. From the project root:

   ```bash
   flutter clean
   flutter pub get
   flutter run -d windows    # or -d macos, -d linux
   ```

4. Follow the on-screen prompts to configure and begin organizing your media.

---

CamWork provides a fully integrated, professional workflow for organizing large photo and video archives, minimizing manual effort while offering comprehensive controls, rich logging, and error-resilient automation.
