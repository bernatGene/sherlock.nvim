local M = {}

M.defaults = {
	-- Default path relative to project root
	translation_file_path = "src/lib/paraglide/messages/en.js",
	-- Custom path (takes precedence if set)
	custom_path = nil,
	-- Highlight group for virtual text
	highlight_group = "Comment",
	-- Virtual text prefix
	prefix = " // ",
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
