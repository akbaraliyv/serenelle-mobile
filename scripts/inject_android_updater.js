const fs = require('fs');
const path = require('path');

// 1. Copy MainActivity.kt into the generated Android namespace package.
const gradlePath = path.join('android', 'app', 'build.gradle');
const gradle = fs.readFileSync(gradlePath, 'utf8');
const namespaceMatch = gradle.match(/namespace\s+["']([^"']+)["']/);
if (!namespaceMatch) throw new Error('Android namespace not found in app/build.gradle');
const namespace = namespaceMatch[1];
const kotlinDir = path.join('android', 'app', 'src', 'main', 'kotlin', ...namespace.split('.'));
fs.mkdirSync(kotlinDir, { recursive: true });
const activity = fs.readFileSync(path.join('android_updater_files', 'MainActivity.kt'), 'utf8')
  .replace(/^package\s+[\w.]+/m, `package ${namespace}`);
fs.writeFileSync(path.join(kotlinDir, 'MainActivity.kt'), activity, 'utf8');
console.log('Injected MainActivity.kt');

// 2. Copy file_paths.xml
const xmlDir = path.join('android', 'app', 'src', 'main', 'res', 'xml');
fs.mkdirSync(xmlDir, { recursive: true });
fs.copyFileSync(
  path.join('android_updater_files', 'file_paths.xml'),
  path.join(xmlDir, 'file_paths.xml')
);
console.log('Injected file_paths.xml');

// 3. Update AndroidManifest.xml
const manifestPath = path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml');
let manifest = fs.readFileSync(manifestPath, 'utf8');

// Add permissions if not present
const perms = `
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
`;
if (!manifest.includes('REQUEST_INSTALL_PACKAGES')) {
  manifest = manifest.replace('<application', `${perms}\n    <application`);
}

// Add FileProvider inside application tag if not present
const provider = `
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="\${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
`;
if (!manifest.includes('androidx.core.content.FileProvider')) {
  manifest = manifest.replace('</application>', `${provider}\n    </application>`);
}

fs.writeFileSync(manifestPath, manifest, 'utf8');
console.log('Updated AndroidManifest.xml with FileProvider and REQUEST_INSTALL_PACKAGES');

// 4. Update build.gradle for minSdkVersion 21
const appGradlePath = path.join('android', 'app', 'build.gradle');
if (fs.existsSync(appGradlePath)) {
  let appGradle = fs.readFileSync(appGradlePath, 'utf8');
  appGradle = appGradle.replace(/minSdkVersion\s+flutter\.minSdkVersion/g, 'minSdkVersion 21');
  appGradle = appGradle.replace(/minSdk\s*=\s*flutter\.minSdkVersion/g, 'minSdk = 21');
  fs.writeFileSync(appGradlePath, appGradle, 'utf8');
  console.log('Configured minSdkVersion 21 in build.gradle');
}
