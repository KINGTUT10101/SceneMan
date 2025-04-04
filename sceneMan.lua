---@class SceneManager
local sceneMan = {
    ---@type table<string, table> All created scenes will be stored here.
    scenes = {},
    ---@type table<integer, table> Scenes that are pushed will be stored here.
    stack = {},
    ---@type table<any, any> Stores variables that are shared between scenes.
    shared = {},
    ---@type table<string, table> Stores saved stacks so they can be restored later.
    saved = {},
    ---@type table<integer, table> Stores the scene stack when the original scene stack is disabled.
    buffer = {},
    ---@type boolean If true, the buffer will be used instead of the original stack.
    frozen = false,
    ---@type integer The highest level of the stack that is locked.
    lockLevel = 0,
    ---@type string The version of Scene Manager being used.
    version = "1.4.1",
}

--- Returns either the buffer or the stack based on the value of `sceneMan.frozen`.
---@return table<integer, table> sceneArr The buffer if the frozen flag is true, otherwise the stack.
local function getStack ()
    return (sceneMan.frozen == true) and sceneMan.buffer or sceneMan.stack
end

--- Redirects stack-altering operations into the buffer instead.
function sceneMan:freeze ()
    if self.frozen == false then
        self.buffer = {} -- Resets the buffer

        -- Copies the stack into the buffer
        for i = 1, #self.stack do
            self.buffer[i] = self.stack[i]
        end
        self.frozen = true
    end
end

--- Copies changes from the buffer back into the original stack.
function sceneMan:unfreeze ()
    if self.frozen == true then
        self.stack = {} -- Resets the stack

        -- Copies the buffer back into the stack
        for i = 1, #self.buffer do
            self.stack[i] = self.buffer[i]
        end
        self.frozen = false
    end
end

--- Saves the current contents of the stack so it can be restored later.
-- This will save the frozen buffer if the stack is frozen
-- This will not modify the current stack in any way
-- @param id (string) A unique ID that will be used to identify the saved stack. It will override anything currently stored at that ID

--- Saves the current contents of the stack so it can be restored later.
--- This will save the frozen buffer if the stack is frozen.
--- This will not modify the current stack in any way.
---@param id string A unique ID to identify the saved stack. Overrides any existing entry at this ID.
function sceneMan:saveStack (id)
    local stack = getStack ()
    local savedStack = {}

    for i = 1, #stack do
        savedStack[i] = stack[i].name
    end

    self.saved[id] = savedStack
end

--- Loads a stack from the saved table.
-- This will call the loaded scenes' "whenAdded" methods
-- @param id (string) A unique ID that identifies the stack that should be restored
-- @param ... (varargs) A list of values that will be passed to the event's "whenAdded" callback function
-- @return (bool) True if the stored stack at the given ID exists and if the current stack is empty, otherwise false

--- Restores a saved stack from storage.
--- This will call the loaded scenes' "whenAdded" methods.
---@param id string A unique ID identifying the stack to restore.
---@vararg any Values passed to the "whenAdded" callback function of scenes.
---@return boolean success True if restoration succeeded (stack exists and current stack is empty), false otherwise.
function sceneMan:restoreStack (id, ...)
    local stack = getStack ()
    local savedStack = self.saved[id]

    if savedStack == nil or #stack ~= 0 then
        return false
    else
        for i = 1, #savedStack do
            self:push (savedStack[i], ...)
        end

        return true
    end
end

--- Deletes a saved stack permanently.
--- Does not affect scenes in the current stack, even if it was restored using the to-be-deleted stack.
--- This will not *delete* the scenes in the stack.
---@param id string A unique ID identifying the saved stack to delete.
function sceneMan:deleteStack (id)
    self.saved[id] = nil
end

--- Locks the stack up to a specified level.
--- Locked scenes skip their event callbacks except "whenAdded", "whenRemoved", or "deleted".
---@param level integer The level to lock up to (bottommost item is at level 1).
function sceneMan:lock (level)
    self.lockLevel = level
end

--- Unlocks all levels in the stack, allowing all scenes to execute their event callbacks again.
function sceneMan:unlock ()
    self.lockLevel = 0
end

--- Gets the current lock level of the stack.
---@return integer level The current lock level.
function sceneMan:getLockLevel ()
    return self.lockLevel
end

--- Adds a new scene and initializes it via its `load` method.
---@param name string Name of the new scene (used for later operations like push/remove).
---@param scene table Table containing attributes and callback functions of the scene.
---@vararg any Values passed to the `load` callback function of this scene.
function sceneMan:newScene (name, scene, ...)
    self.scenes[name] = scene
    self.scenes[name].name = name
    if self.scenes[name].load ~= nil then
        self.scenes[name]:load (...)
    end
end

--- Deletes a registered scene and calls its `delete` method. Deleted scenes cannot be pushed or inserted again.
---@param name string Name of the scene to delete.
---@vararg any Values passed to the `delete` callback function of this scene.
function sceneMan:deleteScene (name, ...)
    if self.scenes[name] ~= nil then
        if self.scenes[name].delete ~= nil then
            self.scenes[name]:delete (...)
        end
        self.scenes[name] = nil
    end
end

--- Gets the current size of the stack.
---@return integer size The size of the stack (number of scenes).
function sceneMan:getStackSize ()
    return #self.stack
end

--- Gets the name of the current topmost scene on the stack. Returns nil if no scenes exist in it (ignores frozen buffer).
---@return string|nil sceneName Name of topmost scene or nil if empty.
function sceneMan:getCurrentScene ()
    return (#self.stack >= 1) and self.stack[#self.stack].name or nil
end

--- Pushes a registered scene onto the top of the stack and calls its `whenAdded` method.
--- Scenes at the top of the stack will have their functions called last
---@param name string Name of registered scene to push onto stack.
---@vararg any Values passed to `whenAdded` callback function of this scene.
function sceneMan:push (name, ...)
    local stack = getStack ()
    
    if self.scenes[name] == nil then
        error ('Attempt to enter undefined scene "' .. name .. '"')
    end
    
    stack[#stack + 1] = self.scenes[name]
    if self.scenes[name].whenAdded ~= nil then
        self.scenes[name]:whenAdded (...)
    end
end

--- Pops a scene off of the stack.
--- This will call the topmost scene's `whenRemoved` method.
---@vararg any Values passed to the `whenRemoved` callback function of this scene.
function sceneMan:pop (...)
    local stack = getStack ()
    
    if #stack >= 1 then
        local temp = stack[#stack]
        stack[#stack] = nil
        if temp.whenRemoved ~= nil then
            temp:whenRemoved (...)
        end
    end
end

--- Adds a scene to the stack at a given index.
--- This will call the scene's `whenAdded` method.
---@param name string The name of the scene to add to the stack.
---@param index integer The position within the stack that the scene should be inserted at.
---@vararg any Values passed to the `whenAdded` callback function of this scene.
---@return boolean success True if the operation was successful, false otherwise.
function sceneMan:insert (name, index, ...)
    local stack = getStack ()
    
    if self.scenes[name] == nil then
        error ('Attempt to enter undefined scene "' .. name .. '"')
    end
    
    if index >= 1 and index <= #stack then
        table.insert (stack, index, name)
        if self.scenes[name].whenAdded ~= nil then
            self.scenes[name]:whenAdded (...)
        end
        return true
    end
    return false
end

--- Removes a scene from the stack at a certain index.
--- This will call the scene's `whenRemoved` method.
---@param index integer The position within the stack that the scene should be removed at.
---@vararg any Values passed to the `whenRemoved` callback function of this scene.
---@return boolean success True if the operation was successful, false otherwise.
function sceneMan:remove (index, ...)
    local stack = getStack ()
    
    if index >= 1 and index <= #stack then
        local temp = stack[index]
        table.remove (stack, index)
        if temp.whenRemoved ~= nil then
            temp:whenRemoved (...)
        end
    end
end

--- Removes all scenes from the stack, starting at the top.
--- This will call all the scenes' `whenRemoved` methods, starting from the topmost scene.
--- This will automatically freeze the stack until all scenes have been iterated over.
---@vararg any Values passed to the `whenRemoved` callback function of this scene.
function sceneMan:clearStack (...)
    local prefrozen = self.frozen
    self:freeze ()
    self.buffer = {}
    
    for i = #self.stack, 1, -1 do
        if self.stack[i].whenRemoved ~= nil then
            self.stack[i]:whenRemoved (...)
        end
    end

    if prefrozen == false then
        self:unfreeze ()
    end
end

--- Removes all scenes from the unlocked portion of the stack, starting at the top.
--- This will call all the scenes' `whenRemoved` methods, starting from the topmost scene.
--- This will automatically freeze the stack until all scenes have been iterated over.
---@vararg any Values passed to the `whenRemoved` callback function of this scene.
function sceneMan:clearUnlockedStack (...)
    local prefrozen = self.frozen
    self:freeze ()
    self.buffer = {}
    
    for i = #self.stack, math.max (self.lockLevel + 1, 1), -1 do
        if self.stack[i].whenRemoved ~= nil then
            self.stack[i]:whenRemoved (...)
        end
    end

    if prefrozen == false then
        self:unfreeze ()
    end
end

--- Fires an event callback for all scenes on the stack.
--- This will automatically freeze the stack until all scenes have been iterated over.
---@param eventName string The name of the event.
---@vararg any Values passed to the scenes' event callbacks.
function sceneMan:event (eventName, ...)
    local prefrozen = self.frozen
    self:freeze ()

    for i = math.max (self.lockLevel + 1, 1), #self.stack do
        local scene = self.stack[i]
        if scene[eventName] ~= nil then
            scene[eventName] (scene, ...)
        end
        if i >= #self.stack then
            break
        end
    end

    if prefrozen == false then
        self:unfreeze ()
    end
end

return sceneMan
