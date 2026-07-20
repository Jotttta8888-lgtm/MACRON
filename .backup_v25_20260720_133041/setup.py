from setuptools import setup

APP = ['macron_tkinter.py']
DATA_FILES = []
OPTIONS = {
    'argv_emulation': True,
    'packages': ['requests'],
    'includes': ['tkinter', 'threading', 'json'],
    'plist': {
        'CFBundleName': 'MACRON',
        'CFBundleShortVersionString': '4.0.0',
        'CFBundleVersion': '4.0.0',
        'CFBundleIdentifier': 'com.macron.app',
        'LSMinimumSystemVersion': '14.0',
        'NSHighResolutionCapable': True,
    }
}

setup(
    app=APP,
    data_files=DATA_FILES,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
