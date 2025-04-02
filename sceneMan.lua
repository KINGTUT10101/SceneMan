local sceneMan = {
    scenes = {}, -- All created scenes will be stored here.
    stack = {}, -- Scenes that are pushed will be stored here.
    shared = {}, -- Stores variables that are shared between scenes
    saved = {}, -- Stores saved stacks so they can be restored later
    buffer = {}, -- Stores the scene stack when the original scene stack is disabled
    frozen = false, -- If true, the buffer will be used instead of the original stack
    lockLevel = 0, -- They highest level of the stack that is locked
    version = "1.4.1", -- The used version of Scene Man
}

--- A helper funciton that returns either the buffer or the stack based on the value of menuMan.frozen.
-- @return (table) The buffer if the frozen flag is true, other the stack
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

--- Copies the changes from the buffer back into the original stack.
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

--- Removes a saved stack permanently.
-- This will not delete the scenes in the stack
-- This will not affect the current stack, even if it was restored using the to-be-deleted stack
-- @param id (string) A unique ID that identifies the stack that should be deleted
function sceneMan:deleteStack (id)
    self.saved[id] = nil
end

--- Locks the stack up until the specified level.
-- Locked scenes will have their event callbacks skipped, except for their "whenAdded", "whenRemoved", or "deleted" methods
-- The bottommost item of the stack is at level 1
-- @param level (int) The level that the stack should be locked up to
function sceneMan:lock (level)
    self.lockLevel = level
end

--- Unlocks the stack, which will allow all scenes to execute their event callbacks again.
function sceneMan:unlock ()
    self.lockLevel = 0
end

--- Gets the current lock level.
-- @return (int) The current lock level
function sceneMan:getLockLevel ()
    return self.lockLevel
end

--- Adds a new scene to Scene Man and initializes it via its load method.
-- This will call the scene's "load" method
-- @param name (string) The name of the new scene. This will be used later to push, insert, and remove this scene from the stack
-- @param scene (table) A table containing the scene's attributes and callback functions
-- @param ... (varargs) A series of values that will be passed to the scene's "load" callback
function sceneMan:newScene (name, scene, ...)
    self.scenes[name] = scene
    self.scenes[name].name = name
    if self.scenes[name].load ~= nil then
        self.scenes[name]:load (...)
    end
end

--- Removes a scene from Scene Man and calls its delete method.
-- This will call the scene's "delete" method
-- If you try to push or insert a deleted scene, Scene Man will throw an error!
-- @param name (string) The name of the scene that should be deleted
-- @param ... (varargs) A series of values that will be passed to the scene's "delete" callback
function sceneMan:deleteScene (name, ...)
    if self.scenes[name] ~= nil then
        if self.scenes[name].delete ~= nil then
            self.scenes[name]:delete (...)
        end
        self.scenes[name] = nil
    end
end

--- Returns the current size of the stack.
-- @return (int) The size of the stack
function sceneMan:getStackSize ()
    return #self.stack
end

--- Gives the name of the current scene. It will return nil is there are no scenes on the stack.
-- This will not look inside the frozen buffer, even if the stack is frozen
-- @return (string) The name of the scene at the top of the stack or nil if the stack is empty
function sceneMan:getCurrentScene ()
    return (#self.stack >= 1) and self.stack[#self.stack].name or nil
end

--- Adds a scene from the scenes table onto the stack.
-- This will call the scene's "whenAdded" method
-- Scenes at the top of the stack will have their functions called last
-- @raise When the given scene name isn't registered inside Scene Man
-- @param name (string) The name of the scene to add to the top of the stack
-- @param ... (varargs) A list of values that will be passed to the event's "whenAdded" callback function
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
-- This will call the topmost scene's "whenRemoved" method
-- @param ... (varargs) A list of values that will be passed to the event's "whenRemoved" callback function
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
-- This will call the scene's "whenAdded" method
-- @raise When the given scene name isn't registered inside Scene Man
-- @param name (string) The name of the scene to add to the top of the stack
-- @param index (int) The position within the stack that the scene should be inserted at
-- @param ... (varargs) A list of values that will be passed to the event's "whenAdded" callback function
-- @return (bool) True if the operation was successful
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
-- This will call the scene's "whenRemoved" method
-- @param index (int) The position within the stack that the scene should be removed at
-- @param ... (varargs) A list of values that will be passed to the event's "whenRemoved" callback function
-- @return (bool) True if the operation was successful
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
-- This will call all the scenes' "whenRemoved" methods, starting from the topmost scene
-- This will automatically freeze the stack until all scenes have been iterated over
-- @param ... (varargs) A list of values that will be passed to the event's "whenRemoved" callback function
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
-- This will call all the scenes' "whenRemoved" methods, starting from the topmost scene
-- This will automatically freeze the stack until all scenes have been iterated over
-- @param ... (varargs) A list of values that will be passed to the event's "whenRemoved" callback function
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
-- This will automatically freeze the stack until all scenes have been iterated over
-- @param eventName (string) The name of the event
-- @param ... (varargs) A series of values that will be passed to the scenes' event callbacks
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
