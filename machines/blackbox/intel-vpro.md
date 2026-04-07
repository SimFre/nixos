

Bridging Tailscale to Intel AMT (vPro) is the ultimate "emergency backup" for a remote appliance. It allows you to reach the BIOS or hardware-level KVM even if NixOS fails to boot or the ZFS pool is corrupted, all without exposing the management interface to the public internet.

On the Lenovo M910q, this requires a specific "Internal Bridge" strategy because the Intel ME (Management Engine) and Tailscale usually live in two different worlds.
1. The Challenge: The "Sidecar" Network

Intel AMT shares the physical Ethernet port with your OS but uses a different MAC address and its own internal IP stack. When your NixOS appliance connects to AzireVPN (Full Tunnel), the OS routing table usually breaks the local path to the AMT interface.
2. The Solution: Tailscale Subnet Router

To reach the vPro interface (which sits on a local IP, e.g., 192.168.1.50) from your laptop anywhere in the world, you configure the NixOS appliance to act as a Tailscale Subnet Router.

In your configuration.nix:
Nix

services.tailscale = {
  enable = true;
  # Allow the appliance to route traffic to the local network (where vPro lives)
  extraUpFlags = [ "--advertise-routes=192.168.1.0/24" ]; 
};

# Enable IP Forwarding so the kernel can pass Tailscale traffic to the AMT interface
boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

3. Step-by-Step Connection Guide
Step A: Configure the MEBx (Hardware Level)

    Reboot the Lenovo and mash Ctrl+P to enter the Intel Management Engine BIOS Extension (MEBx).

    Set a strong password (it usually requires a special character, a number, and a capital letter).

    Enable Network Setup and assign a Static IP (e.g., 192.168.1.50).

        Note: Do not use DHCP for the AMT interface on a headless appliance; it's too risky if the lease fails.

    Enable KVM Redirection.

Step B: Accept the Route in Tailscale

On your Tailscale Admin Console (web-based), find your M910q node:

    Click the "..." menu -> Edit route settings.

    Enable the 192.168.1.0/24 checkbox.
    Now, any device on your Tailscale "Tailnet" can ping 192.168.1.50 as if they were plugged into the same switch.

Step C: The Management Software

Since you are on a "Modern" setup, don't bother with the old Intel proprietary tools. Use MeshCommander (the open-source king of AMT management).

    Install the MeshCommander executable or run the web-based version.

    Add a computer using the static IP (192.168.1.50).

    Click Remote Desktop -> Connect.

4. The "Ghost" Problem (Headless KVM)

As mentioned before, the M910q might show a black screen in the KVM if no monitor is attached.

    The Fix: Plug an HDMI Dummy Plug into the back of the Lenovo. This forces the Intel GPU to stay active, allowing the AMT "tap" to capture the frame buffer.

5. Final Security Hardening for vPro

Since you’ve now made the BIOS reachable over your Tailscale mesh:

    Disable "Small Business Mode": Ensure you are in "Admin Control Mode" (ACM) if possible, which provides higher security levels.

    TLS Only: In the MEBx settings, you can enforce TLS 1.2+ for the management interface so the password isn't sent in the clear inside your Tailscale tunnel (defense in depth).

    Dedicated VLAN (Optional): If your router supports it, put the M910q's Ethernet port on a VLAN that cannot talk to anything except the internet. This prevents a compromised vPro from "lateral movement" inside your home network.



