local Plugin = script.Parent.Parent

local Hooks = require(Plugin.Packages.Hooks)
local Roact = require(Plugin.Packages.Roact)

local Button = require(script.Button)
local useTheme = require(script.Parent.useTheme)

local function Tooltip(props, hooks)
	local theme = useTheme(hooks).Tooltip

	local backgroundColor = theme.BackgroundColor

	local function onInputBegan(_, input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			props.Hovering(true)
		end
	end

	local function onInputEnded(_, input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			props.Hovering(false)
		end
	end

	return Roact.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = backgroundColor,
		ClipsDescendants = false,
		Position = props.Position,
		Size = UDim2.fromOffset(112, 0),

		[Roact.Event.InputBegan] = onInputBegan,
		[Roact.Event.InputEnded] = onInputEnded,
	}, {
		Triangle = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -15),
			Size = UDim2.fromOffset(14, 9),
			BackgroundTransparency = 1,
			Image = "rbxassetid://16141080280",
			ImageColor3 = backgroundColor,
		}),
		Buttons = Roact.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
		}, {
			Rename = Roact.createElement(Button, {
				Text = "Rename",
				Icon = "rbxassetid://16141054694",
				IconSize = UDim2.fromOffset(14, 14),
				Size = UDim2.fromOffset(100, 22),
				LayoutOrder = 0,
				onActivated = props.onRename,
			}),
			Remove = Roact.createElement(Button, {
				Text = "Remove",
				Icon = "rbxassetid://16141074375",
				IconSize = UDim2.fromOffset(14, 14),
				Size = UDim2.fromOffset(100, 22),
				LayoutOrder = 1,
				onActivated = props.onRemove
			}),
			Pin = Roact.createElement(Button, {
				Text = props.Pinned and "Unpin" or "Pin",
				Icon = "rbxassetid://16141069234",
				IconSize = UDim2.fromOffset(14, 14),
				Size = UDim2.fromOffset(100, 22),
				LayoutOrder = 2,
				onActivated = props.onPin
			}),
			List = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})
		}),
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6)
		}),
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6)
		}),
	})
end

return Hooks.new(Roact)(Tooltip)