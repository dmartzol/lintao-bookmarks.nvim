local repo = require("bookmarks.repo")
local api = require("bookmarks.api")
local vimui = require("bookmarks.adapter.vim-ui")
local picker = require("bookmarks.adapter.picker")

---@class Bookmark.Command
---@field name string
---@field callback fun(): nil
---@field description? string

-- TODO: a helper function to generate this structure to markdown table to put into README file

---@type Bookmark.Command[]
local commands = {
	{
		name = "[List] new",
		callback = function()
			local newlist = api.add_list({ name = tostring(os.time()) })
			-- TODO: ask user to input name
			api.mark({ name = "", list_name = newlist.name })
		end,
		description = "create a new BookmarkList and set it to active and mark current line into this BookmarkList",
	},
	{
		name = "[List] delete",
		callback = function()
			local bookmark_lists = repo.get_domains()

			vim.ui.select(bookmark_lists, {
				prompt = "Select the bookmark list you want to delete",
				format_item = function(item)
					---@cast item Bookmarks.BookmarkList
					return item.name
				end,
			}, function(choice)
				---@cast choice Bookmarks.BookmarkList
				if not choice then
					return
				end
				vim.ui.input(
					{ prompt = "Are you sure you want to delete list" .. choice.name .. "? Y/N" },
					function(input)
						if input == "Y" then
							repo.delete_bookmark_list(choice.name)
							vim.notify(choice.name .. " list deleted")
						else
							vim.notify("deletion abort")
							return
						end
					end
				)
			end)
		end,
		description = "delete a bookmark list",
	},
	{
		name = "[List] set active",
		callback = function()
			-- TODO: should I have this dependency in this module?
			vimui.set_active_list()
		end,
		description = "set a BookmarkList as active",
	},
	{
		name = "[Mark] mark to list",
		callback = function()
			picker.pick_bookmark_list(function(choice)
				api.mark({
					name = "", -- TODO: ask user to input name?
					list_name = choice.name,
				})
			end)
		end,
		description = "bookmark current line and add it to specific bookmark list",
	},
	{
		name = "[Mark] rename bookmark",
		callback = function()
			picker.pick_bookmark(function(bookmark)
				vim.ui.input({ prompt = "New name of the bookmark" }, function(input)
					api.rename_bookmark(bookmark.id, input or "")
				end)
			end)
		end,
		description = "rename selected bookmark",
	},
	{
		name = "[Mark] Browsing all",
		callback = function()
			picker.pick_bookmark_list(function(bookmark_list)
				picker.pick_bookmark(function(bookmark)
					api.goto_bookmark(bookmark, { open_method = "vsplit" })
				end, { bookmark_list = bookmark_list })
			end)
		end,
		description = "",
	},
}

return {
	commands = commands,
}
