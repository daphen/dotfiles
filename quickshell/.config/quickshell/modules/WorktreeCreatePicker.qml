import QtQuick
import Quickshell
import "."

Picker {
    id: root

    open: WorktreeCreatePickerState.open
    onCloseRequested: WorktreeCreatePickerState.open = false

    placeholder: "new workspace name (e.g. 1905-infer-path-b-source-type)"
    freeText: true
    altLabel: "Enter: pick local worktree or Lovable-on-Lovable, then provide details"

    onEnterText: text => {
        const name = text.replace(/[^a-zA-Z0-9-]/g, "")
        if (name.length === 0) return
        const safeName = name.replace(/'/g, "'\\''")
        const inner =
            "set -e; " +
            "NAME='" + safeName + "'; " +
            "kind=$(printf 'local-worktree\\nlovable-on-lovable\\n' | fzf --prompt='workspace type> ' --height=8 --reverse --no-sort); " +
            "[ -z \"${kind:-}\" ] && exit 0; " +
            "if [ \"$kind\" = 'local-worktree' ]; then " +
            "  mode=$(printf 'new\\nresume\\nfork\\n' | fzf --prompt='claude session> ' --height=8 --reverse --no-sort); " +
            "  [ -z \"${mode:-}\" ] && mode=new; " +
            "  args=( \"$NAME\" --mode \"$mode\" ); " +
            "  if [ \"$mode\" != 'new' ]; then " +
            "    sid=$(\"$HOME/.config/niri/scripts/spawn-claude-session-picker\" --id-only); " +
            "    [ -z \"${sid:-}\" ] && exit 0; " +
            "    args+=( --session-id \"$sid\" ); " +
            "  fi; " +
            "  \"$HOME/.config/niri/scripts/ws-createwt\" \"${args[@]}\" 2>&1 | tee -a /tmp/ws-spawn.log; " +
            "else " +
            "  \"$HOME/.config/niri/scripts/ws-newlol\" \"$NAME\"; " +
            "  echo; echo 'In the browser: create the project, copy the URL, paste it here:'; " +
            "  read -r url; " +
            "  [ -z \"${url:-}\" ] && { echo 'no URL, aborting'; sleep 2; exit 1; }; " +
            "  \"$HOME/.config/niri/scripts/ws-createlovbox\" \"$NAME\" \"$url\" 2>&1 | tee -a /tmp/ws-spawn.log; " +
            "fi"

        Quickshell.execDetached(["kitty", "--class", "lovable_picker", "bash", "-c", inner])
    }
}
