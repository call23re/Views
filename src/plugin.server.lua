local UserInputService = game:GetService("UserInputService")
local ServerStorage = game:GetService("ServerStorage")
local StudioService = game:GetService("StudioService")
local RunService = game:GetService("RunService")

if not (RunService:IsEdit() or RunService:IsRunMode()) then
	return
end

local Plugin = script.Parent

local Roact = require(Plugin.Packages.Roact)
local App = require(Plugin.Components.App)

local toolbar = plugin:CreateToolbar("Views")
local button = toolbar:CreateButton(
	"Views",
	"Views",
	"rbxassetid://17041838566"
)
button.ClickableWhenViewportHidden = false

local menu = plugin:CreatePluginMenu("", "")
local actionId = 0

local Folder = ServerStorage:FindFirstChild("_cameraSaves")
if not Folder then
	Folder = Instance.new("Folder")
	Folder.Name = "_cameraSaves"
	Folder.Parent = ServerStorage
end

local localUserId = StudioService:GetUserId()

local Container = Folder:FindFirstChild(localUserId)
if not Container then
	Container = Instance.new("Folder")
	Container.Name = localUserId
	Container.Parent = Folder
end

local Tabs = {
	{
		Name = "Main",
		Index = 1,
		Main = true,
		Selected = true,
		New = false,
		Pinned = false,
		CFrame = nil,
		Focus = nil,
		FieldOfView = 70,
		Object = nil
	}
}

local currentTab = 1
local hasNewTab = false
local update = Instance.new("BindableEvent")

local function makeTabFromSave(Save: CFrameValue)
	local name = Save:GetAttribute("Tab") or Save:GetAttribute("tab")
	local index = Save:GetAttribute("Index") or Save:GetAttribute("index")
	local pinned = Save:GetAttribute("Pinned") or Save:GetAttribute("pinned")
	local focus = Save:GetAttribute("Focus") or Save:GetAttribute("focus")
	local fov = Save:GetAttribute("FieldOfView") or 70

	Save.Name = name

	return {
		Name = name,
		Index = index,
		Main = false,
		Selected = false,
		New = false,
		Pinned = pinned,
		CFrame = Save.Value,
		Focus = focus,
		FieldOfView = fov,
		Object = Save
	}
end

for _, obj in Container:GetChildren() do
	table.insert(Tabs, makeTabFromSave(obj))
end

local function ResolveDuplicates()
	local Seen = {}
	local Duplicates = {}

	local numTabs = 0
	for _, tab in Tabs do
		if Seen[tab.Index] then
			table.insert(Duplicates, tab)
		else
			numTabs += 1
		end
		Seen[tab.Index] = true
	end

	local currentIndex = numTabs + 1

	for _, tab in Duplicates do
		tab.Index = currentIndex
		tab.Object:SetAttribute("Index", currentIndex)
		currentIndex += 1
	end

	-- Easier to sort seprately because insert logic is weird
	table.sort(Tabs, function(a, b)
		return a.Index < b.Index
	end)

	for j, tab in Tabs do
		tab.Index = j
		if tab.Object then
			tab.Object:SetAttribute("Index", j)
		end
	end

	update:Fire(Tabs)
end

ResolveDuplicates()
Container.ChildAdded:Connect(function(child)
	if not child:IsA("CFrameValue") then return end

	if child:GetAttribute("Ignore") then
		child:SetAttribute("Ignore", nil)
		return
	end

	child:SetAttribute("Index", #Tabs + 1)

	table.insert(Tabs, makeTabFromSave(child))
	ResolveDuplicates()
end)

Container.ChildRemoved:Connect(function(child)
	if not child:IsA("CFrameValue") then return end
	if child:GetAttribute("Ignore") then return end

	local index = child:GetAttribute("Index")
	table.remove(Tabs, index)

	ResolveDuplicates()
end)

-- Previously, saves were stored directly in the "_cameraSaves" folder.
-- For compatability reasons, I'm moving them into the applicable container for the first valid user.
-- (hopefully fine for now)
for _, obj in Folder:GetChildren() do
	if obj:IsA("CFrameValue") then
		obj.Parent = Container
	end
end

local function Activate(index)
	local currentCamera = workspace.CurrentCamera
	local currentCFrame = currentCamera.CFrame
	local currentFocus = currentCamera.Focus
	local currentFoV = currentCamera.FieldOfView

	local prevTab = Tabs[currentTab]

	if prevTab then
		if not prevTab.Pinned then
			prevTab.CFrame = currentCFrame
			prevTab.Focus = currentFocus
			prevTab.FieldOfView = currentFoV
			if not prevTab.Main then
				prevTab.Object.Value = currentCFrame
				prevTab.Object:SetAttribute("Focus", currentFocus)
				prevTab.Object:SetAttribute("FieldOfView", currentFoV)
			end
		end
	end

	currentTab = index
	local nextTab = Tabs[index]

	currentCamera.CFrame = nextTab.CFrame or currentCFrame
	currentCamera.Focus = nextTab.Focus or currentFocus
	currentCamera.FieldOfView = nextTab.FieldOfView or currentFoV
	
	if nextTab.Object then
		nextTab.Object.Value = nextTab.CFrame or currentCFrame
		nextTab.Object:SetAttribute("Focus", nextTab.Focus or currentFocus)
		nextTab.Object:SetAttribute("FieldOfView", nextTab.FieldOfView or currentFoV)
	end

	for _, tab in Tabs do
		tab.Selected = false
	end
	Tabs[index].Selected = true

	update:Fire(Tabs)
end

local function Remove(index)
	if Tabs[index].Selected then
		Activate(math.max(index - 1, 1))
	end

	Tabs[index].Object:SetAttribute("Ignore", true)
	Tabs[index].Object:Destroy()
	table.remove(Tabs, index)

	for j, tab in Tabs do
		if not tab.Object then continue end
		tab.Object:SetAttribute("Index", j)
	end

	update:Fire(Tabs)
end

local function Add()
	local obj = Instance.new("CFrameValue")
	obj:SetAttribute("Ignore", true)
	obj.Parent = Container

	for _, tab in Tabs do
		tab.New = false
	end

	local Index = #Tabs + 1
	table.insert(Tabs, {
		Name = "New View",
		Index = Index,
		Main = false,
		Selected = true,
		New = true,
		Pinned = false,
		CFrame = nil,
		Focus = nil,
		FieldOfView = 70,
		Object = obj
	})

	obj:SetAttribute("Index", Index)
	obj:SetAttribute("Tab", "New View")

	Activate(#Tabs)

	hasNewTab = true

	update:Fire(Tabs)
end

local function UpdateName(index, name)
	Tabs[index].Name = name
	Tabs[index].New = false
	Tabs[index].Object:SetAttribute("Tab", name)
	Tabs[index].Object.Name = name
	hasNewTab = false
	update:Fire(Tabs)
end

local function UpdateIndex(prevIndex, newIndex)
	if not Tabs[prevIndex] then return end

	table.insert(Tabs, newIndex, table.remove(Tabs, prevIndex))

	for index, tab in Tabs do
		if not tab.Object then continue end
		tab.Object:SetAttribute("Index", index)
	end

	if currentTab == prevIndex then
		currentTab = newIndex
	end

	update:Fire(Tabs)
end

local function SetNew(index)
	for _, tab in Tabs do
		tab.New = false
	end
	Tabs[index].New = true
	hasNewTab = true
	update:Fire(Tabs)
end

local function Pin(index)
	local pinned = not Tabs[index].Pinned

	Tabs[index].Pinned = pinned
	Tabs[index].Object:SetAttribute("Pinned", pinned)

	if pinned and index == currentTab then
		Tabs[index].CFrame = workspace.CurrentCamera.CFrame
		Tabs[index].Focus = workspace.CurrentCamera.Focus
		Tabs[index].FieldOfView = workspace.CurrentCamera.FieldOfView
		Tabs[index].Object.Value = workspace.CurrentCamera.CFrame
		Tabs[index].Object:SetAttribute("Focus", workspace.CurrentCamera.Focus)
		Tabs[index].Object:SetAttribute("FieldOfView", workspace.CurrentCamera.FieldOfView)
	end

	update:Fire(Tabs)
end

local buttonClicked = false
local hovering = false
local enabled, setEnabled = Roact.createBinding(false)

button.Click:Connect(function()
	buttonClicked = not buttonClicked
	setEnabled(buttonClicked)
	button:SetActive(buttonClicked)
end)

local function updateVisibility()
	if buttonClicked then return end
	if UserInputService:GetFocusedTextBox() then return end
	local isHoldingKey = UserInputService:IsKeyDown(Enum.KeyCode.Space)
	setEnabled(isHoldingKey or hovering or hasNewTab)
end

UserInputService.InputBegan:Connect(updateVisibility)
UserInputService.InputChanged:Connect(updateVisibility)
UserInputService.InputEnded:Connect(updateVisibility)

local newApp = Roact.createElement(App, {
	Enabled = enabled,
	Tabs = Tabs,
	Update = update,

	OnActivated = Activate,
	OnRemove = Remove,
	OnUpdateName = UpdateName,
	OnUpdateIndex = UpdateIndex,
	Add = Add,
	SetNew = SetNew,
	Pin = Pin,
	Hovering = function(state)
		hovering = state
		updateVisibility()
	end,
	ToggleTooltip = function()
		-- dumb hack to remove the default context menu when right-clicking over viewport
		task.defer(function()
			menu:AddNewAction(`temp_action {actionId}`, "")
			actionId += 1
			menu:ShowAsync()
		end)
		task.defer(function()
			menu:Clear()
		end)
	end
})

local handle = Roact.mount(newApp, game.CoreGui, "Camera-Switcher")

plugin.Unloading:Connect(function()
	Roact.unmount(handle)
end)