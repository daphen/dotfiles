# Managing Apps: Local vs Managed

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│  Is ~/.config/app a SYMLINK?                                │
│                                                             │
│  YES → Managed (deployed by home-manager)                  │
│  NO  → Local (machine-specific, not version controlled)    │
└─────────────────────────────────────────────────────────────┘
```

## The Complete Flow

### 🆕 Scenario 1: You Found a New Tool

```
1. Install the tool
   └─> pacman -S newtool / nix-env -iA newtool

2. Configure it normally
   └─> Creates ~/.config/newtool/config
   └─> Edit and tweak until you like it

3. DECISION POINT: Keep local or make managed?

   Option A: Keep Local (Machine-Specific)
   ├─> Do nothing!
   ├─> Config stays in ~/.config/newtool/
   ├─> Not version controlled
   └─> Won't sync to other machines
   
   Option B: Make Managed (Version Controlled)
   ├─> Run: bash /tmp/promote-app-to-managed.sh newtool
   ├─> Add home-manager configuration
   ├─> Rebuild: sudo nixos-rebuild switch
   ├─> Now ~/.config/newtool/ is symlinked
   └─> Automatically backed up in git!
```

### 🎨 Scenario 2: Adding Theme Support

```
After making an app managed, optionally add theme support:

1. Create theme template
   └─> ~/dotfiles/themes/.config/themes/templates/newtool.template

2. Template uses placeholders like:
   └─> background={{background.primary}}
   └─> foreground={{foreground.primary}}

3. Theme generator creates:
   └─> generated/newtool/dark.theme
   └─> generated/newtool/light.theme

4. Theme manager applies to:
   └─> ~/dotfiles/newtool/.config/newtool/theme.conf
   └─> (Instantly visible in ~/.config via symlink)
```

### 🔄 Scenario 3: Editing Managed App Config

```
When app is MANAGED:

1. Edit in ~/.config/newtool/config
   └─> (Following the symlink)

2. Changes automatically go to:
   └─> ~/dotfiles/newtool/.config/newtool/config

3. Commit to git:
   └─> cd ~/dotfiles
   └─> git add newtool
   └─> git commit -m "Update newtool config"
   └─> git push

4. On another machine:
   └─> git pull
   └─> sudo nixos-rebuild switch
   └─> ✓ Config synced!
```

### 📦 Scenario 4: New Machine Setup

```
On a brand new NixOS machine:

1. Clone dotfiles:
   └─> git clone https://github.com/you/dotfiles ~/dotfiles

2. Set up home-manager with all managed apps

3. Run nixos-rebuild:
   └─> sudo nixos-rebuild switch

4. All managed apps automatically:
   ├─> Symlinked to ~/dotfiles
   ├─> Configs deployed
   └─> Themes applied

No manual copying needed! 🎉
```

## Examples from Your System

### Currently Managed ✓
- **kitty** - Terminal emulator (you use daily)
- **nvim** - Editor (essential, want on all machines)
- **waybar** - Status bar (part of your WM setup)
- **rofi** - Launcher (part of your workflow)
- **qutebrowser** - Browser (custom config)

### Currently Local (Not Managed)
- **mako** - Notifications (exists in dotfiles but not deployed yet)
- **opencode** - AI assistant (exists in dotfiles but not deployed yet)
- **clipse** - Clipboard (exists in dotfiles but not deployed yet)
- **ghostty** - Terminal (testing/experimental)
- **1Password** - Contains secrets/machine-specific
- **google-chrome** - Generic browser, no custom config

## Decision Examples

| Tool | Managed? | Reason |
|------|----------|--------|
| **nvim** | ✅ Yes | Use on all machines, heavily customized |
| **kitty** | ✅ Yes | Primary terminal, custom theme |
| **mako** | ⏳ Should be | Want consistent notifications everywhere |
| **lazygit** | ❌ No | Machine-specific git repos |
| **google-chrome** | ❌ No | Synced via Google account |
| **1Password** | ❌ No | Contains secrets, different per machine |

## Tools to Help

1. **Check status**: `bash /tmp/check-managed-status.sh`
2. **Promote to managed**: `bash /tmp/promote-app-to-managed.sh <app-name>`
3. **Verify symlink**: `ls -la ~/.config/<app-name>`
4. **Check theme support**: `ls ~/dotfiles/themes/.config/themes/templates/<app-name>.template`

## Pro Tips

💡 **Start local, promote when stable**
   - Install and configure in ~/.config first
   - Once happy with config, promote to managed

💡 **Use .gitignore for secrets**
   - If an app config has secrets, add to .gitignore
   - Or use sops-nix/agenix for encrypted secrets

💡 **Not everything needs to be managed**
   - Browser profiles synced by account → keep local
   - Machine-specific paths/settings → keep local
   - Testing/experimental tools → keep local

💡 **Managed apps get free theme updates**
   - If app has a template, theme switching is automatic
   - No manual config needed, just `theme-manager.sh toggle`
