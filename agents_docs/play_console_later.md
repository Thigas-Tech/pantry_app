# Play Console Deployment — Return Checklist

Complete these steps when Google Play document verification finishes.

All detailed context is in `agents_docs/playstore.md`. This file is the
step-by-step checklist only.

## 1. Google Play Console

- [ ] Log in to https://play.google.com/console
- [ ] Create app with package name `com.thigas_tech.pantry_app`
- [ ] Build the first AAB locally and upload it **manually** to
  Production (Google requires the initial release through the web UI):
  ```bash
  flutter build appbundle --release
  # Upload: Play Console > App > Production > Create new release
  ```
- [ ] Create an **internal test track** (optional but recommended)
- [ ] Complete all Play Console requirements:
  - Content rating questionnaire
  - Privacy policy URL
  - App screenshots and description
  - Target audience and ads declaration
- [ ] Submit for review

## 2. Google Cloud Service Account

- [ ] Go to https://console.cloud.google.com
- [ ] Create a project (or use an existing one)
- [ ] Enable the **Google Play Android Developer API**
- [ ] Create a service account (IAM > Service Accounts > Create)
- [ ] Assign the role **Service Account User**
- [ ] Generate a JSON key and download it
- [ ] In Play Console > Users and permissions, invite the service account
  email with the **Release Manager** role

## 3. Signing Keystore

- [ ] Generate the upload keystore:
  ```bash
  keytool -genkey -v \
    -keystore upload-keystore.jks \
    -alias upload \
    -keyalg RSA -keysize 2048 \
    -validity 10000
  ```
  Save the passwords somewhere secure.
- [ ] Create the real key.properties from the template:
  ```bash
  cp android/key.properties.template android/key.properties
  # Edit file: replace REPLACE_WITH_* with your passwords
  ```
- [ ] Encode both files as base64:
  ```bash
  base64 -w0 upload-keystore.jks    > /tmp/keystore_base64.txt
  base64 -w0 android/key.properties > /tmp/keyprops_base64.txt
  ```

## 4. GitHub Secrets

Go to Settings > Secrets and variables > Actions > New repository secret.

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Contents of `/tmp/keystore_base64.txt` |
| `KEY_PROPERTIES_BASE64` | Contents of `/tmp/keyprops_base64.txt` |
| `PLAY_STORE_SERVICE_ACCOUNT` | JSON key downloaded from step 2 |
| `OFF_USER_ID` | Your Open Food Facts username |
| `OFF_PASSWORD` | Your Open Food Facts password |
| `CONTACT_EMAIL` | Your email address |
| `FEEDBACK_TOKEN` | GitHub PAT with repo scope |

## 5. Re-enable the Deploy Workflow

In `.github/workflows/deploy-to-playstore.yml`, uncomment the `push: tags:`
trigger:

```yaml
on:
  workflow_dispatch:
  push:                              # UNCOMMENT this line
    tags:                            # UNCOMMENT this line
      - 'v[0-9]+.[0-9]+.[0-9]+'     # UNCOMMENT this line
```

## 6. Deploy

- [ ] Ensure `pubspec.yaml` version + build number is correct:
  ```yaml
  version: 0.0.5+1  # increment +N for each release
  ```
- [ ] Push a tag to trigger deployment:
  ```bash
  git tag v0.0.5 && git push origin v0.0.5
  ```
- [ ] Watch the workflow in Actions > Deploy to Play Store
- [ ] Verify the AAB appears in Play Console > Internal testing
- [ ] Promote from internal to production when ready

## 7. Clean Up

- [ ] Remove the reminder block at the top of `TODO.md`
- [ ] Optionally delete this file (`agents_docs/play_console_later.md`)
  since all info is also in `agents_docs/playstore.md`
