local Plugin = script.Parent.Parent

local Hooks = require(Plugin.Packages.Hooks)
local Roact = require(Plugin.Packages.Roact)

local useTheme = require(script.Parent.useTheme)

local Tab = require(script.Parent.Tab)

local function List(props, hooks)
	local theme = useTheme(hooks)

	local prevWidth, setWidth = hooks.useState()
	local width = math.min(prevWidth or math.huge, props.Width - 52)

	local children = {}
	for i, tab in props.Tabs do
		table.insert(children, Roact.createElement(Tab, {
			Main = tab.Main,
			TabName = tab.Name,
			Selected = tab.Selected,
			New = tab.New,
			LayoutOrder = i,

			OnActivated = function()
				props.OnActivated(i)
			end,
			OnRemove = function()
				props.OnRemove(i)
			end,
			OnUpdateName = function(new)
				props.OnUpdateName(i, new)
			end,
			ToggleTooltip = function(UserInputType)
				props.ToggleTooltip(i, UserInputType)
			end,
			OnPressed = function(state)
				props.OnPressed(i, state)
			end
		}))
	end

	local function onInputBegan(_, input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not props.Hovering then return end
			props.Hovering(true)
		end
	end

	local function onInputEnded(_, input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not props.Hovering then return end
			props.Hovering(false)
		end
	end

	return Roact.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 26),
		Position = props.Position,
		
		[Roact.Event.InputBegan] = onInputBegan,
		[Roact.Event.InputEnded] = onInputEnded,
	}, {
		Tabs = Roact.createElement("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			CanvasPosition = Vector2.new(prevWidth, 0),
			ElasticBehavior = Enum.ElasticBehavior.Never,
			LayoutOrder = 0,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			Size = UDim2.fromOffset(width, 28)
		}, {
			List = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				[Roact.Ref] = function(ref)
					if not ref then return end
					local curWidth = ref.AbsoluteContentSize.X
					if curWidth ~= prevWidth then
						setWidth(ref.AbsoluteContentSize.X)
					end
				end
			}),
			children = Roact.createFragment(children)
		}),
		Add = Roact.createElement("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(26, 26),
			Text = "+",
			TextSize = 22,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Selected),
			Font = Enum.Font.Gotham,
			LayoutOrder = 1,
			[Roact.Event.Activated] = props.Add
		}),
		List = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		})
	})
end

return Hooks.new(Roact)(List)