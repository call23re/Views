local Plugin = script.Parent.Parent

local Hooks = require(Plugin.Packages.Hooks)
local Roact = require(Plugin.Packages.Roact)

local useTheme = require(script.Parent.useTheme)

local function sanitize(text)
	if text == "" then return " " end
	if #text > 40 then return text:sub(1, 40) end
	return text
end

local function Tab(props, hooks)
	local theme = useTheme(hooks)

	local hovered, setHover = hooks.useState(false)
	local focused, setFocused = hooks.useState(false)
	local lastClicked, setLastClicked = hooks.useState(os.clock())
	local inputState, setInputState = hooks.useState(props.New)

	local modifier = Enum.StudioStyleGuideModifier.Default
	if props.Selected then
		modifier = Enum.StudioStyleGuideModifier.Selected
	elseif hovered then
		modifier = Enum.StudioStyleGuideModifier.Hover
	end

	local backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.Button, modifier)
	local textColor = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, modifier)
	local hue, saturation, value = textColor:ToHSV()
	local placeholderTextColor = Color3.fromHSV(hue, saturation, value - 0.1)

	hooks.useEffect(function()
		setInputState(props.New)
	end, { props.New })

	local function onInputBegan(_, input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			setHover(true)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not props.Main then
				props.OnPressed(true)
			end

			local timestamp = os.clock()
			if timestamp - lastClicked <= 0.3 then
				-- double clicked
				setInputState(true)
			else
				if props.OnActivated then
					props.OnActivated()
				end
			end
			setLastClicked(timestamp)
		elseif (input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3) and not props.Main then
			props.ToggleTooltip(input.UserInputType)
		end
	end

	local function onInputEnded(_, input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			setHover(false)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			props.OnPressed(false)
		end
	end

	return Roact.createElement("ImageButton", {
		Active = true,
		AutoButtonColor = false,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = backgroundColor,
		Selected = props.Selected,
		Size = UDim2.fromOffset(0, 26),
		LayoutOrder = props.LayoutOrder,

		[Roact.Event.InputBegan] = onInputBegan,
		[Roact.Event.InputEnded] = onInputEnded
	}, {
		Icon = Roact.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://16116210846",
			ImageColor3 = textColor,
			LayoutOrder = 0,
			Size = UDim2.fromOffset(14, 12),
		}),
		Label = if inputState and not props.Main then 
			Roact.createElement("TextBox", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				ClearTextOnFocus = false,
				Font = Enum.Font.SourceSans,
				LayoutOrder = 1,
				Size = UDim2.fromScale(0, 1),
				Text = props.TabName,
				TextSize = 14,
				PlaceholderColor3 = placeholderTextColor,
				PlaceholderText = props.TabName,
				TextColor3 = textColor,
				[Roact.Ref] = function(rbx)
					if not rbx or focused then return end
					task.defer(function()
						rbx:CaptureFocus()
					end)
					setFocused(true)
				end,
				[Roact.Event.FocusLost] = function(rbx)
					setInputState(false)
					setFocused(false)
					if not props.OnUpdateName then return end
					props.OnUpdateName(sanitize(rbx.Text))
				end
			})
			else Roact.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Font = Enum.Font.SourceSans,
				LayoutOrder = 1,
				Size = UDim2.fromScale(0, 1),
				Text = props.TabName or "Unknown",
				TextColor3 = textColor,
				TextSize = 14,
				ZIndex = 2,
			}),
		Remove = if not props.Main then Roact.createElement("ImageButton", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://16116217702",
			ImageColor3 = textColor,
			Size = UDim2.fromOffset(8, 8),
			LayoutOrder = 2,
			[Roact.Event.Activated] = props.OnRemove
		}) else nil,

		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6)
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

return Hooks.new(Roact)(Tab)