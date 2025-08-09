local config = require("sherlock.config")

local M = {}

local call_query_string = [[
(call_expression
  function: (member_expression
    object: (identifier) @object (#eq? @object "m")
    property: (property_identifier) @method_name)
  arguments: (arguments)) @call
]]

local ns_id = vim.api.nvim_create_namespace("paraglide_hints")

-- Find project root by looking for package.json
local function find_project_root()
	local current_file = vim.api.nvim_buf_get_name(0)
	if current_file == "" then
		return nil
	end

	local current_dir = vim.fn.fnamemodify(current_file, ":p:h")

	-- Walk up the directory tree looking for package.json
	while current_dir ~= "/" do
		if vim.fn.filereadable(current_dir .. "/package.json") == 1 then
			return current_dir
		end
		current_dir = vim.fn.fnamemodify(current_dir, ":h")
	end

	return nil
end

-- Get the translation file path
local function get_translation_file_path()
	if config.options.custom_path then
		return config.options.custom_path
	end

	local project_root = find_project_root()
	if not project_root then
		return nil
	end

	return project_root .. "/" .. config.options.translation_file_path
end

-- Check if tree-sitter is available
local function check_treesitter()
	local ok, ts = pcall(require, "nvim-treesitter")
	if not ok then
		vim.notify("paraglide-hints: nvim-treesitter is required", vim.log.levels.ERROR)
		return false
	end
	return true
end

function M.get_translation_text(function_name, en_file_path)
	if vim.fn.filereadable(en_file_path) ~= 1 then
		return "Translation file not found"
	end

	local content = vim.fn.readfile(en_file_path)
	local text = table.concat(content, "\n")

	local pattern = "export%s+const%s+" .. function_name .. "%s*=%s*.-return%s+`([^`]*)`"
	local match = text:match(pattern)

	return match or "Translation not found"
end

function M.show()
	if not check_treesitter() then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype

	-- Only work with supported file types
	if filetype ~= "svelte" and filetype ~= "typescript" then
		vim.notify("paraglide-hints: Unsupported filetype: " .. filetype, vim.log.levels.WARN)
		return
	end

	-- Clear existing virtual text
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	local en_file_path = get_translation_file_path()
	if not en_file_path then
		vim.notify("paraglide-hints: Could not find project root or translation file", vim.log.levels.ERROR)
		return
	end

	local function add_virtual_text(tree, lang)
		local ok, query = pcall(vim.treesitter.query.parse, lang, call_query_string)
		if not ok then
			vim.notify("paraglide-hints: Failed to parse tree-sitter query for " .. lang, vim.log.levels.ERROR)
			return
		end

		local root = tree:root()

		for id, node in query:iter_captures(root, bufnr, 0, -1) do
			local name = query.captures[id]
			if name == "method_name" then
				local method_name = vim.treesitter.get_node_text(node, bufnr)
				local translation_text = M.get_translation_text(method_name, en_file_path)
				local row, col = node:start()

				-- Truncate long translations
				if #translation_text > 80 then
					translation_text = translation_text:sub(1, 77) .. "..."
				end

				vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, {
					virt_text = { { config.options.prefix .. translation_text, config.options.highlight_group } },
					virt_text_pos = "eol",
				})
			end
		end
	end

	if filetype == "svelte" then
		local parser = vim.treesitter.get_parser(bufnr, "svelte")
		parser:parse()

		parser:for_each_tree(function(tree, ltree)
			local lang = ltree:lang()
			if lang == "typescript" or lang == "javascript" then
				add_virtual_text(tree, lang)
			end
		end)
	elseif filetype == "typescript" then
		local parser = vim.treesitter.get_parser(bufnr, "typescript")
		local tree = parser:parse()[1]
		add_virtual_text(tree, "typescript")
	end
end

function M.hide()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.toggle()
	local bufnr = vim.api.nvim_get_current_buf()
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})

	if #marks > 0 then
		M.hide()
	else
		M.show()
	end
end

function M.setup(opts)
	config.setup(opts)

	-- Create user commands
	vim.api.nvim_create_user_command("ParaglideShow", M.show, {})
	vim.api.nvim_create_user_command("ParaglideHide", M.hide, {})
	vim.api.nvim_create_user_command("ParaglideToggle", M.toggle, {})
end

return M
