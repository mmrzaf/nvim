for _, p in ipairs({
	"gzip",
	"zip",
	"zipPlugin",
	"tar",
	"tarPlugin",
	"getscript",
	"getscriptPlugin",
	"vimball",
	"vimballPlugin",
	"2html_plugin",
	"logipat",
	"rrhelper",
	"spellfile_plugin",
	"matchit",
	"matchparen",
	-- netrw family — comment out if you rely on :Ex or net-based reads
	"netrw",
	"netrwPlugin",
	"netrwSettings",
	"netrwFileHandlers",
	-- legacy providers (speed): enable one by setting to 0 here and installing the tool
	"python3_provider",
	"node_provider",
	"ruby_provider",
	"perl_provider",
}) do
	vim.g["loaded_" .. p] = 1
end
