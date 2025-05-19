# PT Champion Android App Signing

This directory contains the keystore file for signing the PT Champion Android app. In production, the actual keystore should be stored securely and not committed to version control.

## Generating a Production Keystore

To generate a production keystore, use the following command:

```bash
keytool -genkey -v -keystore ptchampion.keystore -alias ptchampion -keyalg RSA -keysize 2048 -validity 10000
```

When prompted:
1. Enter a secure password for the keystore
2. Enter your organization details
3. Set the same password for the key as the keystore (or a different one if you prefer)

## GitHub Encrypted Secrets

For CI/CD deployment, store the following secrets in GitHub Encrypted Secrets:

1. `KEYSTORE_BASE64`: The base64-encoded keystore file 
   ```bash
   base64 -i ptchampion.keystore | tr -d '\n' > keystore_base64.txt
   ```

2. `KEYSTORE_PASSWORD`: The password for the keystore
3. `KEY_ALIAS`: The alias used when creating the keystore (e.g., "ptchampion")
4. `KEY_PASSWORD`: The password for the key

## GitHub Actions Workflow for App Signing

In your GitHub Actions workflow, add steps to decode and use the keystore:

```yaml
jobs:
  build:
    steps:
      - name: Decode Keystore
        run: |
          echo ${{ secrets.KEYSTORE_BASE64 }} | base64 --decode > app/keystore/ptchampion.keystore
      
      - name: Build Release APK and Bundle
        run: |
          ./gradlew assembleRelease bundleRelease \
            -PKEYSTORE_PASSWORD=${{ secrets.KEYSTORE_PASSWORD }} \
            -PKEY_ALIAS=${{ secrets.KEY_ALIAS }} \
            -PKEY_PASSWORD=${{ secrets.KEY_PASSWORD }}
```

## Backup

Keep a secure backup of the keystore file. If you lose it, you won't be able to:
- Update your app on Google Play
- Use the same package name for new app versions

## Security Best Practices

1. Never commit the actual keystore file to version control
2. Use long, random passwords for both keystore and key
3. Restrict access to the keystore file to only trusted team members
4. Consider using Google Play App Signing for additional security 