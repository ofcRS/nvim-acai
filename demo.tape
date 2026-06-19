# Generates assets/demo.gif by driving a real nvim against the live model.
# Run from the repo root:  vhs demo.tape
Output assets/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1000
Set Height 560
Set Padding 24
Set Framerate 24
Set TypingSpeed 55ms
Set Theme "TokyoNight"

Hide
Type "cd ~/projects/nvim-acai && /Users/shck/.local/share/mise/installs/neovim/latest/bin/nvim -u demo_init.lua demo.ts"
Enter
Sleep 4s
# Warm the endpoint so the first VISIBLE beat is a fast (warm) call, then
# delete the throwaway line so the buffer is clean again.
Type "Gowarm "
Sleep 6s
Escape
Type "dd"
Sleep 800ms
Show

# Beat 1 — basic completion: ghost -> a + b
Type "G"
Sleep 300ms
Type "o"
Type "const add = (a: number, b: number) => "
Sleep 4s
Ctrl+L
Sleep 1400ms
Escape
Sleep 500ms

# Beat 2 — comment-driven, value-aware: ghost -> users.find(... "Ada Lovelace")
Type "o"
Enter
Type "// find the user named Ada"
Enter
Type "const ada = "
Sleep 4s
Ctrl+L
Sleep 1400ms
Escape
Sleep 500ms

# Beat 3 — comment-driven: ghost -> users.map(u => u.email)
Type "o"
Enter
Type "// get every user's email address"
Enter
Type "const emails = "
Sleep 4s
Ctrl+L
Sleep 1400ms
Escape
Sleep 2s
