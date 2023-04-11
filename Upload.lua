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
return function(data, plugin)
  local newScript = Instance.new 'Script'
  local worked, err = pcall(function()
    newScript.Source = tostring(data)
    newScript.Parent = game

    game:GetService('Selection'):Set { newScript }
    plugin:OpenScript(newScript)
    task.spawn(function()
      task.wait(240)
      pcall(newScript.Destroy, newScript)
    end)
  end)
  if not worked then
    warn(err, '- Uploading to hastebin')
    print(
      'Uploaded to:',
      'https://hastebin.com/'
        .. game:GetService('HttpService'):JSONDecode(
          game
            :GetService('HttpService')
            :PostAsync('https://hastebin.com/documents', data, Enum.HttpContentType.TextPlain, false, {
              ['Accept'] = 'application/json',
              ['Accept-Language'] = 'en-US,en;q=0.5',
              ['Sec-Fetch-Dest'] = 'empty',
              ['Sec-Fetch-Mode'] = 'cors',
              ['Sec-Fetch-Site'] = 'same-origin',
              ['Sec-GPC'] = '1',
            })
        ).key
    )
  end
end
