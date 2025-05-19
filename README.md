## SceneMan

Scene Man is a simple and lightweight scene/gamestate manager! (No relation to [lucassardois/sceneman](https://github.com/lucassardois/sceneman))

It's useful for separating your game into distinct “scenes” that can be stored in separate files. It can also be used to easily separate game logic from GUI logic or transition to different parts of the game.

### Features:

*   Stack-based: Multiple scenes can be layered over one another at the same time. Scenes can also push and pop other scenes from the stack at any time.
*   Extremely flexible: custom callbacks are trivial to define and can be used in any situation (updating, drawing, detecting mouse clicks, etc).
*   Small size: The entire system is only a few hundred lines long. It should take up next to no space inside your projects.
*   Portable: Works in any Lua-based frameworks or game engines. Tested with Lua version 5.1.
*   Stack freezing: The scene stack can be “frozen” so the scenes only transition when you want them to.
*   Stack saving: The current contents of the stack can be saved and restored with ease.
*   Stack locking: Stacks can be locked up to a specified "level" so everything below that level is not executed.

### Usage:

See the [Example](https://github.com/KINGTUT10101/SceneMan/wiki/Example) page on the wiki for a general sample.

See the [Freezing](https://github.com/KINGTUT10101/SceneMan/wiki/Freezing) page on the wiki for an example of the freezing system.

![image](https://github.com/KINGTUT10101/SceneMan/assets/45105509/4df08b3f-3235-4a5d-91ca-5073b5924a50)

### Changelog:

*   Version 1.1.0:
    *   Added stack freezing.
    *   The stack will automatically freeze while using the event and clearStack methods.
*   Version 1.2.0:
    *   Added stack saving.
    *   Stacks can now be saved and restored using unique IDs assigned to each saved stack.
*   Version 1.3.0:
    *   Added stack locking.
    *   Stacks can now be locked up to a specified level. Any scenes at and below the specified level will be skipped during an event trigger. This can be used to easily transition to a new scene and back. Simply lock the stack, push the new scene, run its code, pop the new scene, and unlock the stack.
*   Version 1.4.0:
    *   Added a function for getting the current lock level value.
    *   Added a function for clearing the unlocked portion of the stack, aka all the scenes above the current lock level value.
*   Version 1.4.1:
    *   A scene's load method will no longer automatically pass the sceneMan library as the first argument.
    *   Fixed a bug/oversight where the varargs were not passed to a scene's delete method.
    *   Added EmmyLua style comments to the library.
*   Version 1.4.2:
    *   Added assertions to sceneMan:newScene to ensure that scene names are strings and that scenes are not accidentally redefined.
    *   Fixed some comments and documentation in the code.
    *   Added sceneMan:getSceneAt method for getting the name of a scene at a specific index of the stack.
    *   Added sceneMan:getSceneIndex method for getting the index of a specific scene in the stack.
    *   Fixed a bug with the sceneMan:insert method that inserted the scene's name instead of its table.
    *   Updated sceneMan:remove method so users can specify what scene they'd like to remove using either their index or their name.
*   Version 1.4.3:
    *   Fixed a bug with the insert method where it would fail if the stack was empty.

### Documentation:

#### Attributes:

```lua
sceneMan.scenes = {} -- All created scenes will be stored here.
sceneMan.stack = {} -- Scenes that are pushed will be stored here.
sceneMan.shared = {} -- Stores variables that are shared between scenes
sceneMan.saved = {} -- Stores saved stacks so they can be restored later
sceneMan.buffer = {} -- Stores the scene stack when the original scene stack is disabled
sceneMan.frozen = false -- If true, the buffer will be used instead of the original stack
lockLevel = 0 -- They highest level of the stack that is locked
sceneMan.version = "1.4.2" -- The used version of Scene Man
```

#### Methods:

```lua
--- Adds a new scene and initializes it via its `load` method.
---@param name string Name of the new scene (used for later operations like push/remove).
---@param scene table Table containing attributes and callback functions of the scene.
---@vararg any Values passed to the `load` callback function of this scene.
sceneMan:newScene (name, scene, ...)

--- Deletes a registered scene and calls its `delete` method. Deleted scenes cannot be pushed or inserted again.
---@param name string Name of the scene to delete.
---@vararg any Values passed to the `delete` callback function of this scene.
sceneMan:deleteScene (name)

--- Gets the current size of the stack.
---@return integer size The size of the stack (number of scenes).
sceneMan:getStackSize ()

--- Gets the name of the current topmost scene on the stack.
--- This will ignore the frozen buffer.
---@return string|nil sceneName Name of topmost scene or nil if the stack is empty.
sceneMan:getCurrentScene ()

--- Gets the name of the scene at the provided index in the stack.
--- This will ignore the frozen buffer.
---@param index integer The index of the scene.
---@return string|nil sceneName Name of topmost scene or nil if the stack is empty.
sceneMan:getSceneAt (index)

--- Gets the index of a scene in the stack matching the provided name.
--- This will ignore the frozen buffer.
--- If the scene is present multiple times in the stack, this function will only return the index of the first scene found, starting from the top of the stack.
---@param sceneName string The name of the desired scene.
---@return integer|nil index Name of the scene at the given index or nil if the stack is empty.
sceneMan:getSceneIndex (sceneName)

--- Pushes a registered scene onto the top of the stack and calls its `whenAdded` method.
--- Scenes at the top of the stack will have their functions called last
---@param name string Name of registered scene to push onto stack.
---@vararg any Values passed to `whenAdded` callback function of this scene.
sceneMan:push (name, ...)

--- Pops a scene off of the stack.
--- This will call the topmost scene's `whenRemoved` method.
---@vararg any Values passed to the `whenRemoved` callback function of this scene.
sceneMan:pop (...)

--- Adds a scene to the stack at a given index.
--- This will call the scene's `whenAdded` method.
---@param name string The name of the scene to add to the stack.
---@param index integer The position within the stack that the scene should be inserted at.
---@vararg any Values passed to the `whenAdded` callback function of this scene.
---@return boolean success True if the scene was successfully inserted, false otherwise.
sceneMan:insert (name, index, ...)

--- Removes a scene from the stack at a certain index.
--- This will call the scene's `whenRemoved` method.
--- If a scene is present multiple times in the stack and a name is provided for the key, the first scene found starting at the top of the stack will be removed.
---@param key integer|string The position within the stack or the name of a scene that should be removed from the stack.
---@vararg any Values passed to the `whenRemoved` callback function of this scene.
---@return boolean success True if a scene was removed, false if the operation failed or if the scene with the provided name was not found.
sceneMan:remove (key, ...)

--- Removes all scenes from the stack, starting at the top.
--- This will call all the scenes' `whenRemoved` methods, starting from the topmost scene.
--- This will automatically freeze the stack until all scenes have been iterated over.
---@vararg any Values passed to the `whenRemoved` callback function of this scene.
sceneMan:clearStack (...)

--- Removes all scenes from the unlocked portion of the stack, starting at the top.
--- This will call all the scenes' `whenRemoved` methods, starting from the topmost scene.
--- This will automatically freeze the stack until all scenes have been iterated over.
---@vararg any Values passed to the `whenRemoved` callback function of this scene.
sceneMan:clearUnlockedStack (...)

--- Fires an event callback for all scenes on the stack.
--- This will automatically freeze the stack until all scenes have been iterated over.
---@param eventName string The name of the event.
---@vararg any Values passed to the scenes' event callbacks.
sceneMan:event (eventName, ...)

--- Redirects stack-altering operations into the buffer instead.
sceneMan:freeze ()

--- Copies the changes from the buffer back into the original stack.
sceneMan:unfreeze ()

--- Locks the stack up to a specified level.
--- Locked scenes skip their event callbacks except "whenAdded", "whenRemoved", or "deleted".
---@param level integer The level to lock up to (bottommost item is at level 1).
sceneMan:lock (level)

--- Unlocks all levels in the stack, allowing all scenes to execute their event callbacks again.
sceneMan:unlock ()

--- Gets the current lock level of the stack.
---@return integer level The current lock level.
sceneMan:getLockLevel ()

--- Saves the current contents of the stack so it can be restored later.
--- This will save the frozen buffer if the stack is frozen.
--- This will not modify the current stack in any way.
---@param id string A unique ID to identify the saved stack. Overrides any existing entry at this ID.
sceneMan:saveStack (id)

--- Restores a saved stack from storage.
--- This will call the loaded scenes' "whenAdded" methods.
---@param id string A unique ID identifying the stack to restore.
---@vararg any Values passed to the "whenAdded" callback function of scenes.
---@return boolean success True if restoration succeeded (stack exists and current stack is empty), false otherwise.
sceneMan:restoreStack (id, ...)

--- Deletes a saved stack permanently.
--- Does not affect scenes in the current stack, even if it was restored using the to-be-deleted stack.
--- This will not *delete* the scenes in the stack.
---@param id string A unique ID identifying the saved stack to delete.
sceneMan:deleteStack (id)
```
