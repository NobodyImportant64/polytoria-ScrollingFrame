-- Written by SpaceAgeCapitalist 5/13/2026

-- README:
	-- This module implements the ScrollingFrame class which represents a UIView which can be vertically scrolled a defined number of pixels.
	--
	-- To construct a ScrollingFrame, use the ScrollingFrame.Embed() function to "embed" a scrolling frame into any existing UI element
	-- which inherits UIField. This function returns a refrence to a ScrollingFrame object which contains two fields:
		-- ScrollingFrame.ScrollingSizeY represents the vertical depth of the frame. This is the limit for how far a user can scroll down.
		-- ScrollingFrame.Frame provides an access point to the actual UIView object which scrolls up and down.
	--
	-- IMPORTANT: UI elements that go inside of the scrolling frame must be parented to ScrollingFrame.Frame, NOT ScrollingFrame itself.
	-- When a scrolling frame is embeded, it automatically migrates all of the Adornee's original children into the scrolling frame.
	--
	-- Since scrolling frames use events to listen for scroll wheel inputs, you should use the ScrollingFrame:Destroy() function to properly
	-- dispose of a ScrollingFrame object without leaking memory.

-- Internal ScrollingFrame type
type ScrollingFrame = {
	__enterEvent: PTSignalConnection;
	__exitEvent: PTSignalConnection;
	__keyDownEvent: PTSignalConnection;
	__active: boolean;
	__ScrollSizeY: number;
	__frame: UIView;
	
	ScrollingSizeY: number;
	Frame: UIView;
	
	Destroy: (self: ScrollingFrame) -> nil;
}

-- External ScrollingFrame type (copy this typedef to other scripts and modules)
export type ScrollingFrame = {
	ScrollingSizeY: number;
	Frame: UIView;
	
	Destroy: (self: ScrollingFrame) -> nil;
}

-- Module typedef (copy to scripts requiring this module to get accurate luau typechecking when referencing the module itself)
export type MODULE_ScrollingFrame = {
	Embed: (Adornee: UIField) -> ScrollingFrame
}

local module: MODULE_ScrollingFrame = {}

local meta = {
	__index = function(self: ScrollingFrame, i: any)
		if(i == "Destroy") then
			return function()
				self.__enterEvent:Disconnect()
				self.__exitEvent:Disconnect()
				self.__keyDownEvent:Disconnect()
				self.__frame:Destroy()
			end
		end
		
		if(i == "ScrollingSizeY") then
			return self.__ScrollSizeY
		end
		
		if(i == "Frame") then
			return self.__frame
		end
		
		return self.__frame[i]
	end;
	
	__newindex = function(self: ScrollingFrame, i: any, v: any)
		if(i == "ScrollingSizeY") then
			self.__ScrollSizeY = v
			self.__frame.SizeOffset = Vector2.new(0,v)
			return
		end
		
		self.__frame[i] = v
	end;
}

local __ScrollSensitivity

function module.Embed(Adornee: UIField, ScrollSizeY: number?, ScrollPixels: number?): ScrollingFrame
	ScrollPixels = ScrollPixels or 50
	ScrollSizeY  = ScrollSizeY or Adornee.AbsoluteSize.Y

	local self: ScrollingFrame = setmetatable({}, meta)
	
	rawset(self, "__active", false)
	rawset(self, "__frame", Instance.New("UIView"))
	rawset(self, "__ScrollSizeY", ScrollSizeY)
	self.__frame.Name = "ScrollingFrame"
	self.__frame.PivotPoint   = Vector2.New(0,0)
	self.__frame.SizeOffset   = Vector2.New(0,ScrollSizeY)
	self.__frame.SizeRelative = Vector2.New(1,0)
	self.__frame.PositionRelative = Vector2.New(0,0)
	self.__frame.PositionOffset = Vector2.New(0,0)
	self.__frame.ClipDescendants = true
	self.__frame.ZIndex = -1
		
	-- Reparent adornee's children
	for i, child in pairs(Adornee:GetChildren()) do
		child.Parent = self.__frame
	end
	
	self.__frame.Parent = Adornee
	
	local __enterEvent = Adornee.MouseEnter:Connect(function()
		self.__active = true
		if Environment.CurrentCamera.ScrollSensitivity ~= 0 then
			__ScrollSensitivity = Environment.CurrentCamera.ScrollSensitivity
			Environment.CurrentCamera.ScrollSensitivity = 0
		end
	end)
	
	local __exitEvent = Adornee.MouseExit:Connect(function()
		self.__active = false
		Environment.CurrentCamera.ScrollSensitivity = __ScrollSensitivity
	end)
	
	local __keyDownEvent = Input.KeyDown:Connect(function(KeyCode)
		if(self.__active == false) then return end
		
		if (tostring(KeyCode) == tostring(Enums.KeyCode.MouseWheelDown)) then
			self.__frame.PositionOffset = Vector2.New(0,math.clamp(self.__frame.PositionOffset.Y - ScrollPixels, math.min(Adornee.AbsoluteSize.Y - self.__ScrollSizeY, 0), 0))
		elseif(tostring(KeyCode) == tostring(Enums.KeyCode.MouseWheelUp)) then
			self.__frame.PositionOffset = Vector2.New(0,math.clamp(self.__frame.PositionOffset.Y + ScrollPixels, math.min(Adornee.AbsoluteSize.Y - self.__ScrollSizeY, 0), 0))
		end
		print(self.__frame.PositionOffset.Y)
	end)
	
	rawset(self, "__enterEvent", __enterEvent)
	rawset(self, "__exitEvent", __exitEvent)
	rawset(self, "__keyDownEvent", __keyDownEvent)
	
	return self
end

return module