# Chroot Jail Setup Scripts

A collection of Bash scripts for creating and managing a simple Linux chroot jail environment. These scripts allow you to:

* Create a chroot jail structure.
* Create users that are automatically jailed upon login.
* Add commands and their required shared libraries into the jail.
* Remove commands and their dependencies from the jail.

## Overview

The project consists of three scripts:

| Script               | Purpose                                              |
| -------------------- | ---------------------------------------------------- |
| `chroot_setup.sh`    | Creates the chroot environment and jailed users      |
| `command_adder.sh`   | Copies commands and required libraries into the jail |
| `command_remover.sh` | Removes commands and copied libraries from the jail  |

---

# 1. Creating the Chroot Jail

Run:

```bash
sudo ./chroot_setup.sh
```

Select:

```text
M1
```

This creates the jail at:

```text
/var/chroot
```

The script will:

* Create the required directory structure.
* Copy essential system configuration files.
* Copy PAM configuration files.
* Copy NSS libraries and authentication components.
* Prepare the environment for jailed users.

If an existing jail is detected, you will be prompted before it is deleted and recreated.

---

# 2. Creating a Jailed User

After creating the jail with **M1**, run:

```bash
sudo ./chroot_setup.sh
```

Select:

```text
M2
```

The script will:

* Create a new Linux user.
* Add the user to the sudo group.
* Create a home directory inside the jail.
* Generate a custom login shell:

```text
/bin/jailshell_<username>
```

Whenever the user logs in, they will automatically be redirected into:

```text
/var/chroot
```

using:

```bash
chroot --userspec=<username>:<group>
```

The script also synchronizes the required entries from:

```text
/etc/passwd
/etc/group
/etc/shadow
```

into the jail.

### User Requirements

Usernames must:

* Be at least 6 characters long.
* Be no longer than 32 characters.
* Contain only:

  * Letters
  * Numbers
  * Underscores (`_`)

---

# 3. Adding Commands to the Jail

The jail initially contains very few executable programs.

To make commands available inside the jail, edit:

```bash
command_adder.sh
```

Example:

```bash
list=(
    "/bin/bash"
    "/bin/ls"
    "/bin/mkdir"
    "/usr/bin/nano"
)
```

Then run:

```bash
sudo ./command_adder.sh
```

The script will:

1. Copy the executable into the jail.
2. Detect all required shared libraries using:

```bash
ldd
```

3. Copy those libraries into their corresponding locations inside the jail.

After completion, the command becomes available for jailed users.

### Finding Command Paths

Use:

```bash
which nano
which bash
which vim
```

Examples:

```text
/bin/bash
/usr/bin/nano
/usr/bin/vim
```

Different Linux distributions may store binaries in different locations, so always verify the path before adding it.

---

# 4. Removing Commands from the Jail

To remove commands from the jail:

Edit:

```bash
command_remover.sh
```

and specify the same command paths that were previously added.

Example:

```bash
list=(
    "/bin/bash"
    "/usr/bin/nano"
)
```

Then run:

```bash
sudo ./command_remover.sh
```

The script will:

* Remove the executable from the jail.
* Remove the copied shared libraries associated with that executable.

---

# Typical Workflow

## Step 1

Create the jail:

```bash
sudo ./chroot_setup.sh
```

Select:

```text
M1
```

## Step 2

Add commands:

```bash
sudo ./command_adder.sh
```

Example additions:

```bash
"/bin/bash"
"/bin/ls"
"/bin/cat"
"/usr/bin/nano"
```

## Step 3

Create a jailed user:

```bash
sudo ./chroot_setup.sh
```

Select:

```text
M2
```

## Step 4

Log in as the newly created user.

The user should automatically be placed inside:

```text
/var/chroot
```

and only have access to the commands you copied into the jail.

---

# Notes

* These scripts must be run as root.
* The jail is created under:

```text
/var/chroot
```

* Removing and recreating the jail deletes all previously copied commands and jailed user directories.
* Some applications require additional configuration files, devices, or libraries beyond what `ldd` reports.
* If a command does not work inside the jail, verify that all required files and dependencies have been copied.

---

# Warning

This project is intended as a lightweight chroot environment and should not be considered a complete security sandbox.

A properly secured production environment may require additional hardening such as:

* Mount isolation
* Device restrictions
* Capability dropping
* Namespaces
* Containers (LXC/Docker/Podman)
* Mandatory Access Control (AppArmor/SELinux)

Use at your own discretion.
