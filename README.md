# Logging App User

Logging App User is a desktop application built using Flutter that monitors and logs system activities. The app stores log files locally in JSON format and uploads the data to Firebase for centralized logging and analysis.

## Features

- **Real-Time Logging**: Monitors system activities and updates the log file in real-time.
- **JSON Storage**: Stores log entries in JSON format locally on the user's machine.
- **Firebase Integration**: Automatically uploads log entries to Firebase for remote storage and analysis.
- **Automatic Startup**: The application starts automatically when the computer boots up.
- **Minimize to Tray**: Supports minimizing the application to the system tray.
- **Cross-Platform**: Built using Flutter, allowing for cross-platform deployment.

## Installation

### Prerequisites

- **Flutter SDK**: Make sure you have Flutter installed on your machine. [Get Flutter](https://flutter.dev/docs/get-started/install)
- **Firebase Setup**: Ensure your Firebase project is set up correctly and you've added the necessary configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS, etc.).

### Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/logging_app_user.git
   cd logging_app_user
2. **Install Dependencies**:
   ```bash
   flutter pub get
3. **Build the Application: For Windows**:
   ```bash
   flutter build windows
4. **Verify Installation**:
   After installation, verify that the application is installed in the specified directory and that it starts automatically with your computer.

## Usage

### Start the Application

The application will start automatically when your computer boots up. You can also manually start it from the Start Menu or Desktop shortcut if created.

### View Logs

The application provides a log viewer to see the latest log entries. You can access it by double-clicking the application icon in the system tray.

### Upload Logs to Firebase

Log entries are automatically uploaded to Firebase. Ensure you have internet connectivity for the logs to be uploaded successfully.

## Configuration

### Firebase Configuration

To configure Firebase for your Windows application, follow these steps:

1. **Create a Firebase Project**:  
   Go to the Firebase Console and create a new project.

2. **Add Your App**:  
   Add your app to the Firebase project. Although `google-services.json` or `GoogleService-Info.plist` are not required for Windows, you still need to set up your Firebase project to integrate Firebase services.

3. **Add Firebase Initialization Code**:  
   Ensure your Flutter project includes the Firebase initialization code. Typically, this is done in the `main.dart` file with the `Firebase.initializeApp()` method.

4. **Update Firebase Rules**:  
   Make sure your Firebase Firestore rules are set up to allow reading and writing data. You can set up your rules in the Firebase Console under the Firestore Database section.

### Automatic Startup

The application is configured to start automatically with your computer using a registry entry. If you want to disable this, you can remove the entry from the Windows registry:

1. **Open the Registry Editor**:  
   Press `Win + R`, type `regedit`, and press `Enter`.

2. **Navigate to Startup Entries**:  
   Go to `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`.

3. **Remove Entry**:  
   Find the entry for "Logging App User" and delete it.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
