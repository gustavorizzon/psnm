# PowerShell Simple Node Manager

This tool is designed to simplify the management of Node.js versions on your system. With PowerShell Simple Node Manager, you can easily install, switch, and manage multiple versions of Node.js with just a few commands.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Commands](#commands)

### Getting Started

To get started with PowerShell Simple Node Manager, follow these steps:

1. Clone the repository:

   ```powershell
   git clone https://github.com/gustavorizzon/psnm.git $HOME\.psnm
   ```

2. Add an entry to your PowerShell profile to create an alias for the PowerShell Simple Node Manager:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   if (-not (Test-Path $profile)) { New-Item $profile -Force }
   Add-Content -Path $profile -Value "Set-Alias psnm $HOME\.psnm\bin\psnm.ps1"
   ```

3. Restart your PowerShell session to apply the changes made to your profile.

### Commands

| Command                  | Description                                                |
| ------------------------ | ---------------------------------------------------------- |
| `psnm use <version>`     | Switches to the specified version of Node.js.              |
| `psnm ls`                | Lists all installed versions of Node.js.                   |
| `psnm ls-remote`         | Lists all available versions of Node.js.                   |
| `psnm install <version>` | Installs the specified version of Node.js from your system |
| `psnm remove <version>`  | Removes the specified version of Node.js from your system  |
