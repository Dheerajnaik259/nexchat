import os

base_dir = r"e:\ANDROID APPS\chat_app\lib"

directories = [
    "app",
    "core/constants",
    "core/errors",
    "core/extensions",
    "core/theme",
    "core/utils",
    "core/widgets",
    "models",
    "services/firebase",
    "services/encryption",
    "providers",
    "features/auth/screens",
    "features/auth/widgets",
    "features/auth/controllers",
    "features/home/screens",
    "features/home/widgets",
    "features/chat/screens",
    "features/chat/widgets",
    "features/chat/controllers",
    "features/calls/screens",
    "features/calls/widgets",
    "features/calls/controllers",
    "features/status/screens",
    "features/status/widgets",
    "features/status/controllers",
    "features/contacts/screens",
    "features/contacts/controllers",
    "features/groups/screens",
    "features/groups/controllers",
    "features/profile/screens",
    "features/profile/controllers",
    "features/settings/screens",
    "features/settings/controllers",
]

for d in directories:
    dir_path = os.path.join(base_dir, d.replace('/', os.sep))
    os.makedirs(dir_path, exist_ok=True)
    # Create an empty .gitkeep so git tracks the empty dir, or we can just leave them empty.
    gitkeep_path = os.path.join(dir_path, ".gitkeep")
    open(gitkeep_path, 'a').close()

assets_dir = r"e:\ANDROID APPS\chat_app\assets"
asset_dirs = [
    "images",
    "animations",
    "sounds",
    "fonts"
]

for d in asset_dirs:
    dir_path = os.path.join(assets_dir, d)
    os.makedirs(dir_path, exist_ok=True)
    gitkeep_path = os.path.join(dir_path, ".gitkeep")
    open(gitkeep_path, 'a').close()

print("Directories scaffolded securely.")
