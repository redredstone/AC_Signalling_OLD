--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

--Constants
local BridgeNet2 = require(ReplicatedStorage.cframe_common:WaitForChild("BridgeNet2"))

local SignallingSystem = _Workspace:WaitForChild("SignallingSystem")
local Signals = SignallingSystem:WaitForChild("Signals")
local Markers = SignallingSystem:WaitForChild("Sensors")

--Variables
local offTransparency = 0.1
local onTransparency = 0.75

local StopTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0)
local DiscTweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0)

local SignalTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0)

local failureMin = 1
local failureMax = 5
local possibleFailures = 2
--Arrays
local TrainList = {}
local MarkerTable = {"Entry","Exit"}

--Events
local inbound = BridgeNet2.ReferenceBridge("SignallingInbound")
local outbound = BridgeNet2.ReferenceBridge("SignallingOutbound")

--Init

for _, signalMain in pairs(Signals:GetDescendants()) do
	if signalMain.Parent == Signals and signalMain.Parent.Parent == SignallingSystem then --Main folder of the signal
		
		local succ, err
		
		succ, err = pcall(function()
			local aspect = signalMain:GetAttribute("Aspect")
			local isFake = signalMain:GetAttribute("isFake")
			
			--Train Stops
			if aspect ~= "Disabled" then
				for _, tripLever in pairs(signalMain.TrainStops:GetDescendants()) do
					if tripLever.Name == "Arm" or tripLever.Name == "Disarmed" then
						local originCFrame = tripLever:FindFirstChild("originalCFrame") or Instance.new("CFrameValue")
						originCFrame.Name = "originalCFrame"
						originCFrame.Value = tripLever.CFrame
						originCFrame.Parent = tripLever
						if isFake then
							local tween = TweenService:Create(tripLever, StopTweenInfo, {CFrame = tripLever.originalCFrame.Value * CFrame.Angles(math.rad(40),0,0) * CFrame.new(0, 0.248, 0.005)})
							tween:Play()
							tripLever.Name = "Arm"
						else
							local tween = TweenService:Create(tripLever, StopTweenInfo, {CFrame = tripLever.originalCFrame.Value})
							tween:Play()
							local con
							con = tween.Completed:Connect(function()
								tripLever.Name = "Disarmed"
							end)
							con:Disconnect()
						end
					end
				end
			end
			
			--Signals
			if aspect ~= "Disabled" then
				for _, signalLight in pairs(signalMain.Signals:GetDescendants()) do
					if signalLight.Parent.Name == "SignalLamps" then
						if isFake ~= true then --Fake signals as of the signal is in an area where the trains can't go (like sidings where trains can't spawn)
							signalMain:SetAttribute("Aspect","Green")
							if signalLight.Name == "Green" then
								signalLight.Transparency = onTransparency
							else
								signalLight.Transparency = offTransparency
							end
						else --Fake signal
							signalMain:SetAttribute("Aspect","Red")
							if signalLight.Name == "Red" then
								signalLight.Transparency = onTransparency
							else
								signalLight.Transparency = offTransparency
							end
						end
					elseif signalLight.Parent.Name == "SignalHead" then
						if isFake ~= true then
							local originalPosition = signalLight:FindFirstChild("originalPosition") or Instance.new("CFrameValue")
							originalPosition.Parent = signalLight
							originalPosition.Value = signalLight.CFrame
							originalPosition.Name = "originalPosition"
							local tween = TweenService:Create(signalLight, DiscTweenInfo, {CFrame = originalPosition.Value * CFrame.Angles(math.rad(-45),0,0)})
							tween:Play()
							local con
							con = tween.Completed:Connect(function()
								tween:Destroy()
							end)
							con:Disconnect()
							signalMain:SetAttribute("Aspect","Green")
						else
							local originalPosition = signalLight:FindFirstChild("originalPosition") or Instance.new("CFrameValue")
							originalPosition.Parent = signalLight
							originalPosition.Value = signalLight.CFrame
							originalPosition.Name = "originalPosition"
							local tween = TweenService:Create(signalLight, DiscTweenInfo, {CFrame = originalPosition.Value * CFrame.Angles(0,0,0)})
							tween:Play()
							local con
							con = tween.Completed:Connect(function()
								tween:Destroy()
							end)
							con:Disconnect()
							signalMain:SetAttribute("Aspect","Red")
						end
					end

					--Plates
					if signalLight.Name == "HeadcodePlate" then
						signalLight.SurfaceGui.TextBox.Text = signalMain.Name
					end
				end

				--Repeaters

				for _, repeaterLight in pairs(signalMain.Repeaters:GetDescendants()) do
					if repeaterLight.Parent.Name == "LightsRep" then
						if repeaterLight.Parent.Parent:FindFirstChild("suppression") then
							if isFake == true or repeaterLight.Parent.Parent:FindFirstChild("suppression").Value:GetAttribute("isFake") == true then
								if repeaterLight.Name == "Green" then
									repeaterLight.Transparency = offTransparency
								else
									repeaterLight.Transparency = offTransparency
								end
							else
								if repeaterLight.Name == "Green" then
									repeaterLight.Transparency = onTransparency
								else
									repeaterLight.Transparency = offTransparency
								end
							end
						else
							if isFake ~= true then
								if repeaterLight.Name == "Green" then
									repeaterLight.Transparency = onTransparency
								else
									repeaterLight.Transparency = offTransparency
								end
							else
								if repeaterLight.Name == "Red" then
									repeaterLight.Transparency = onTransparency
								else
									repeaterLight.Transparency = offTransparency
								end
							end
						end
					end

					--Plates
					if repeaterLight.Name == "HeadcodePlate" then
						repeaterLight.SurfaceGui.TextBox.Text = "R"..signalMain.Name
					end
				end
			end
			
		end)
		
		if not succ then
			warn("Error detected during startup, shutting down... | "..err)
			
			local aspect = signalMain:GetAttribute("Aspect")
			aspect = "FAILURE"
			
			for _, i in pairs(Signals:GetDescendants()) do
				if i.Parent.Name == "LightsRep" or i.Parent.Name == "SignalLamps" then
					i.Transparency = offTransparency
				end
				if i.Parent.Name == "SignalHead" then
					i.Orientation = Vector3.new(0,0,0)
				end
			end
		end
		
	end
end

for _, markers in pairs(Markers:GetChildren()) do
	if table.find(MarkerTable, markers.Name) then
		if markers:IsA("BasePart") then
			markers.CanCollide = false
			markers.Anchored = true
			if script.hideSignalBlocks.Value then
				markers.Transparency = 1
			else
				markers.Transparency = 0.4
			end
		end
	end
end

--Functions
function getSignals(block)
	local signalsWithID = {}
	for _, i in pairs(Signals:GetChildren()) do
		if i:GetAttribute("internalID") == block:GetAttribute("internalID") then
			if not table.find(signalsWithID, i) then
				table.insert(signalsWithID, i)
			end
		end
	end
	return signalsWithID
end

function getSignalAspect(SignalID)
	for _, signal in pairs(Signals:GetChildren()) do
		if signal:GetAttribute("internalID") == SignalID then
			return signal:GetAttribute("Aspect")
		end
	end
end

function signalFailure(signalID)
	local num = math.random(failureMin, failureMax)
	if num == 1 then
		print("Signal failed! ID: "..signalID)
		return true
	else
		print("No failure, number: "..num)
		return false
	end
end

function updateAspect(Signal : Folder, Aspect : string, fixed : boolean) --fixed will only have a value if the signal just got fixed
	if Signal:GetAttribute("isFake") ~= true then
		if Signal:GetAttribute("Aspect") ~= Aspect then
			Signal:SetAttribute("Aspect", Aspect)
			local isFailed = false
			if script.SignalFailureEnabled.Value then
				isFailed = signalFailure(Signal:GetAttribute("internalID"))
			end
			if isFailed and (not fixed or fixed == nil) then
				Signal:SetAttribute("isFailed",isFailed)
			end
			for _, signal in pairs(Signal.Signals:GetDescendants()) do
				--Update the signals and repeaters
				if signal.Parent.Name == "SignalLamps" then -- Regular signal
					if isFailed or Signal:GetAttribute("failed") then
						if signal.Name == "Red" and not signal:FindFirstChild("SignalFixPrompt") then
							local num = math.random(1, possibleFailures)
							if num == 1 then
								local tween = TweenService:Create(signal, SignalTweenInfo, {Transparency = offTransparency})
								tween:Play()
								
								local prompt = Instance.new("ProximityPrompt")
								prompt.Parent = signal
								task.wait(0.05)
								prompt.Parent = signal.Parent.Parent

								prompt.HoldDuration = 3
								prompt.MaxActivationDistance = 50

								prompt.ObjectText = "Signal failure"
								prompt.ActionText = "Fix signal"
								prompt.Name = "SignalFixPrompt"

								prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow		
								prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
								prompt.KeyboardKeyCode = Enum.KeyCode.F

								prompt.Triggered:Connect(function()
									Signal:SetAttribute("isFailed", false)
									local tempSave = Signal:GetAttribute("Aspect")
									Signal:SetAttribute("Aspect","TempAspect")
									updateAspect(Signal, tempSave, true)
									prompt:Destroy()
								end)
							elseif num == 2 then
								local tween = TweenService:Create(signal, SignalTweenInfo, {Transparency = onTransparency})
								tween:Play()
								
								local prompt = Instance.new("ProximityPrompt")
								prompt.Parent = signal
								task.wait(0.05)
								prompt.Parent = signal.Parent.Parent

								prompt.HoldDuration = 3
								prompt.MaxActivationDistance = 50

								prompt.ObjectText = "Train stop failure"
								prompt.ActionText = "Fix signal"
								prompt.Name = "SignalFixPrompt"

								prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow		
								prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
								prompt.KeyboardKeyCode = Enum.KeyCode.F
								
								prompt.Triggered:Connect(function()
									Signal:SetAttribute("isFailed", false)
									local tempSave = Signal:GetAttribute("Aspect")
									Signal:SetAttribute("Aspect","TempAspect")
									updateAspect(Signal, tempSave, true)
									prompt:Destroy()
								end)
							end
						end
					else
						if signal.Name == Aspect then
							local tween = TweenService:Create(signal, SignalTweenInfo, {Transparency = onTransparency})
							tween:Play()
						elseif signal.Name ~= Aspect then
							local tween = TweenService:Create(signal, SignalTweenInfo, {Transparency = offTransparency})
							tween:Play()
						end
					end

					--Repeaters
					for _, repLamps in pairs(Signal.Repeaters:GetDescendants()) do
						if repLamps.Parent.Name == "LightsRep" then
							if repLamps.Parent.Parent:FindFirstChild("suppression") then
								local suppression = repLamps.Parent.Parent:FindFirstChild("suppression")
								if suppression.Value ~= nil then
									if suppression.Value:GetAttribute("Aspect") == "Red" then
										if repLamps.Name == "Yellow" then
											local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = offTransparency})
											tween:Play()
										else
											local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = offTransparency})
											tween:Play()
										end
									else
										if Aspect == "Red" then
											if repLamps.Name == "Yellow" then
												local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = onTransparency})
												tween:Play()
											else
												repLamps.Transparency = offTransparency
												local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = offTransparency})
												tween:Play()
											end
										else
											if repLamps.Name == "Yellow" then
												repLamps.Transparency = offTransparency
												local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = offTransparency})
												tween:Play()
											else
												local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = onTransparency})
												tween:Play()
											end
										end
									end
								end
							else
								if Aspect == "Red" then
									if repLamps.Name == "Yellow" then
										local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = onTransparency})
										tween:Play()
									else
										local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = offTransparency})
										tween:Play()
									end
								else
									if repLamps.Name == "Yellow" then
										local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = offTransparency})
										tween:Play()
									else
										local tween = TweenService:Create(repLamps, SignalTweenInfo, {Transparency = onTransparency})
										tween:Play()
									end
								end
							end
						end
					end

					--Other repeaters
					for _, repLampsOut in pairs(Signals:GetDescendants()) do
						if repLampsOut.Parent.name == "LightsRep" then
							if repLampsOut.Parent.Parent:FindFirstChild("suppression") then
								local suppression = repLampsOut.Parent.Parent:FindFirstChild("suppression")
								if suppression.Value == Signal then
									local mainSignal = suppression.Parent.Parent.Parent
									if Aspect == "Red" then
										if repLampsOut.Name == "Yellow" then
											local tween = TweenService:Create(repLampsOut, SignalTweenInfo, {Transparency = offTransparency})
											tween:Play()
										else
											local tween = TweenService:Create(repLampsOut, SignalTweenInfo, {Transparency = offTransparency})
											tween:Play()
										end
									else
										if mainSignal:GetAttribute("Aspect") == "Red" then
											if repLampsOut.Name == "Yellow" then
												local tween = TweenService:Create(repLampsOut, SignalTweenInfo, {Transparency = onTransparency})
												tween:Play()
											else
												local tween = TweenService:Create(repLampsOut, SignalTweenInfo, {Transparency = offTransparency})
												tween:Play()
											end
										else
											if repLampsOut.Name == "Yellow" then
												local tween = TweenService:Create(repLampsOut, SignalTweenInfo, {Transparency = offTransparency})
												tween:Play()
											else
												local tween = TweenService:Create(repLampsOut, SignalTweenInfo, {Transparency = onTransparency})
												tween:Play()
											end
										end
									end
								end
							end
						end
					end
				elseif signal.Parent.Name == "SignalHead" then -- Shut up signal
					if Signal:GetAttribute("Aspect") ~= Aspect then
						Signal:SetAttribute("Aspect", Aspect)
						if signal:FindFirstChild("originalPosition") ~= nil then
							local originalPosition = signal:FindFirstChild("originalPosition")
							if Aspect == "Red" then
								local tween = TweenService:Create(signal, DiscTweenInfo, {CFrame = originalPosition.Value})
								tween:Play()
							else
								local tween = TweenService:Create(signal, DiscTweenInfo, {CFrame = originalPosition.Value * CFrame.Angles(math.rad(-45),0,0)})
								tween:Play()
							end
						end

						--Repeaters
						for _, repLamps in pairs(Signal.Repeaters:GetDescendants()) do
							if repLamps.Parent.Name == "LightsRep" then
								if repLamps.Parent.Parent:FindFirstChild("suppression") then
									local suppression = repLamps.Parent.Parent:FindFirstChild("suppression")
									if suppression.Value ~= nil then
										if suppression.Value:GetAttribute("Aspect") == "Red" then
											if repLamps.Name == "Yellow" then
												repLamps.Transparency = offTransparency
											else
												repLamps.Transparency = offTransparency
											end
										else
											if repLamps.Parent.Parent:GetAttribute("NextSignalID") then
												for _, signal in pairs(Signals:GetChildren()) do
													if signal:GetAttribute("internalID") == repLamps.Parent.Parent:GetAttribute("NextSignalID") then
														if Aspect == "Red" then
															if repLamps.Name == "Yellow" then
																repLamps.Transparency = onTransparency
															else
																repLamps.Transparency = offTransparency
															end
														else
															if repLamps.Name == "Yellow" then
																repLamps.Transparency = offTransparency
															else
																repLamps.Transparency = onTransparency
															end
														end
													end
												end
											else
												if Aspect == "Red" then
													if repLamps.Name == "Yellow" then
														repLamps.Transparency = onTransparency
													else
														repLamps.Transparency = offTransparency
													end
												else
													if repLamps.Name == "Yellow" then
														repLamps.Transparency = offTransparency
													else
														repLamps.Transparency = onTransparency
													end
												end
											end
										end
									end
								else
									if Aspect == "Red" then
										if repLamps.Name == "Yellow" then
											repLamps.Transparency = onTransparency
										else
											repLamps.Transparency = offTransparency
										end
									else
										if repLamps.Name == "Yellow" then
											repLamps.Transparency = offTransparency
										else
											repLamps.Transparency = onTransparency
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function updateTrip(Signal : Folder, Aspect : string)
	if Signal ~= nil then
		task.wait(1)
		local isStop = false
		for _, stop in pairs(Signal.TrainStops:GetDescendants()) do
			if stop.Name == "Arm" or stop.Name == "Disarmed" then
				isStop = true
				if Aspect == "Red" then
					if stop:FindFirstChild("originalCFrame") then
						local position = {CFrame = stop.originalCFrame.Value * CFrame.Angles(math.rad(40),0,0) * CFrame.new(0, 0.248,0.005)}
						local tween = TweenService:Create(stop, StopTweenInfo, position)
						tween:Play()
						updateAspect(Signal, Aspect)
						local con
						con = tween.Completed:Connect(function()
							tween:Destroy()
						end)
						con:Disconnect()
					else
						warn("NOT FOUND")
					end
				else
					if stop:FindFirstChild("originalCFrame") then
						local position = {CFrame = stop.originalCFrame.Value}
						local tween = TweenService:Create(stop, StopTweenInfo, position)
						for _, lamps in pairs(Signal.Signals:GetDescendants()) do
							if lamps.Parent.Name == "SignalLamps" then
								if lamps.Name == "Green" then
									local tween = TweenService:Create(lamps, SignalTweenInfo, {Transparency = onTransparency})
									tween:Play()
								end
							end
						end
						tween:Play()
						local con
						con = tween.Completed:Connect(function()
							updateAspect(Signal, Aspect)
							tween:Destroy()
							con:Disconnect()
						end)
					else
						warn("NOT FOUND")
					end
				end
			end
		end
		if not isStop then
			updateAspect(Signal, Aspect)
		else
			return
		end
	end
end

function findTrain(blockID : number, TrainID : number)
	--[1] SignalBlock [2] TrainID
	for i,v in pairs(TrainList) do
		if v[1] == blockID and v[2] == TrainID then
			return {true, i}
		end
	end
	return {false}
end

function onEvent(plr, content)
	-- [1] Action [2] Block [3] TrainID [4] Aspect [5] Carriage
	-- or
	-- [1] Action [2] SignalID [3] Aspect
	
	local Carriage = content[5]
	local Block = content[2]
	local Train = content[3]
	
	
	if content[1] == "Manual" then
		--Nothing here yet lol
		return
	elseif content[1] == "Auto" then
		-- hi
		--hello
		Block:SetAttribute("lastTrain", Train:GetAttribute("TrainID"))
		
		if Block then
			if Block.Name == "Exit" then
				local prevSignalID = Block:GetAttribute("prevSignalID")
				local signalID = Block:GetAttribute("signalID")

				local succ, err
				
				succ, err = pcall(function()
					if signalID == 0 and prevSignalID ~= 0 then
						while findTrain(prevSignalID, Train:GetAttribute("TrainID"))[1] do
							table.remove(TrainList, findTrain(prevSignalID, Train:GetAttribute("TrainID"))[2])
						end
					elseif prevSignalID == 0 and signalID ~= 0 then
						while findTrain(signalID, Train:GetAttribute("TrainID"))[1] do
							table.remove(TrainList, findTrain(signalID, Train:GetAttribute("TrainID"))[2])
						end
					else
						warn("NO SIGNAL ID")
					end
					if Carriage == "Front" or Carriage == "Back" then
						if Block:GetAttribute("isBack") then
							for _, i in pairs(Signals:GetChildren()) do
								if i:GetAttribute("internalID") == signalID and signalID ~= 0 then
									if Carriage == "Back" then
										updateTrip(i, "Green")
									end
								elseif i:GetAttribute("internalID") == prevSignalID and prevSignalID ~= 0 then
									if Carriage == "Front" then
										updateTrip(i, "Green")
									end
								end
							end
						else
							for _, i in pairs(Signals:GetChildren()) do
								if i:GetAttribute("internalID") == signalID and Carriage == "Front" then
									updateTrip(i, "Green")
								elseif i:GetAttribute("internalID") == prevSignalID and Carriage == "Back" and prevSignalID ~= 0 then
									updateTrip(i, "Green")
								end
							end
						end
					else
						warn("Carriage value invalid!")
						return
					end
				end)

				if not succ then
					warn("An error has occured. Error: "..err)
				end

			elseif Block.Name == "Entry" then
				local prevSignalID = Block:GetAttribute("prevSignalID")
				local signalID = Block:GetAttribute("signalID")
				Block:SetAttribute("lastTrain", Train:GetAttribute("TrainID"))

				local succ, err

				succ, err = pcall(function()
					if not findTrain(signalID, Train:GetAttribute("TrainID"))[1] or Carriage == "Back" then
						if Carriage == "Front" or Carriage == "Back" then
							table.insert(TrainList, {signalID, Train:GetAttribute("TrainID")})
							for _, i in pairs(Signals:GetChildren()) do
								if i:GetAttribute("internalID") == signalID and Carriage == "Front" then
									updateTrip(i, "Red")
								elseif i:GetAttribute("internalID") == prevSignalID and Carriage == "Back" then
									while findTrain(prevSignalID, Train:GetAttribute("TrainID"))[1] do
										table.remove(TrainList, findTrain(prevSignalID, Train:GetAttribute("TrainID"))[2])
									end
									updateTrip(i, "Green")
								end
							end
						else
							warn("Carriage value invalid!")
							return
						end
					else
						return
					end
				end)

				if not succ then
					warn("An error has occured. Error: "..err)
				end
			else
				return
			end
		end
	elseif content[1] == "Debug" then
		local signalID = content[2]
		local aspect = content[3]
		if aspect == "G" then
			for _, i in pairs(Signals:GetChildren()) do
				if i:GetAttribute("internalID") == signalID then
					updateTrip(i, "Green")
				end
			end
		elseif aspect == "R" then
			for _, i in pairs(Signals:GetChildren()) do
				if i:GetAttribute("internalID") == signalID then
					updateTrip(i, "Red")
				end
			end
		end
	end
end

local function wipe_signal_with_train_id_last(trainId) --Wipe the train ID from the system
	for i,v in pairs(workspace.SignallingSystem.Signals:GetChildren()) do
		if v:GetAttribute("lastTrain") == trainId then
			updateAspect(v, "Green")
		end
	end
end

--Connections
inbound:Connect(onEvent)

script.Signal.Event:Connect(function(signal, aspect, clear, train_id)
	if clear == true then
		wipe_signal_with_train_id_last(train_id)
	else
		updateAspect(signal, aspect)
	end
end)

script.Signal2.Event:Connect(function(train_id)
	for i,v in pairs(workspace.SignallingSystem.Sensors:GetChildren()) do
		if v:GetAttribute("lastTrain") == train_id then
			for a,b in pairs(workspace.SignallingSystem.Signals:GetChildren()) do
				if b:GetAttribute("internalID") == v:GetAttribute("signalID") then
					updateAspect(b, "Green")
				end
			end
		end
	end
end)
