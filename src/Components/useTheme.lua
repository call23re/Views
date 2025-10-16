local ThemeContext = require(script.Parent.ThemeContext)
local studio = settings().Studio

local function getTheme(studioTheme: StudioTheme)
	local isDark = studioTheme.Name == "Dark"

	local TextColor = studioTheme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Default)
	local textHue, textSaturation, textValue = TextColor:ToHSV()
	local PlaceholderTextColor = Color3.fromHSV(textHue, textSaturation, textValue - 0.1)
	local IconColor = if isDark then TextColor else Color3.fromHex("#3d3f4b")

	return {
		Tab = {
			BackgroundColor = {
				Default = studioTheme:GetColor(
					Enum.StudioStyleGuideColor.Button,
					Enum.StudioStyleGuideModifier.Default
				),
				Selected = if isDark then studioTheme:GetColor(
					Enum.StudioStyleGuideColor.Button, 
					Enum.StudioStyleGuideModifier.Selected
				) else Color3.fromHex("#b9ceff"),
				Hover = studioTheme:GetColor(
					Enum.StudioStyleGuideColor.Button,
					Enum.StudioStyleGuideModifier.Hover
				)
			},
			TextColor = TextColor,
			PlaceholderTextColor = PlaceholderTextColor,
			IconColor = IconColor
		},
		Tooltip = {
			BackgroundColor = studioTheme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Default),
			Button = {
				BackgroundColor = {
					Default = studioTheme:GetColor(
						Enum.StudioStyleGuideColor.Button,
						Enum.StudioStyleGuideModifier.Default
					),
					Hover = if not isDark then studioTheme:GetColor(
						Enum.StudioStyleGuideColor.Button,
						Enum.StudioStyleGuideModifier.Hover
					) else Color3.fromHex("#3d3f4b")
				},
				TextColor = TextColor,
				IconColor = IconColor
			}
		},
		List = {
			Add = {
				TextColor = if isDark then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
			}
		}
	}
end

local function useTheme(hooks)
	local theme = hooks.useContext(ThemeContext)
	local studioTheme, setStudioTheme = hooks.useState(getTheme(studio.Theme))

	hooks.useEffect(function()
		if theme then return end
		local connection = studio.ThemeChanged:Connect(function()
			setStudioTheme(getTheme(studio.Theme))
		end)
		return function()
			connection:Disconnect()
		end
	end, { theme, studioTheme })

	return theme or studioTheme
end

return useTheme