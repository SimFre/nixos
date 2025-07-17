
# Rough notes to get wsl to use Pageant for SSH keys.

Info: https://sxda.io/posts/sharing-ssh-agent-wsl/
Info: https://github.com/jkwmoore/setup_Windows_ssh_Pagent_agent_and_WSL2_ssh_agent_support


# Install appplications
winget install PuTTY.PuTTY
winget install albertony.npiperelay
mkdir %USERPROFILE%\.ssh

# Create Pageant in autostart
$WshShell = New-Object -ComObject WScript.Shell
$StartupFolder = [Environment]::GetFolderPath("Startup")
$Shortcut = $WshShell.CreateShortcut("$StartupFolder\\Pageant.lnk")
$Shortcut.TargetPath = "$env:ProgramFiles\\PuTTY\\pageant.exe"
$Shortcut.Arguments = "--openssh-config `"$env:USERPROFILE\\.ssh\\pageant.conf`""
$Shortcut.WorkingDirectory = "$env:ProgramFiles\\PuTTY"
$Shortcut.IconLocation = "$env:ProgramFiles\\PuTTY\\pageant.exe"
$Shortcut.Save()


Prereq: wget socat unzip

In Nix:
mkdir -p ~/.local/bin
ln -s `wslpath "$(powershell.exe -Command '(Get-Command npiperelay).Source')" | tr -d '\r'` ~/.local/bin/npiperelay.exe



----
  # In Windows: winget install winssh-pageant
  # it installs to %localappdata%\Programs\WinSSH-Pageant
  # and creates a shortcut in Startup
  # SSH Pipe: \\.\pipe\openssh-ssh-agent


  # "C:\Program Files\PuTTY\pageant.exe" --openssh-config %USERPROFILE%\.ssh\pageant_win.conf --unix %USERPROFILE%\.ssh\pageant_nix.sock
  # nix: wget latest binary from https://github.com/albertony/npiperelay
  
----



mkdir -p ~/.config/systemd/user/
cat <<EOF > ~/.config/systemd/user/named-pipe-ssh-agent.socket
[Unit]
Description=SSH Agent provided by Windows named pipe \\.\pipe\openssh-ssh-agent

[Socket]
ListenStream=%t/ssh/ssh-agent.sock
SocketMode=0600
DirectoryMode=0700
Accept=true

[Install]
WantedBy=sockets.target
EOF








socat EXEC:"/mnt/c/Users/$USERNAME/.ssh/npiperelay.exe ${PIPE_PATH}" UNIX-LISTEN:/tmp/ssh-agent.sock,unlink-close,unlink-early,fork

-- cat > ~/.config/systemd/user/ssh-agent-pageant.service <<'EOF'
[Unit]
Description=Socat SSH Agent Forwarding for Pageant
After=network.target

[Service]

ExecStart=/bin/bash ${HOME}/.config/systemd/user/start-ssh-agent-pageant-pipe.sh
Restart=always
StandardOutput=file:/tmp/ssh-agent-pageant-output.log
StandardError=file:/tmp/ssh-agent-pageant-error.log

[Install]
WantedBy=default.target



