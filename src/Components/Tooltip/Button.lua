local Plugin = script.Parent.Parent.Parent

local Hooks = require(Plugin.Packages.Hooks)
local Roact = require(Plugin.Packages.Roact)

local useTheme = require(script.Parent.Parent.useTheme)

local function Button(props, hooks)
	local theme = useTheme(hooks)

	local hovered, setHover = hooks.useState(false)

	local modifier = Enum.StudioStyleGuideModifier.Default
	if hovered then
		modifier = Enum.StudioStyleGuideModifier.Hover
	end

	local backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.Button, modifier)
	local textColor = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, modifier)

	local function onInputBegan(_, input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			setHover(true)
		end
	end

	local function onInputEnded(_, input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			setHover(false)
		end
	end

	return Roact.createElement("ImageButton", {
		AutoButtonColor = false,
		BackgroundColor3 = backgroundColor,
		BorderSizePixel = 0,
		Size = props.Size,
		Position = props.Position,
		LayoutOrder = props.LayoutOrder,

		[Roact.Event.InputBegan] = onInputBegan,
		[Roact.Event.InputEnded] = onInputEnded,
		[Roact.Event.Activated] = props.onActivated
	}, {
		Icon = Roact.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = props.Icon,
			ImageColor3 = textColor,
			LayoutOrder = 0,
			Size = props.IconSize,
		}),
		Label = Roact.createElement("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = Enum.Font.SourceSans,
			LayoutOrder = 1,
			Size = UDim2.fromScale(0, 1),
			Text = props.Text or "Button",
			TextColor3 = textColor,
			TextSize = 16,
			ZIndex = 2,
		}),
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6)
		}),
		List = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 7),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		})
	})
end

return Hooks.new(Roact)(Button)