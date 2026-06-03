---@class ScaffoldContext
---@field buf integer
---@field path string
---@field root string
---@field stem string
---@field ext string

---@class ScaffoldResult
---@field lines string[]
---@field cursor? { line: integer, col?: integer }

---@class ScaffoldRenameContext
---@field buf integer
---@field path string
---@field old_symbol string
---@field new_symbol string
---@field old_stem string

---@class ScaffoldRenameProvider
---@field symbol_at_cursor fun(buf: integer): string|nil
---@field should_rename_file fun(ctx: ScaffoldRenameContext): boolean
---@field new_path fun(ctx: ScaffoldRenameContext): string

---@class ScaffoldFileMoveExpected
---@field namespace string
---@field symbol string
---@field kind string

---@alias ScaffoldTransferMode "move" | "copy"

---@class ScaffoldFilePair
---@field from string
---@field to string

---@class ScaffoldFileMoveContext
---@field operation ScaffoldTransferMode
---@field from string
---@field to string
---@field old_stem string
---@field new_stem string
---@field buf integer|nil

---@class ScaffoldFileMoveProvider
---@field should_handle fun(ctx: ScaffoldFileMoveContext): boolean
---@field expected fun(ctx: ScaffoldFileMoveContext): ScaffoldFileMoveExpected|nil
---@field sync_buffer fun(ctx: ScaffoldFileMoveContext, expected: ScaffoldFileMoveExpected): boolean

---@class ScaffoldProvider
---@field filetypes string[]
---@field extensions? string[]
---@field should_scaffold? fun(buf: integer): boolean
---@field build fun(ctx: ScaffoldContext): ScaffoldResult|nil
---@field rename? ScaffoldRenameProvider
---@field file_move? ScaffoldFileMoveProvider

---@class ScaffoldRenamePending
---@field provider ScaffoldProvider
---@field old_symbol string|nil
---@field old_stem string
---@field path string

return {}
