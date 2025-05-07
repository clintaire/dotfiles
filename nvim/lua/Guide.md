# Neovim Configuration Guide

This guide explains how to use the keyboard shortcuts (keybindings) in your Neovim configuration.

## Important Note

The `<leader>` key mentioned below is set to `,` (comma) in your configuration.

---

## Basic Navigation

### Moving Around

- `j` - Move down one line
- `k` - Move up one line
- `h` - Move left
- `l` - Move right

### Between Windows (Splits)

- `Ctrl + h` - Move to the left window
- `Ctrl + j` - Move to the bottom window
- `Ctrl + k` - Move to the top window
- `Ctrl + l` - Move to the right window

### Between Files (Buffers)

- `Tab` - Go to next file
- `Shift + Tab` - Go to previous file

---

## Common Actions

### Save and Quit

- `,w` - Save file
- `,q` - Quit
- `,Q` - Force quit (without saving)

### Escape from Insert Mode

- `jk` - Exit insert mode (alternative to Escape key)
- `Escape` - Exit insert mode

---

## Text Editing

### Moving Lines

Select lines in visual mode (press `v` and move), then:

- `J` - Move selected lines down
- `K` - Move selected lines up

### Spell Checking

- `,s` or `,ts` - Toggle spell checking on/off
- `z=` - Show spelling suggestions for word under cursor

---

## Running Code

### Code Execution

- `,r` - Run current code file
- `,rf` - Run current file
- `,rp` - Run current project
- `,rc` - Close the runner window

### Debugging

- `,db` - Toggle breakpoint at current line
- `,dc` - Start/continue debugging
- `,di` - Step into function
- `,do` - Step over (execute current line)
- `,dt` - Terminate debugging session
- `,du` - Toggle debugging UI

---

## Other Features

### Window Management

- `Ctrl + Up Arrow` - Make window taller
- `Ctrl + Down Arrow` - Make window shorter
- `Ctrl + Right Arrow` - Make window wider
- `Ctrl + Left Arrow` - Make window narrower

### Other Tools

- `,ut` - Toggle Undo Tree (view history of changes)

---

## Getting Started Tips

- Start with the basics: navigation and saving files
- Practice using `,w` to save often
- Use `jk` to exit insert mode (easier than reaching for Escape)
- Try `,r` to run your code after writing it
- Remember: Neovim works in different "modes" - most commands work in "Normal mode" (press `Escape` or `jk` to make sure you're in Normal mode).

## Where to Find These Settings

All keyboard shortcuts are defined in the `mappings.lua` file located at:
`/home/$USER/.config/nvim/lua/core/mappings.lua`

- Code execution commands: Around line 60
- Debugging commands: Around line 64
