# WIP: Sherlock (inlang) like utils for nvim

Sort of working proof of concept.

Allows to visualize the message contents from a key inline as a comment or
floating text.

```ts
const hello = m.hello() // Hello world!
```

And also extracting messages, by selecting a string literal (only string
literals supported at the moment) and executing the key binding. It will
auto-generate a key based on the text, and enters the key into the `en.json`
(assumes en is the default locale). In fact, it assumes many things at the
moment :)

Requires:

- `treesitter.nvim`
- python3 installed system-wide

Only works in `ts` and `svelte` files at the moment.

Minimal configuration (LazyVim)

```lua
return {
  "bernatGene/sherlock.nvim",
  ft = { "svelte", "typescript" }, -- Only load for these filetypes
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("sherlock").setup({
      translation_file_path = "src/lib/paraglide/messages/en.js", -- path relative to package.json
      highlight_group = "DiagnosticInfo", -- Comment/DiagnosticInfo whatever
      prefix = " >> ", -- prefix the floating text
    })

    -- toggle the text. needs to rerun if keys change values
    vim.keymap.set("n", "<leader>tp", "<cmd>ParaglideToggle<cr>", { desc = "Toggle paraglide hints" })

    -- extract_translation
    vim.keymap.set("v", "<leader>te", function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
      vim.schedule(function()
        require("sherlock").extract_translation()
      end)
    end, { desc = "Extract translation" })
  end,
}
```
