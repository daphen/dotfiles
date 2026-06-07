return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = true,
	event = {
		"BufReadPre " .. vim.fn.expand("~") .. "/personal/notes/storage/**.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/personal/notes/storage/**.md",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/personal/notes/storage",
			},
		},

		-- frontmatter convention — keep aligned with the categorisation
		-- scheme in SYSTEM.md / the obsidian app config.
		new_notes_location = "notes_subdir",
		notes_subdir = "inbox",
		daily_notes = {
			folder = "journal",
			date_format = "%Y-%m-%d",
			default_tags = { "daily" },
		},

		-- wikilinks: prefer markdown-style links so files stay portable
		-- and the vault works fine outside Obsidian-flavoured tools.
		preferred_link_style = "wiki",
		wiki_link_func = "use_alias_only",

		-- completion via nvim-cmp when wikilinking
		completion = {
			nvim_cmp = true,
			min_chars = 2,
		},

		-- open files from Obsidian's "tags" or "links" picker in nvim
		picker = {
			name = "telescope.nvim",
		},

		-- generate sensible frontmatter on new notes
		note_frontmatter_func = function(note)
			return {
				type = note.metadata and note.metadata.type or "note",
				status = note.metadata and note.metadata.status or "active",
				tags = note.tags,
				created = os.date("%Y-%m-%d"),
			}
		end,

		-- open `obsidian://` URIs in the real Obsidian app when desired
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url })
		end,
	},
	keys = {
		{ "<leader>oo", "<cmd>ObsidianOpen<cr>",        desc = "Obsidian: open in app" },
		{ "<leader>on", "<cmd>ObsidianNew<cr>",         desc = "Obsidian: new note" },
		{ "<leader>od", "<cmd>ObsidianToday<cr>",       desc = "Obsidian: today's journal" },
		{ "<leader>oy", "<cmd>ObsidianYesterday<cr>",   desc = "Obsidian: yesterday's journal" },
		{ "<leader>ot", "<cmd>ObsidianTomorrow<cr>",    desc = "Obsidian: tomorrow's journal" },
		{ "<leader>os", "<cmd>ObsidianSearch<cr>",      desc = "Obsidian: full-text search" },
		{ "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: quick switch" },
		{ "<leader>ob", "<cmd>ObsidianBacklinks<cr>",   desc = "Obsidian: show backlinks" },
		{ "<leader>oT", "<cmd>ObsidianTags<cr>",        desc = "Obsidian: list tags" },
		{ "<leader>or", "<cmd>ObsidianRename<cr>",      desc = "Obsidian: rename + update links" },
		{ "gf",         "<cmd>ObsidianFollowLink<cr>",  desc = "Obsidian: follow link under cursor", ft = "markdown" },
	},
}
