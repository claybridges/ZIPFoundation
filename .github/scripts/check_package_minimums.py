# Fails when the manifest selected by the active Xcode declares a platform minimum below
# what that Xcode's SDKs support. Xcode silently raises such minimums instead of warning.
import json, subprocess, sys

sdk_for = {"macos": "macosx", "ios": "iphoneos", "tvos": "appletvos", "watchos": "watchos", "visionos": "xros"}

def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout

def version(s):
    return tuple(int(x) for x in s.split("."))

package_path = sys.argv[1] if len(sys.argv) > 1 else "."
package = json.loads(run("swift", "package", "--package-path", package_path, "dump-package"))
failed = False
for platform in package["platforms"]:
    sdk = sdk_for.get(platform["platformName"])
    if sdk is None:
        continue
    sdk_path = run("xcrun", "--sdk", sdk, "--show-sdk-path").strip()
    with open(f"{sdk_path}/SDKSettings.json") as f:
        minimum = json.load(f)["SupportedTargets"][sdk]["MinimumDeploymentTarget"]
    below = version(platform["version"]) < version(minimum)
    print(f"{platform['platformName']}: declares {platform['version']}, SDK minimum is {minimum}" + ("  <-- below" if below else ""))
    failed |= below
sys.exit(1 if failed else 0)
