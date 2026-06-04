import QtQuick
import Quickshell
import "."

Picker {
    id: root

    open: WorktreeCreatePickerState.open
    onCloseRequested: WorktreeCreatePickerState.open = false

    placeholder: "new wt name"
    freeText: true
    altLabel: "Enter: create worktree (kitty opens for claude mode picker)"

    onEnterText: text => {
        const name = text.replace(/[^a-zA-Z0-9-]/g, "")
        if (name.length === 0) return
        const safeName = name.replace(/'/g, "'\\''")
        const inner =
            "set -e; " +
            "mode=$(printf 'new\\nresume\\nfork\\n' | fzf --prompt='claude session> ' --height=8 --reverse --no-sort); " +
            "[ -z \"${mode:-}\" ] && mode=new; " +
            "args=( '" + safeName + "' --mode \"$mode\" ); " +
            "if [ \"$mode\" != 'new' ]; then " +
            "  sid=$(\"$HOME/.config/niri/scripts/spawn-claude-session-picker\" --id-only); " +
            "  [ -z \"${sid:-}\" ] && exit 0; " +
            "  args+=( --session-id \"$sid\" ); " +
            "fi; " +
            "\"$HOME/.config/niri/scripts/ws-createwt\" \"${args[@]}\" 2>&1 | tee -a /tmp/ws-spawn.log"

        Quickshell.execDetached(["kitty", "--class", "lovable_picker", "bash", "-c", inner])
    }
}
