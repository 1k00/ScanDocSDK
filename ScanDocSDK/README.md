# ScanDoc iOS SDK

The ScanDoc SDK enables easy integration of document scanning and NFC biometric data reading within your iOS application.

## ✨ Features

- Real-time camera scanning for ID documents.
- Document image, face, and signature extraction.
- NFC biometric chip reading (PACE (fallback to BAC) protocol).
- Configurable SDK settings via `ScanDocSDKConfig`.

---

## 🚀 Getting Started

### Step 1: Setting up plist.info and delegates

info.plist should include the following:
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NFCReaderUsageDescription</key>
    <string>This app uses NFC to scan passports</string>
    <key>NSCameraReactionEffectGesturesEnabledDefault</key>
    <true/>
    <key>NSCameraUsageDescription</key>
    <string>This app uses the camera to read passports</string>
    <key>UIApplicationSceneManifest</key>
    <array>
        <string>nfc</string>
        <string>armv7</string>
    </array>
    <key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A0000002471001</string>
        <string>A0000002472001</string>
        <string>00000000000000</string>
    </array>
</dict>
</plist>

```

masterList.pem should be added to the project root directory

entitlement file should include the following:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.nfc.readersession.formats</key>
    <array>
        <string>TAG</string>
    </array>
</dict>
</plist>
```

---

## 🧪 Usage Example

### Initialize the SDK and Start Scanning



```
ScanDocAPI.initialize(userKey: <user_key>, acceptTermsAndConditions: true)
```

---

### 🖼 ScanDoc API codes:

- 1000 (EXTRACTING) -> Proceeding with extraction
- 1001 (DEPRECATED) -> Deprecated info code - focusing replaced by 1009
- 1002 (DOCUMENT_NOT_VISIBLE) -> Document not fully visible, all four corners of the document should be on-screen.
- 1003 (DOCUMENT_NOT_PRESENT) -> Document not present.
- 1004 (ANGLED_DOCUMENT) -> Captured document is at an angle. Please correct the document angle.
- 1005 (DOCUMENT_TOO_SMALL) -> Captured document is too small. Please move it closer to the camera.
- 1006 (DOCUMENT_UNSUPPORTED) -> Document not supported.
- 1007 (FLIP_DOCUMENT) -> Image is valid, but the document has a back side - flip the document.
- 1008 (BACKGROUND_TOO_SIMILAR) -> Background color is too similar to the color of the document.
- 1009 (CAMERA_FOCUSING) -> Waiting for camera to focus.
- 1010 (LOW_IMAGE_QUALITY) -> Low image quality detected, keep the camera stable.
- 0001 (not an enum) -> Raises an error (you do not need to cover this case)

---

## 📲 NFC Reading

Use PassportScannerView to initialize the NFC reading process after a successful document scan:

This view accepts mrzKey as its required parameter, which is a string containing the passport number, date of birth, and expiry date (see Utils/PassportUtils.swift)

---

## 📩 Support

For integration assistance or API access, contact [mvlaic@scandoc.ai](mailto:mvlaic@scandoc.ai) and [support@scandoc.ai](mailto:support@scandoc.ai)

---

## 🧾 License

This SDK is proprietary. For any kind of use, contact [info@scandoc.ai](mailto:info@scandoc.ai).
