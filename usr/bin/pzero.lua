local shell = require("shell")
local fs = require("filesystem")

local args, ops = shell.parse(...)

local dir_struct = {
    branch = {
        master = {},
        history = true
    }
}

-- print() that obeys the ops.silent switch
local function hush(str)
    if not ops.silent then
        print(str)
    end
end

-- Prints an error message and terminates the program
local function except(arg, message)
    if not ops.silent then
        print(message..": --"..arg)
    end
    os.exit(1)
end

-- Creates a directory structure
local function createTree(tbl, path)
    path = path or ""
    for k, v in pairs(tbl) do
        if type(v) == "table" then createTree(v, path.."/"..k)
        elseif type(v) == "boolean" then fs.makeDirectory(path.."/"..k) end
    end
end

-- Returns val if arg is nil or true
local function default(arg, val)
    if not ops[arg] then
        return val
    elseif ops[arg] == true then
        except("Missing value", val)
    end
    return ops[arg]
end

local actions = {}

-- Initialize a clean repo at path with defaults
function actions.init()
    ops.path = shell.resolve(default("path", os.getenv("PWD")))
    if fs.exists(ops.path) and not ops.force then
        except("Repository already initiated", "Error")
    end

    fs.remove(ops.path.."/.pz")
    createTree(dir_struct, ops.path.."/.pz")

    local fh, err = io.open(ops.path.."/.pz/state.tbl", "w")
    if fh then fh:write("{branch='master',origin='..',deps={}}")
    else except(ops.path.."/.pz/state.tbl", err) end
    return "Initiated a clean local repository on branch 'master'"
end


function actions.help()
    local str = "Invalid action\nAvailable actions: "
    for k, v in pairs(actions) do
        if type(v) == "function" then str = str..", "..k end
    end
    return str:sub(1, -3)
end

local function parse()
    if args[1] and actions[args[1]] then
        return actions[args[1]]()
    else
        return actions.help()
    end
end

local res = parse()
hush(res)