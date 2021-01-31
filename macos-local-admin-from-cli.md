# Create a local admin on macOS from CLI

```bash
sudo -i
# This creates a user entry, it does not create a home directory
dscl . -create /Users/luser
dscl . -create /Users/luser UserShell /bin/zsh
dscl . -create /Users/luser RealName "Local User"
dscl . -create /Users/luser UniqueID "1010"

# Set the primary group to be the admin group
dscl . -create /Users/luser PrimaryGroupID 80

# This is where we set the home directory:
dscl . -create /Users/luser NFSHomeDirectory /Users/luser
dscl . -passwd /Users/luser password_here

# Copy over the library template directory
cp -R /System/Library/User\ Template/English.lproj /Users/luser

Make the Drop Box folder and set appropriate ACLs
mkdir -p /Users/luser/Public/Drop\ Box
chmod +a "user:luser allow list,add_file,search,delete,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,writesecurity,chown,file_inherit,directory_inherit" /Users/luser/Public/Drop\ Box

chown -R luser:staff /Users/luser
reboot
```
