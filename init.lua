--[=[
    A Plugin to convert an instance tree into a script
    Copyright (C) 2023  Expo

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]=]
if false then
  MS_WATERMARK 'ExponentialWorkload made this shit - enjoy the plugin'
end
local ChangeHistoryService = game:GetService 'ChangeHistoryService'
local Selection = game:GetService 'Selection'

local varPrefixes

local breadMode = false

local toolbar = plugin:CreateToolbar(breadMode and 'Bread2Lua' or 'RBX2Lua')
local newScriptButton =
  toolbar:CreateButton(breadMode and 'Bread2Lua' or 'Convert\nto\nLua', breadMode and 'BREADLUA' or 'Convert to Lua', '')
local useTable =
  toolbar:CreateButton('Convert\nTo Lua\nusing Table\n(Syn)', 'To Lua using Table\n(Synapse Compatibility Mode)', '')
local dump = game:GetService('HttpService'):JSONDecode(require(script.Dump))
local upload = require(script.Upload)

local find = function(t, v)
  for _, o in pairs(t) do
    if o == v then
      return true
    end
  end
  return false
end

if shared.varPrefixes and typeof(shared.varPrefixes) ~= 'table' then
  error 'varPrefixes Not table'
end
if shared.varPrefixes then
  pcall(function()
    for _, v in pairs(shared.varPrefixes) do
      table.insert(shared.varPrefixes, v)
    end
    table.insert(shared.varPrefixes, 'cord_breadhub_cc')
    table.insert(shared.varPrefixes, 'MadeByExponentialWorkload')
  end)
end
varPrefixes = varPrefixes
  or shared.varPrefixes
  or {
    'BallsHangingLowWhileIPopABottleOffAYacht',
    'IPlayMinecraftWithTheBestSpecs',
    'IsItReallyLoveIsItAllInMyMind',
    'ArsonMyBelovedActivity',
    'StdioIsNotResponding',
    'StudioIsNotResponding',
    'RobloxHasEncounteredAFatalErrorAndNeedsToQuit_WereSorry',
    'ABCDLSDSagWerHatDenBestenSchnee',
    'YOUTUBE_dQw4w9WgXcQ',
    'HeyVsauceRussiaHereYourComputerSecurityIsGoodOrIsIt',
    'MarriedToAstolfo',
    'AstolfoIsMyWife',
    'pingspoofing',
    'GambareGambareSenpai',
    'DidIReallyJustForgetThatMelody',
    'madebyexpo',
    'TablesAreNotForOOP_StopUsingMETATABLES',
    'urafatneek',
    'CockAndBallTorture',
    'ThisShitGoingHarderThanFuckingChildAbuse',
    'LostChildrenWillBeTaughtCPP',
    'IDidYourMom',
    'RobloxR34_HOT',
    'RobloxR63_HOT',
    'HotRobloxBoobsAndSex',
    'HeyVSauce_HitlerHere',
    'AnalLightbulb',
    'YouRemindMeOfButterflyDoors_WaistTightWithABodyLikeOh_HitYouWithTheDougiePose_RichJamesSuperfreakWhatchuKnowAboutThoseYeah',
  } -- {'_'} | {'var'}
local _vp = varPrefixes
local shouldUseTable = false

local Blacklists = require(script.BlacklistedProps)

local checkBlacklist = function(className, prop)
  local isBlacklisted = false
  for _, n in pairs(Blacklists[className] or {}) do
    if n == prop then
      isBlacklisted = true
      break
    end
  end
  --if prop == 'Transparency' then warn('Fail BlacklistCheck',className) end
  return isBlacklisted
end

local dumpClasses = dump.Classes
local dumpRelevantInfo = {}
local getProps = function(class)
  local props = {}
  for _, o in pairs(class.Members) do
    if o.MemberType == 'Property' and not checkBlacklist(class.Name, o.Name) then
      if
        o.Security.Read == 'None'
        and o.Security.Write == 'None'
        and not find(o.Tags or {}, 'Deprecated')
        and not find(o.Tags or {}, 'ReadOnly')
        and not find(o.Tags or {}, 'Hidden')
      then
        table.insert(props, o.Name)
      end
    end
  end
  return props
end
for _, class in pairs(dumpClasses) do
  local props = getProps(class)

  dumpRelevantInfo[class.Name] = {
    Tags = class.Tags,
    Name = class.Name,
    Superclass = class.Superclass,
    Props = props,
  }
end
local hadDiff = true
local superClassed = {}
local getSuperclassProperties
local includes = function(t, k)
  for k2, v in pairs(t) do
    if k == k2 or k == v then
      return true
    end
  end
  return false
end
getSuperclassProperties = function(class)
  if class == '<<<ROOT>>>' then
    return {}
  end
  local classData = dumpRelevantInfo[class]
  if not superClassed[class] then
    for _, o in pairs(getSuperclassProperties(classData.Superclass)) do
      if not checkBlacklist(classData.Name, o.Name) and not includes(classData.Props, o) then
        table.insert(classData.Props, o)
      end
    end
    superClassed[class] = true
  end
  return dumpRelevantInfo[class].Props
end
for k, v in pairs(dumpRelevantInfo) do
  for _, o in pairs(getSuperclassProperties(v.Superclass)) do
    table.insert(v.Props, o)
  end
end

newScriptButton.ClickableWhenViewportHidden = true
useTable.ClickableWhenViewportHidden = true

local escape = function(value)
  local byted = ''
  for i = 1, #value, 1 do
    local char = string.sub(value, i, i)
    if
      char == '\''
      or char == '"'
      or char == '\\'
      or char == '\n'
      or char == '\r'
      or char == '\b'
      or char == '\f'
      or char == '\t'
      or char == '\v'
    then
      byted = byted .. '\\' .. string.byte(char)
    else
      byted = byted .. char
    end
  end
  return byted
end

local map = function(a, f)
  for k, v in pairs(a) do
    a[k] = f(v, k)
  end
  return a
end

local serializeValue
serializeValue = function(value)
  if typeof(value) == 'boolean' or typeof(value) == 'number' or typeof(value) == 'nil' then
    value = tostring(value)
  elseif typeof(value) == 'Vector2' then
    value = string.format('Vector2.new(%s,%s)', tostring(value.X), tostring(value.Y))
  elseif typeof(value) == 'Vector3' then
    value = string.format('Vector3.new(%s,%s,%s)', tostring(value.X), tostring(value.Y), tostring(value.Z))
  elseif typeof(value) == 'Color3' then
    value = string.format('Color3.new(%s,%s,%s)', tostring(value.R), tostring(value.G), tostring(value.B))
  elseif typeof(value) == 'UDim' then
    value = string.format('UDim.new(%s,%s)', tostring(value.Scale), tostring(value.Offset))
  elseif typeof(value) == 'UDim2' then
    value = string.format(
      'UDim2.new(%s,%s,%s,%s)',
      tostring(value.X.Scale),
      tostring(value.X.Offset),
      tostring(value.Y.Scale),
      tostring(value.Y.Offset)
    )
  elseif typeof(value) == 'Instance' then
    warn('Cannot resolve instance', value:GetFullName(), 'within tree!')
    value = 'nil'
  elseif typeof(value) == 'string' then
    value = '\'' .. escape(value) .. '\''
  elseif typeof(value) == 'EnumItem' then
    value = tostring(value)
  elseif typeof(value) == 'Font' then
    value = string.format('Font.new(\'%s\',%s,%s)', value.Family, tostring(value.Weight), tostring(value.Style))
  elseif typeof(value) == 'CFrame' then
    value = string.format('CFrame.new(%s)', table.concat({ value:GetComponents() }, ','))
  elseif typeof(value) == 'Rect' then
    value = string.format(
      'Rect.new(Vector2.new(%s,%s),Vector2.new(%s,%s))',
      tostring(value.Min.X),
      tostring(value.Min.Y),
      tostring(value.Max.X),
      tostring(value.Max.Y)
    )
  elseif typeof(value) == 'NumberSequenceKeypoint' then
    value = string.format(
      'NumberSequenceKeypoint.new(%s,%s,%s)',
      tostring(value.Time),
      tostring(value.Value),
      tostring(value.Envelope)
    )
  elseif typeof(value) == 'NumberSequence' then
    value = string.format('NumberSequence.new{%s}', table.concat(map(value.Keypoints, serializeValue), ';'))
  elseif typeof(value) == 'ColorSequenceKeypoint' then
    value = string.format('ColorSequenceKeypoint.new(%s,%s)', tostring(value.Time), serializeValue(value.Value))
  elseif typeof(value) == 'ColorSequence' then
    value = string.format('ColorSequence.new{%s}', table.concat(map(value.Keypoints, serializeValue), ';'))
  end
  return value
end

local function onNewScriptButtonClicked()
  local varPrefixes = _vp
  if shouldUseTable then
    varPrefixes = {
      '_',
      '+',
      '-',
      '!',
      '?',
      ':',
      '"',
      '{',
      '}',
      '[',
      ']',
      'RBX2Lua',
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z',
      ',',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '0',
    }
  end
  local selectedObjects = Selection:Get()
  if #selectedObjects > 0 then
    local bundleTarget = selectedObjects[1]:Clone()
    local objectList = {}
    objectList[bundleTarget] = 'ROOT'
    local i = {}
    for _, o in pairs(bundleTarget:GetDescendants()) do
      if not o:IsA 'BaseScript' or o:IsA 'ModuleScript' then
        local prefix = varPrefixes[math.random(1, #varPrefixes)]
        i[prefix] = (i[prefix] or -1) + 1
        objectList[o] = prefix .. tostring(i[prefix])
      end
    end
    local script =
      '-- RBX2Lua by ExponentialWorkload\n-- Reminder to minify this for a giant code size reduction! This is Pure Lua 5.1 (no extra luau weirdness) so it\'ll work in almost any minifier.\n'
    if shouldUseTable then
      script = script .. 'local _={};\n'
    end
    local varFormat = shouldUseTable and '_[\'%s\']' or '%s'
    local varDefineFormat = shouldUseTable and varFormat or ('local ' .. varFormat)
    local f = string.format
    if breadMode then
      script = script .. '-- BREAD~\n'
    end
    -- build instance creations
    for object, objectName in pairs(objectList) do
      script = script .. f(varDefineFormat, objectName) .. '=Instance.new\'' .. object.ClassName .. '\''
    end
    script = script .. '\n--[[prop names]]\n'
    local scriptpt2 = ''
    local propNames = {}
    local propIdx = {}
    local lineIdx = 0
    local lineCount = 0
    for _ in pairs(objectList) do
      lineCount = lineCount + 1
    end
    local line = math.random(1, lineCount)
    -- define props
    for object, objectName in pairs(objectList) do
      scriptpt2 = scriptpt2 .. '--[[' .. escape(object:GetFullName()) .. ']]'
      local propsAdded = {}
      for _, prop in pairs(dumpRelevantInfo[object.ClassName].Props) do
        local canWrite, err = pcall(function()
          if checkBlacklist(object.ClassName, prop) then
            error 'Blacklisted Prop'
          end
          local instance = Instance.new(object.ClassName)
          local p = instance[prop]
          instance:Destroy()
          if p == object[prop] then
            error 'Default'
          else
            object[prop] = object[prop]
          end
        end)
        if canWrite and not includes(propsAdded, prop) then
          local value = object[prop]
          if typeof(value) == 'Instance' and objectList[value] then
            value = f(varFormat, objectList[value])
          else
            value = serializeValue(value)
          end
          if typeof(value) == 'string' then
            local propShort = propNames[prop]
            if not propShort then
              local pref = varPrefixes[math.random(1, #varPrefixes)]
              propIdx[pref] = propIdx[pref] or 0
              propShort = '_p_' .. pref .. tostring(propIdx[pref])
              propIdx[pref] = propIdx[pref] + 1
              propNames[prop] = propShort
            end
            scriptpt2 = scriptpt2 .. string.format('%s[%s]=%s;', f(varFormat, objectName), f(varFormat, propShort), value)
            --scriptpt2=scriptpt2..string.format('%s[%s]=%s;',objectName,'\''..prop..'\'',value)
            table.insert(propsAdded, prop)
          else
            warn('Failed to serialize', value, '(post-conversion type', typeof(value), ' is not string)')
          end
        end
      end
      for k, v in pairs(object:GetAttributes()) do
        local serialized = serializeValue(v)
        if typeof(serialized) == 'string' then
          scriptpt2 = scriptpt2 .. string.format('%s:SetAttribute(\'%s\',%s);', objectName, escape(k), serialized)
        else
          warn('Cannot serialize', typeof(v), '(got', typeof(serialized), 'after attempted serialization)')
        end
      end
      lineIdx = lineIdx + 1
      if lineIdx == line then
        scriptpt2 = scriptpt2
          .. 'string.gsub([[<title>Expo\'s RBX2Lua</title><meta name="description" content="This script was a Roblox Instance tree, but now it\'s a Lua Script, thanks to RBX2Lua - https://rbx2lua.xn--urs05q.wtf/">]],\'Hey there! Please dont remove these credits, its not like they harm you, plus they help promote this tool i worked on! ily xx pls dont remove this notice <3 - P.S. if you have this interfering with something you\\\'re doing, simply change the string from an HTML tag to something like "Generated by Expo\\\'s RBX2Lua"\',\'\')'
      end
      scriptpt2 = scriptpt2 .. '\n'
    end
    for propName, propVar in pairs(propNames) do
      script = script .. f(varDefineFormat, propVar) .. '=\'' .. escape(propName) .. '\''
    end
    script = script
      .. '\n--[[prop values]]\n'
      .. scriptpt2
      .. string.format('return %s;\n', string.format(varFormat, 'ROOT'))
    upload(script, plugin)
    ChangeHistoryService:SetWaypoint 'Do action'
  end
end

newScriptButton.Click:Connect(function()
  shouldUseTable = false
  return onNewScriptButtonClicked()
end)
useTable.Click:Connect(function()
  shouldUseTable = true
  return onNewScriptButtonClicked()
end)
