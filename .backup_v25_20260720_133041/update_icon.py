import plistlib

plist_path = '/Applications/MACRON.app/Contents/Info.plist'
with open(plist_path, 'rb') as f:
    plist = plistlib.load(f)

plist['CFBundleIconFile'] = 'MACRON'
plist['CFBundleIconName'] = 'MACRON'

with open(plist_path, 'wb') as f:
    plistlib.dump(plist, f)

print("OK")
