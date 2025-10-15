local UserInputService = game:GetService("UserInputService")

local Plugin = script.Parent.Parent

local Hooks = require(Plugin.Packages.Hooks)
local Roact = require(Plugin.Packages.Roact)

local List = require(script.Parent.List)
local Tooltip = require(script.Parent.Tooltip)

local function App(props, hooks)
	local tabs, setTabs = hooks.useState(props.Tabs)
	local gui: ScreenGui, setGui = hooks.useState()
	local activeTooltip, setActiveTooltip = hooks.useState()
	local dragging, setDragging = hooks.useState()

	-- lol
	local list, tooltipPosition;
	do
		if gui then
			list = gui:FindFirstChild("List")
			if not list then return end
		end
		if list and activeTooltip then
			local el = list.Tabs:FindFirstChild(activeTooltip)
			if not el then return end
			tooltipPosition = UDim2.fromOffset(el.AbsolutePosition.X + el.AbsoluteSize.X / 2 - 56, el.AbsolutePosition.Y + 40)
		end
	end

	-- update tabs
	hooks.useEffect(function()
		local connection = props.Update.Event:Connect(function(newTabs)
			setTabs(newTabs)
		end)

		return function()
			if connection.Connected then
				connection:Disconnect()
			end
		end
	end)

	-- disable tooltip if user clicks outside bounds
	hooks.useEffect(function()
		if not activeTooltip then return end
		if not tooltipPosition then return end

		local connection = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		
			local position = input.Position
			local size = Vector2.new(112, 84)
			if
				position.X < tooltipPosition.X.Offset - 10 or
				position.X > tooltipPosition.X.Offset + size.X + 10 or
				position.Y < tooltipPosition.Y.Offset - 10 or
				position.Y > tooltipPosition.Y.Offset + size.Y + 10
			then
				setActiveTooltip(nil)
			end
		end)

		return function()
			if connection.Connected then
				connection:Disconnect()
			end
		end
	end, { activeTooltip })

	-- dragging tabs rearranges them
	hooks.useEffect(function()
		if not dragging then return end
		if not list then return end

		local connection = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

			local best = dragging
			for _, element: ImageButton in list.Tabs:GetChildren() do
				if not element:IsA("ImageButton") then continue end
				local index = tonumber(element.Name)
				-- TODO: make this logic more clear
				if input.Position.X >= element.AbsolutePosition.X + (index > dragging and (element.AbsoluteSize.X / 2) or -(element.AbsoluteSize.X / 2) ) and input.Position.X <= element.AbsolutePosition.X + element.AbsoluteSize.X then
					best = math.max(index, 2)
				end
			end

			if best ~= dragging then
				props.OnUpdateIndex(dragging, best)
				setDragging(best)
			end
		end)

		return function()
			if connection.Connected then
				connection:Disconnect()
			end
		end
	end, { dragging })

	local function onRename()
		props.SetNew(activeTooltip)
		setActiveTooltip(nil)
	end

	local function onRemove()
		props.OnRemove(activeTooltip)
		setActiveTooltip(nil)
	end

	local function onPin()
		props.Pin(activeTooltip)
		setActiveTooltip(nil)
	end

	return Roact.createElement("ScreenGui", {
		Enabled = props.Enabled,
		[Roact.Ref] = setGui
	}, {
		List = Roact.createElement(List, {
			Position = UDim2.fromOffset(5, 5),
			Tabs = tabs,
			Width = gui and gui.AbsoluteSize.X or 1000,

			OnActivated = function(index)
				props.OnActivated(index)
				setActiveTooltip(nil)
			end,
			OnRemove = function(index)
				props.OnRemove(index)
				setActiveTooltip(nil)
			end,
			OnUpdateName = function(index, new)
				props.OnUpdateName(index, new)
				setActiveTooltip(nil)
			end,
			Add = function()
				props.Add()
				setActiveTooltip(nil)
			end,
			ToggleTooltip = function(index, method: Enum.UserInputType)
				local nextTooltip = index
				if activeTooltip == index then
					nextTooltip = nil
				end
				setActiveTooltip(nextTooltip)

				if method == Enum.UserInputType.MouseButton2 then
					props.ToggleTooltip()
				end
			end,
			OnPressed = function(index, state)
				if state then
					setActiveTooltip(nil)
				end
				setDragging(state and index)
			end,
			Hovering = props.Hovering
		}),
		Tooltip = if activeTooltip and tooltipPosition then
			Roact.createElement(Tooltip, {
				Position = tooltipPosition,
				Pinned = props.Tabs[activeTooltip] and props.Tabs[activeTooltip].Pinned,
				onRename = onRename,
				onRemove = onRemove,
				onPin = onPin,
				HideTooltip = function()
					setActiveTooltip(nil)
				end,
				Hovering = props.Hovering
			})
		else nil
	})
end

return Hooks.new(Roact)(App)