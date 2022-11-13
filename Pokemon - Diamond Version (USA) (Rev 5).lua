NeuralNetwork = {}
UIDrawer = {}
ReplayMemory = {}

input = {}
inputScannerBorderString = "---------------------"
inputScannerWidth = 11
inputScannerHeight = 11
output = {}

neuralNetworks = {}
neuralNetworkLayers = {inputScannerWidth * inputScannerHeight, 60, 60, 60, 5}
neuralNetworkLayersBackPropagationTest = {1, 2, 1, 1}
neuralNetworkIndex = 1
neuralNetworkCount = 20
goodNeuralNetworkCount = 5
averageNeuralNetworkCount = 5
neuralNetworkNegativeColor = "Red"
neuralNetworkPositiveColor = "Green"
neuralNetworkType = "Q Learning"

bestRun = -1
totalRuns = 0
runTime = 1000
runTimer = 0
evolution = 0

mutationChance = 40
mutationStrength = 10

joypadTable = {}
joypadControl = true

playerPositionX = 0
playerPositionY = 0
playerPositionXAddress = 0x291D3C
playerPositionYAddress = 0x291D44
playerPositionXAddressForWrite = 0x291D48
playerPositionYAddressForWrite = 0x291D50
previousPlayerPositionX = 0
previousPlayerPositionY = 0
playerRotation = 0
playerRotationAddress = 0x291D14
playerWalkingTowardsTileType = 0
playerWalkingTowardsTileTypeAddress = 0x291D84
playerTileType = 0
playerTileTypeAddress = 0x291D92
playerRepetitiveStuckPositionX = 0
playerRepetitiveStuckPositionY = 0
playerRepetitiveStuckDistance = 3
playerRepetitiveStuckCurrentCount = 0
playerRepetitiveStuckMaxCount = 10
isPlayerRepetitiveStuckActive = true
isPlayerInConversation = false
playerConversationAddress = 0x39E544

worldGrid = {}
worldGridWidth = 1000
worldGridHeight = 1000
worldGridCreatorTimer = 0
worldGridCreatorX = 100
worldGridCreatorY = 856
worldGridCreatorIndex = 0
worldGridSaveFileName = "World Grid.txt"
unExploredTileInput = 0
exploredTileInput = 1
wallInput = 2
wallColor = "White"
npcInput = 3
npcColor = "Yellow"
grassInput = 4
grassColor = "DarkGreen"

stuckTime = 40
isRunTimerActive = true
stuckTimer = 0
isStuckTimerActive = true

bestFitness = 0
fitnessPlayerMoving = 0
fitnessPlayerSpeed = 0

saveState = 5

saveFileName = "Best Neural Network.txt"

replayAfterEvolution = false
replayTime = 150
replayFormat = "Replay #%s"

extraBorderWidth = 360

trainingTextPositionX = 5
trainingTextPositionY = 5
trainingTextOffsetY = 20

replayMemory = nil
replayMemorySize = 150

--print(joypad.getimmediate())

function printInputScanner(input)
	local inputScannerStrings = {}
	local inputScannerIndex = 1

	for i = 1, inputScannerWidth do
		for j = 1, inputScannerHeight do
			if inputScannerStrings[j] == nil then
				inputScannerStrings[j] = ""
			end

			inputScannerStrings[j] = inputScannerStrings[j] .. tostring(input[inputScannerIndex])

			inputScannerIndex = inputScannerIndex + 1
		end
	end

	for i = 1, #(inputScannerStrings) do
		print(inputScannerStrings[i])
	end

	print(inputScannerBorderString)
end

function setJoypadInput(joypadTable)
	if joypadControl then
		return
	end

	joypad.set(joypadTable)
end

function enableRunTimers()
	isRunTimerActive = true
	isStuckTimerActive = true
	isPlayerRepetitiveStuckActive = true
end

function disableRunTimers()
	isRunTimerActive = false
	isStuckTimerActive = false
	isPlayerRepetitiveStuckActive = false
end

function manhattanDistance(x1, y1, x2, y2)
	return math.abs(x1 - x2) + math.abs(y1 - y2)
end

function deltaTime()
	return 1 / client.get_approx_framerate()
end

function arrayLength2D(array)
	local length = 0

	for i = 1, #(array) do
		length = length + #array[i]
	end
	
	return length
end

function arrayLength3D(array)
	local length = 0

	for i = 1, #(array) do
		for j = 1, #(array[i]) do
			length = length + #array[i][j]
		end
	end
	
	return length
end

function getJoypadTableFromOutput(output)
	local joypadTable = {
		Right = output[1] > 0,
		Left = output[2] > 0,
		Up = output[3] > 0,
		Down = output[4] > 0,
		B = output[5] > 0
	}

	return joypadTable
end

function getRandomOutput()
	local joypadTable = {}
	local buttonCount = 5

	for i = 1, buttonCount do
		local randomInt = math.random(0, 100)

		if (randomInt <= 100 / buttonCount) then
			joypadTable[i] = 1
		else
			joypadTable[i] = 0
		end
	end

	return joypadTable
end

function fileExists(fileName)
	local saveFile = io.open(fileName, "r")

	if saveFile then saveFile:close() end

	return saveFile ~= nil
end

function isInputEqual(input1, input2)
	inputEqual = true

	for i = 1, #(input1) do
		if (input1[i] ~= input2[i]) then
			inputEqual = false
		end
	end

	return inputEqual
end

function isInGridRange(x, y, width, height)
	if 
		x >= 1 and
		x <= width and
		y >= 1 and
		y <= height
	then
		return true
	end

	return false
end

function isInWorldGridRange(x, y)
	return isInGridRange(x, y, #(worldGrid), #(worldGrid[1]))
end

function isPlayerInGridRange()
	return isInWorldGridRange(playerPositionX, playerPositionY)
end

function readFromMemory()
	playerPositionX = memory.read_s32_le(playerPositionXAddress)
	playerPositionY = memory.read_s32_le(playerPositionYAddress)
	playerRotation = memory.read_s32_le(playerRotationAddress)
	playerWalkingTowardsTileType = memory.read_s32_le(playerWalkingTowardsTileTypeAddress)
	playerTileType = memory.read_s16_le(playerTileTypeAddress)
	isPlayerInConversation = numberToBool(memory.read_s32_le(playerConversationAddress))
end

function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function boolToNumber(value)
	return value and 1 or 0
end

function numberToBool(value)
	if value == 1 then
		return true
	elseif value == 0 then
		return false
	end

	return false
end

function playerMovedOneStep()
	return playerPositionX ~= previousPlayerPositionX or playerPositionY ~= previousPlayerPositionY
end

function saveWorldGrid(fileName)
	local saveFile = io.open(fileName, "w")

	saveFile:write(worldGridWidth, "\n")
	saveFile:write(worldGridHeight, "\n")

	for i = 1, #(worldGrid) do
		for j = 1, #(worldGrid[i]) do
			saveFile:write(worldGrid[i][j], "\n")
		end
	end

	io.close(saveFile)
end

function loadWorldGrid(fileName)
	local lines = {}
	local index = 1

	for line in io.lines(fileName) do 
		lines[#lines + 1] = line
	end

	worldGridWidth = tonumber(lines[index])
	index = index + 1

	worldGridHeight = tonumber(lines[index])
	index = index + 1

	for i = 1, worldGridWidth do
		for j = 1, worldGridHeight do
			worldGrid[i][j] = tonumber(lines[index])
			index = index + 1
		end
	end
end

function initWorldGrid()
	for i = 1, worldGridWidth do
		worldGrid[i] = {}

		for j = 1, worldGridHeight do
			worldGrid[i][j] = 0
		end
	end
end

function initNeuralNetworks()
	for i = 1, neuralNetworkCount do
		neuralNetworks[i] = NeuralNetwork:new(neuralNetworkLayers)

		if fileExists(saveFileName) then
			neuralNetworks[i]:load(saveFileName)
		end
	end

	if fileExists(saveFileName) then
		mutate()
	else
		mutateAll()
	end
end

function initNeuralNetworksForQLearning()
	neuralNetworks[1] = NeuralNetwork:new(neuralNetworkLayers)
	neuralNetworks[2] = NeuralNetwork:new(neuralNetworkLayers)

	if fileExists(saveFileName) then
		neuralNetworks[1]:load(saveFileName)
	else
		neuralNetworks[1]:mutate(100, mutationStrength)
	end

	neuralNetworks[1]:copy(neuralNetworks[2])
end

function initNeuralNetworksForBackPropagationTest()
	neuralNetworks[1] = NeuralNetwork:new(neuralNetworkLayersBackPropagationTest)
	neuralNetworks[1]:mutate(100, mutationStrength * 5)
end

function initReplayMemory()
	replayMemory = ReplayMemory:new(replayMemorySize)
end

function replay()
	replayAfterEvolution = true

	print("Replay will show after next evolution")
end

function gameCenterX()
	return (client.screenwidth() + extraBorderWidth) / 2
end

function gameCenterY()
	return client.screenheight() / 2
end

function initTrainingLoop()
	gui.clearGraphics()

	readFromMemory()

	-- Start of run initialization
	if runTimer == 0 and isRunTimerActive then
		-- Reset previous player position if a new run started
		updatePlayerPreviousPosition()

		playerRepetitiveStuckPositionX = playerPositionX
		playerRepetitiveStuckPositionY = playerPositionY

		-- Start position is explored
		worldGrid[playerPositionX][playerPositionY] = 1
	end
end

function trainingLoopPlayerMoved()
	-- Player moved one step
	if playerMovedOneStep() then
		updatePlayerRepetitiveStuck()

		updatePlayerMovementFitness()

		stuckTimer = 0
	end
end

function updatePlayerPreviousPosition()
	previousPlayerPositionX = playerPositionX
	previousPlayerPositionY = playerPositionY
end

function updatePlayerRepetitiveStuck()
	if not isPlayerRepetitiveStuckActive then
		return
	end

	-- If player stays within a small distance go next run
	if playerRepetitiveStuckCurrentCount >= playerRepetitiveStuckMaxCount then
		if manhattanDistance(playerPositionX, playerPositionY, playerRepetitiveStuckPositionX, playerRepetitiveStuckPositionY) <= playerRepetitiveStuckDistance then
			if neuralNetworkType == "Default" then
				nextRun()
			elseif neuralNetworkType == "Q Learning" then
				nextRunQLearning()
			end
		else
			playerRepetitiveStuckPositionX = playerPositionX
			playerRepetitiveStuckPositionY = playerPositionY
			playerRepetitiveStuckCurrentCount = 0
		end
	end

	playerRepetitiveStuckCurrentCount = playerRepetitiveStuckCurrentCount + 1
end

function updatePlayerMovementFitness()
	fitnessPlayerSpeed = fitnessPlayerSpeed + (stuckTime - stuckTimer) * 0.000001

	-- If player moved to a new grid tile, add fitness
	if isPlayerInGridRange() then
		if worldGrid[playerPositionX][playerPositionY] == 0 then
			worldGrid[playerPositionX][playerPositionY] = 1
			fitnessPlayerMoving = fitnessPlayerMoving + 0.0001
		end
	end
end

function updateWorldGrid()
	local gridOffsetX = 0
	local gridOffsetY = 0
	local gridPositionX = 0
	local gridPositionY = 0
	local gridValue = -1

	for i = 0, 3 do
		-- Get grid offset by player rotation
		if playerRotation == 0 then
			gridOffsetX = 0
			gridOffsetY = -1
		elseif playerRotation == 1 then
			gridOffsetX = 0
			gridOffsetY = 1
		elseif playerRotation == 2 then
			gridOffsetX = -1
			gridOffsetY = 0
		elseif playerRotation == 3 then
			gridOffsetX = 1
			gridOffsetY = 0
		end

		gridPositionX = playerPositionX + gridOffsetX
		gridPositionY = playerPositionY + gridOffsetY

		if isInWorldGridRange(gridPositionX, gridPositionY) then
			gridValue = worldGrid[gridPositionX][gridPositionY]

			-- If there already is an NPC, don't change the grid value
			if
				gridValue ~= 3
			then
				-- Wall
				if playerWalkingTowardsTileType == 2 then
					worldGrid[gridPositionX][gridPositionY] = 2

				-- Grass
				elseif playerTileType == 2 then
					worldGrid[playerPositionX][playerPositionY] = 4
				end

				-- NPCs
				if isPlayerInConversation then
					worldGrid[gridPositionX][gridPositionY] = 3
				end
			end
		end
	end
end

function updateRunTimer()
	if not isRunTimerActive then
		return
	end

	runTimer = runTimer + 1

	if runTimer >= runTime then
		if neuralNetworkType == "Default" then
			nextRun()
		elseif neuralNetworkType == "Q Learning" then
			nextRunQLearning()
		end
	end
end

function updateStuckTimer()
	if not isStuckTimerActive then
		return
	end

	stuckTimer = stuckTimer + 1

	if stuckTimer >= stuckTime then
		if neuralNetworkType == "Default" then
			nextRun()
		elseif neuralNetworkType == "Q Learning" then
			nextRunQLearning()
		end
	end
end

function getNeuralNetworkColorFromValue(value)
	local color

	if value <= 0 then
		color = neuralNetworkNegativeColor
	else
		color = neuralNetworkPositiveColor
	end

	return color
end

function getNeuralNetworkColorFromInput(value)
	local color

	if value == unExploredTileInput then
		color = neuralNetworkNegativeColor
	elseif value == wallInput then
		color = wallColor
	elseif value == npcInput then
		color = npcColor
	elseif value == grassInput then
		color = grassColor
	else
		color = neuralNetworkPositiveColor
	end

	return color
end

function getNeuralNetworkInputFromGrid(width, height)
	local input = {}
	local inputIndex = 1

	for i = 1, width do
		for j = 1, height do
			gridIndexX = playerPositionX - math.floor(width / 2) + i - 1
			gridIndexY = playerPositionY - math.floor(height / 2) + j - 1

			if isInWorldGridRange(gridIndexX, gridIndexY) then
				input[inputIndex] = worldGrid[gridIndexX][gridIndexY]
			else
				input[inputIndex] = 2
			end

			inputIndex = inputIndex + 1
		end
	end

	return input
end

function increaseNeuralNetwork(fileName, newNeuralNetworkLayers)
	local neuralNetworkOld = NeuralNetwork:new(neuralNetworkLayers)
	local neuralNetworkNew = NeuralNetwork:new(newNeuralNetworkLayers)

	neuralNetworkOld:load(fileName)

	local lines = {}
	local linesNew = {}
	local index = 1
	local biasesToAdd = arrayLength2D(neuralNetworkNew.biases) - arrayLength2D(neuralNetworkOld.biases)
	local weightsToAdd = arrayLength3D(neuralNetworkNew.weights) - arrayLength3D(neuralNetworkOld.weights)

	for line in io.lines(fileName) do
		lines[#lines + 1] = line
	end

	-- Set best fitness to 0 because the new Neural Network won't beat the old best fitness
	linesNew[index] = 0
	index = index + 1

	for i = 1, #(neuralNetworkOld.biases) do
		for j = 1, #(neuralNetworkOld.biases[i]) do
			linesNew[index] = neuralNetworkOld.biases[i][j]
			index = index + 1
		end
	end

	-- New biases
	for i = 1, biasesToAdd do
		linesNew[index] = 0
		index = index + 1
	end

	for i = 1, #(neuralNetworkOld.weights) do
		for j = 1, #(neuralNetworkOld.weights[i]) do
			for k = 1, #(neuralNetworkOld.weights[i][j]) do
				linesNew[index] = neuralNetworkOld.weights[i][j][k]
				index = index + 1
			end
		end
	end

	-- New weights
	for i = 1, weightsToAdd do
		linesNew[index] = 0
		index = index + 1
	end

	-- Save new values
	local saveFile = io.open(fileName, "w")

	-- Save best Fitness
	saveFile:write(linesNew[1], "\n")

	for i = 2, #(linesNew) do
		saveFile:write(linesNew[i], "\n")
	end

	io.close(saveFile)

	print("Increased Neural Network size from " .. #(lines) .. " to " .. #(linesNew))
end

function sortNeuralNetworks(neuralNetworks)
	local highestFitness = -1
	local bestNeuralNetworkIndex = -1
	local neuralNetworksSorted = {}
	local neuralNetworksUsed = {}

	for i = 1, #(neuralNetworks) do
		neuralNetworksUsed[i] = 0
	end

	for i = 1, #(neuralNetworks) do
		for j = 1, #(neuralNetworks) do
			if neuralNetworksUsed[j] == 0 then
				if neuralNetworks[j] ~= nil then
					if neuralNetworks[j].fitness >= highestFitness or highestFitness == -1 then
						bestNeuralNetworkIndex = j
						highestFitness = neuralNetworks[j].fitness
					end
				end
			end
		end

		neuralNetworksSorted[i] = neuralNetworks[bestNeuralNetworkIndex]

		neuralNetworksUsed[bestNeuralNetworkIndex] = 1
		bestNeuralNetworkIndex = -1
		highestFitness = -1
	end

	return neuralNetworksSorted
end

function nextRun()
	totalRuns = totalRuns + 1

	print("Runs: " .. totalRuns)

	updateFitness(neuralNetworks[neuralNetworkIndex])

	if 
		neuralNetworks[neuralNetworkIndex].fitness > bestFitness
	then
		local savedFitness = 0

		if fileExists(saveFileName) then
			saveFile = io.open(saveFileName)
			savedFitness = tonumber(saveFile:read())
			saveFile:close()
		end

		if neuralNetworks[neuralNetworkIndex].fitness > savedFitness then		-- Make sure to not save if another emulator had a better fitness
			bestFitness = neuralNetworks[neuralNetworkIndex].fitness
			bestRun = totalRuns

			neuralNetworks[neuralNetworkIndex]:save(saveFileName)

			print("New Best Fitness: " .. bestFitness)
		end
	end

	fitnessPlayerMoving = 0
	fitnessPlayerSpeed = 0
	
	playerRepetitiveStuckCurrentCount = 0

	neuralNetworkIndex = neuralNetworkIndex + 1
	stuckTimer = 0
	runTimer = 0
	input = {}
	
	initWorldGrid()
	loadWorldGrid(worldGridSaveFileName)

	-- Only remove places walked from grid, but keep walls etc
	--[[
	for i = 1, #(worldGrid) do
		for j = 1, #(worldGrid[i]) do
			if worldGrid[i][j] == 1 then
				worldGrid[i][j] = 0
			end
		end
	end
	]]--

	if neuralNetworkIndex >= #(neuralNetworks) then
		nextEvolution()
	end

	savestate.loadslot(saveState)
end

function nextRunQLearning()
	totalRuns = totalRuns + 1

	print("Runs: " .. totalRuns)

	--updateFitness(neuralNetworks[neuralNetworkIndex])

	if 
		neuralNetworks[neuralNetworkIndex].fitness > bestFitness
	then
		local savedFitness = 0

		if fileExists(saveFileName) then
			saveFile = io.open(saveFileName)
			savedFitness = tonumber(saveFile:read())
			saveFile:close()
		end

		if neuralNetworks[neuralNetworkIndex].fitness > savedFitness then		-- Make sure to not save if another emulator had a better fitness
			bestFitness = neuralNetworks[neuralNetworkIndex].fitness
			bestRun = totalRuns

			neuralNetworks[neuralNetworkIndex]:save(saveFileName)

			print("New Best Fitness: " .. bestFitness)
		end
	end

	fitnessPlayerMoving = 0
	fitnessPlayerSpeed = 0
	
	playerRepetitiveStuckCurrentCount = 0

	--neuralNetworkIndex = neuralNetworkIndex + 1
	stuckTimer = 0
	runTimer = 0
	input = {}

	for i = 1, #(neuralNetworks) do
		neuralNetworks[i].fitness = 0
	end
	
	initWorldGrid()
	loadWorldGrid(worldGridSaveFileName)

	--[[
	if neuralNetworkIndex >= #(neuralNetworks) then
		nextEvolution()
	end
	--]]

	savestate.loadslot(saveState)
end

function nextEvolution()
	evolution = evolution + 1

	neuralNetworks = sortNeuralNetworks(neuralNetworks)

	print("Evolutions: " .. evolution)
	print("Best Fitness: " .. neuralNetworks[1].fitness)

	neuralNetworks[1]:load(saveFileName)

	mutateWithPercentage(math.random(1, 100))

	for i = goodNeuralNetworkCount + 1, #(neuralNetworks) do
		neuralNetworks[i].fitness = 0
	end

	-- Show replays if replay method is called earlier
	if not replayAfterEvolution then
		neuralNetworkIndex = goodNeuralNetworkCount + 1
	else
		neuralNetworkIndex = 1
		replayAfterEvolution = false
	end
end

function updateFitness(neuralNetwork)
	neuralNetwork.fitness = getCurrentFitness()
end

function addFitness(neuralNetwork)
	neuralNetwork.fitness = neuralNetwork.fitness + getCurrentReward()
end

function getCurrentReward()
	return fitnessPlayerMoving + fitnessPlayerSpeed
end

function mutate()
	for i = goodNeuralNetworkCount + 1, #(neuralNetworks) do
		neuralNetworks[i] = neuralNetworks[math.random(1, goodNeuralNetworkCount)]:copy(neuralNetworks[i])
		neuralNetworks[i]:mutate(mutationChance, math.random(0, mutationStrength))
	end
end

function mutateAll()
	for i = 1, #(neuralNetworks) do
		neuralNetworks[i]:mutate(mutationChance, mutationStrength)
	end
end

function mutateWithAverage()
	for i = goodNeuralNetworkCount + 1, #(neuralNetworks) do
		neuralNetworks[i] = neuralNetworks[math.random(1, goodNeuralNetworkCount)]:copy(neuralNetworks[i])

		if i > goodNeuralNetworkCount + averageNeuralNetworkCount then
			neuralNetworks[i]:mutate(mutationChance, math.random(0, mutationStrength))
		else
			neuralNetworks[i]:copyAverage(neuralNetworks[i - averageNeuralNetworkCount])
		end
	end
end

function mutateWithPercentage(percentage)
	for i = goodNeuralNetworkCount + 1, #(neuralNetworks) do
		neuralNetworks[i] = neuralNetworks[math.random(1, goodNeuralNetworkCount)]:copy(neuralNetworks[i])

		if i > goodNeuralNetworkCount + averageNeuralNetworkCount then
			neuralNetworks[i]:mutate(mutationChance, math.random(0, mutationStrength))
		else
			neuralNetworks[i - averageNeuralNetworkCount]:copyPercentage(neuralNetworks[i], percentage)
		end
	end
end

function onExit()
	gui.clearGraphics()

	client.SetClientExtraPadding(0, 0, 0, 0)
end

function runWorldGridCreator()
	math.randomseed(os.time())

	event.onexit(onExit)

	console.clear()

	client.SetClientExtraPadding(extraBorderWidth, 0, 0, 0)

	memory.usememorydomain("Main RAM")

	savestate.loadslot(saveState)

	gui.use_surface("client")
	gui.clearGraphics()

	readFromMemory()

	initWorldGrid()

	disableRunTimers()

	joypadControl = false

	updatePlayerPreviousPosition()

	worldGridCreatorLoop()
end

function runTraining()
	math.randomseed(os.time())

	event.onexit(onExit)

	console.clear()

	client.SetClientExtraPadding(extraBorderWidth, 0, 0, 0)

	memory.usememorydomain("Main RAM")

	savestate.loadslot(saveState)

	gui.use_surface("client")
	gui.clearGraphics()

	readFromMemory()

	initWorldGrid()
	loadWorldGrid(worldGridSaveFileName)

	enableRunTimers()

	joypadControl = false

	initReplayMemory();

	updatePlayerPreviousPosition()

	initNeuralNetworks()

	trainingLoop()
end

function runQLearningTraining()
	math.randomseed(os.time())

	event.onexit(onExit)

	console.clear()

	client.SetClientExtraPadding(extraBorderWidth, 0, 0, 0)

	memory.usememorydomain("Main RAM")

	savestate.loadslot(saveState)

	gui.use_surface("client")
	gui.clearGraphics()

	readFromMemory()

	initWorldGrid()
	loadWorldGrid(worldGridSaveFileName)

	enableRunTimers()

	joypadControl = false

	initReplayMemory();

	updatePlayerPreviousPosition()

	initNeuralNetworksForQLearning()

	trainingLoopQLearning()
end

function runBackPropagationTest()
	math.randomseed(os.time())

	event.onexit(onExit)

	console.clear()

	client.SetClientExtraPadding(extraBorderWidth, 0, 0, 0)

	gui.use_surface("client")
	gui.clearGraphics()

	initNeuralNetworksForBackPropagationTest()

	trainingLoopBackPropagationTest()
end

function worldGridCreatorLoop()
	while true do
		gui.clearGraphics()

		joypadTable = {}

		-- Change player position
		if worldGridCreatorIndex == 0 then
			savestate.loadslot(saveState)

			memory.write_s32_le(playerPositionXAddressForWrite, worldGridCreatorX)
			memory.write_s32_le(playerPositionYAddressForWrite, worldGridCreatorY)
		elseif worldGridCreatorIndex == 10 * 1 then
			savestate.loadslot(saveState)

			memory.write_s32_le(playerPositionXAddressForWrite, worldGridCreatorX)
			memory.write_s32_le(playerPositionYAddressForWrite, worldGridCreatorY)
		elseif worldGridCreatorIndex == 10 * 2 then
			savestate.loadslot(saveState)

			memory.write_s32_le(playerPositionXAddressForWrite, worldGridCreatorX)
			memory.write_s32_le(playerPositionYAddressForWrite, worldGridCreatorY)
		elseif worldGridCreatorIndex == 10 * 3 then
			savestate.loadslot(saveState)

			memory.write_s32_le(playerPositionXAddressForWrite, worldGridCreatorX)
			memory.write_s32_le(playerPositionYAddressForWrite, worldGridCreatorY)
		end

		-- Directional player movement
		if worldGridCreatorIndex >= 0 and worldGridCreatorIndex <= 7 then
			joypadTable = {
				Left = true
			}
		elseif worldGridCreatorIndex >= 10 * 1 and worldGridCreatorIndex <= 10 * 1 + 7 then
			joypadTable = {
				Up = true
			}
		elseif worldGridCreatorIndex >= 10 * 2 and worldGridCreatorIndex <= 10 * 2 + 7 then
			joypadTable = {
				Right = true
			}
		elseif worldGridCreatorIndex >= 10 * 3 and worldGridCreatorIndex <= 10 * 3 + 7 then
			joypadTable = {
				Down = true
			}
		end

		-- A button press for player interaction with NPCs,
		-- so we can check if there is an NPC in front of the player.
		-- Currently only works for saved direction from save state since the player
		-- takes time to rotate before interaction
		if worldGridCreatorIndex >= 0 and worldGridCreatorIndex <= 7 then
			joypadTable.A = true
		elseif worldGridCreatorIndex >= 10 * 1 and worldGridCreatorIndex <= 10 * 1 + 7 then
			joypadTable.A = true
		elseif worldGridCreatorIndex >= 10 * 2 and worldGridCreatorIndex <= 10 * 2 + 7 then
			joypadTable.A = true
		elseif worldGridCreatorIndex >= 10 * 3 and worldGridCreatorIndex <= 10 * 3 + 7 then
			joypadTable.A = true
		end

		readFromMemory()

		updateWorldGrid()

		input = getNeuralNetworkInputFromGrid(inputScannerWidth, inputScannerHeight)

		setJoypadInput(joypadTable)

		UIDrawer.drawInputScanner(input, 10, 10, 10, 10)

		worldGridCreatorTimer = worldGridCreatorTimer + 1

		if worldGridCreatorIndex >= 10 * 3 + 8 then
			worldGridCreatorIndex = 0

			print("[" .. worldGridCreatorX .. "][" .. worldGridCreatorY .. "]")

			if worldGridCreatorX >= 122 then
				if worldGridCreatorY < 892 then
					worldGridCreatorY = worldGridCreatorY + 1
					worldGridCreatorX = 100
				else
					saveWorldGrid(worldGridSaveFileName)
					break;
				end
			else
				worldGridCreatorX = worldGridCreatorX + 1
			end
		else
			worldGridCreatorIndex = worldGridCreatorIndex + 1
		end

		emu.frameadvance()
	end
end

function trainingLoop()
	while true do
		initTrainingLoop()

		trainingLoopPlayerMoved()

		--updateWorldGrid()

		input = getNeuralNetworkInputFromGrid(inputScannerWidth, inputScannerHeight)

		output = neuralNetworks[neuralNetworkIndex]:feedForward(input)

		joypadTable = getJoypadTableFromOutput(output)

		setJoypadInput(joypadTable)

		updateRunTimer()

		updateStuckTimer()

		--UIDrawer.drawTrainingUI()

		emu.frameadvance()

		updatePlayerPreviousPosition()
	end
end

function trainingLoopQLearning()
	local test = 0
	while true do
		initTrainingLoop()

		trainingLoopPlayerMoved()

		--updateWorldGrid()

		local previousInput = input
		local previousOutput = output
		local reward = getCurrentReward()

		addFitness(neuralNetworks[neuralNetworkIndex])

		fitnessPlayerMoving = 0
		fitnessPlayerSpeed = 0

		input = getNeuralNetworkInputFromGrid(inputScannerWidth, inputScannerHeight)

		if runTimer > 0 then
			if reward > 0 then
				replayMemory:addReplay(previousInput, previousOutput, reward, input)

				local replays = replayMemory:getBatch(6)
				local totalErrors = {0, 0, 0, 0, 0}

				for i = 1, #(replays) do
					local outputPolicy = neuralNetworks[neuralNetworkIndex]:feedForward(replays[i]["State"])
					local outputTarget = neuralNetworks[neuralNetworkIndex + 1]:feedForward(replays[i]["Next State"])

					local outputErrors = {}

					for errorIndex = 1, #(outputPolicy) do
						outputErrors[errorIndex] = replays[i]["Reward"] + outputTarget[errorIndex] - outputPolicy[errorIndex]

						totalErrors[errorIndex] = totalErrors[errorIndex] + outputErrors[errorIndex]
					end
				end

				neuralNetworks[neuralNetworkIndex]:backPropagate(totalErrors, 10)
			end
		end

		if not isInputEqual(input, previousInput) then
			if math.random(0, 100) >= test then
				output = getRandomOutput()

				print("Random output")
			else
				output = neuralNetworks[neuralNetworkIndex]:feedForward(input)

				print("Policy output")
			end
		end

		test = test + 0.1

		if test >= 100 then
			print("Updating target network")

			neuralNetworks[neuralNetworkIndex]:copy(neuralNetworks[neuralNetworkIndex + 1])
			test = 0
		end
		

		if not isInputEqual(input, previousInput) then
			joypadTable = getJoypadTableFromOutput(output)
		end

		setJoypadInput(joypadTable)

		updateRunTimer()

		updateStuckTimer()

		UIDrawer.drawTrainingUI()

		emu.frameadvance()

		updatePlayerPreviousPosition()
	end
end

function trainingLoopBackPropagationTest()
	while true do
		gui.clearGraphics()

		input = {0}

		local outputTarget = {-0.1}
		local errors = {}
		local totalError = 0

		output = neuralNetworks[neuralNetworkIndex]:feedForward(input)

		--neuralNetworks[neuralNetworkIndex]:printWeights()
		
		----[[
		print(
			"Current output: [" ..
			tonumber(string.format("%.9f", output[1])) ..
			"]"
		)
		----]]

		--neuralNetworks[neuralNetworkIndex]:printBiases()

		--[[
		print(
			"Current output: [" ..
			tonumber(string.format("%.1f", output[1])) ..
			"] [" ..
			tonumber(string.format("%.1f", output[2])) ..
			"] [" ..
			tonumber(string.format("%.1f", output[3])) ..
			"]"
		)
		--]]
		--print("Target output: " .. outputTest)

		for i = 1, #(outputTarget) do
			errors[i] = (output[i] - outputTarget[i])^2
			totalError = totalError + errors[i]
		end

		print("Total error: " .. string.format("%.10f", totalError))

		neuralNetworks[neuralNetworkIndex]:backPropagate(outputTarget, 0.1)

		UIDrawer.drawCurrentNeuralNetwork()

		emu.frameadvance()
	end
end

function UIDrawer.drawTrainingUI()
	UIDrawer.drawTrainingText(trainingTextPositionX, trainingTextPositionY, trainingTextOffsetY)

	--UIDrawer.drawReplayText(neuralNetworkIndex)

	UIDrawer.drawCurrentNeuralNetwork()

	UIDrawer.drawInputScanner(input)
end

function UIDrawer.drawTrainingText(positionX, positionY, offsetY)
	gui.text(positionX, positionY + offsetY * 0, "Best Fitness: " .. bestFitness)
	gui.text(positionX, positionY + offsetY * 1, "Best Run: " .. bestRun)
	gui.text(positionX, positionY + offsetY * 3, "Current Run: " .. totalRuns + 1)
	gui.text(positionX, positionY + offsetY * 4, "Current Evolution: " .. evolution)
end

function UIDrawer.drawReplayText(neuralNetworkIndex)
	local replayText = string.format(replayFormat, neuralNetworkIndex)

	if neuralNetworkIndex <= goodNeuralNetworkCount and runTimer <= replayTime then
		gui.drawText(gameCenterX(), gameCenterY(), replayText, nil, nil, (client.screenwidth() + 250 - client.borderwidth() * 2) / 8, nil, "bold", "center", "center")
	end
end

function UIDrawer.drawNeuralNetwork(neuralNetwork, positionX, positionY)
	positionX = positionX or 5
	positionY = positionY or 125

	local color, offsetX, offsetY

	for i = 1, #(neuralNetwork.neurons) do
		for j = 1, #(neuralNetwork.neurons[i]) do
			offsetX = (client.borderwidth() + extraBorderWidth) / #(neuralNetwork.neurons) / 2.1
			offsetY = (client.screenheight() - 150) / #(neuralNetworks[neuralNetworkIndex].neurons[i])

			local neuronValue = neuralNetworks[neuralNetworkIndex].neurons[i][j]

			if
				(neuronValue == exploredTileInput and i == 1) or
				(neuronValue > 0 and i ~= 1)
			then
				color = getNeuralNetworkColorFromValue(neuronValue)
			elseif neuronValue == wallInput and i == 1 then
				color = getNeuralNetworkColorFromInput(wallInput)
			else
				color = getNeuralNetworkColorFromValue(neuronValue)
			end

			gui.drawRectangle(positionX + offsetX * (i - 1), positionY + offsetY * (j - 1), 10, 1, color, color)
		end
	end
end

function UIDrawer.drawCurrentNeuralNetwork()
	UIDrawer.drawNeuralNetwork(neuralNetworks[neuralNetworkIndex])
end

function UIDrawer.drawInputScanner(input, positionX, positionY, tileWidth, tileHeight, outlineColor)
	positionX = positionX or 240
	positionY = positionY or 5
	tileWidth = tileWidth or 9
	tileHeight = tileHeight or 9

	local inputScannerStrings = {}
	local inputScannerIndex = 1
	local color

	for i = 1, inputScannerWidth do
		for j = 1, inputScannerHeight do
			color = getNeuralNetworkColorFromInput(input[inputScannerIndex])

			outlineColorFinal = outlineColor or color

			gui.drawRectangle(
				positionX + tileWidth * (i - 1),
				positionY + tileHeight * (j - 1),
				tileWidth, tileHeight, outlineColorFinal, color
			)

			inputScannerIndex = inputScannerIndex + 1
		end
	end
end

function NeuralNetwork:new(layers)
	local this = {}
	setmetatable(this, self)
	self.__index = self

	this.layers = layers
	this.neurons = {}
	this.neuronsWithoutActivation = {}
	this.biases = {}
	this.weights = {}
	this.fitness = 0

	this:initNeurons()
	this:initBiases()
	this:initWeights()

	return this
end

function NeuralNetwork:activate(value)
	return math.tanh(value)
end

function NeuralNetwork:activateDerivative(value)
	return 1 - (self:activate(value)^2)
end

function NeuralNetwork:activateRelu(value)
	return math.max(value, 0)
end

function NeuralNetwork:feedForward(inputs)
	-- Update inputs
	for inputIndex = 1, #(inputs) do
		self.neurons[1][inputIndex] = inputs[inputIndex]
	end

	-- Update neurons based on weights, biases and activation
	for layerIndex = 2, #(self.layers) do
		for neuronIndex = 1, #(self.neurons[layerIndex]) do
			local value = 0

			for weightIndex = 1, #(self.neurons[layerIndex - 1]) do
				value = value + self.weights[layerIndex - 1][neuronIndex][weightIndex] * self.neurons[layerIndex - 1][weightIndex]
			end

			self.neurons[layerIndex][neuronIndex] = self:activate(
				value + self.biases[layerIndex][neuronIndex]
			)

			self.neuronsWithoutActivation[layerIndex][neuronIndex] = value + self.biases[layerIndex][neuronIndex]
		end
	end

	return self.neurons[#(self.neurons)]
end

function NeuralNetwork:backPropagate(targetOutputs, learningRate)
	self:updateBackPropagateWeightsAndBiases(targetOutputs, learningRate)
end

function NeuralNetwork:updateBackPropagateWeightsAndBiases(targetOutputs, learningRate)
	for outputIndex = 1, #(self.neurons[#(self.layers)]) do
		local layer = #(self.layers)
		local targetOutput = targetOutputs[outputIndex]

		for layerIndex = 1, #(self.layers) - 1 do
			for neuronIndex = 1, #(self.neurons[layer]) do
				for weightIndex = 1, #(self.weights[layer - 1][neuronIndex]) do
					self:updateBackPropagateWeight(learningRate, layer, neuronIndex, weightIndex, targetOutput)
				end

				self:updateBackPropagateBias(learningRate, layer, neuronIndex, targetOutput)
			end

			layer = layer - 1
		end
	end
end

function NeuralNetwork:updateBackPropagateWeight(learningRate, layer, neuronIndex, weightIndex, targetOutput)
	local weight = self.weights[layer - 1][neuronIndex][weightIndex]

	local newWeight = self:calculateBackPropagateWeight(
		weight, learningRate, layer, neuronIndex, targetOutput
	)

	self.weights[layer - 1][neuronIndex][weightIndex] = newWeight
end

function NeuralNetwork:updateBackPropagateBias(learningRate, layer, neuronIndex, targetOutput)
	local bias = self.biases[layer][neuronIndex]

	local newBias = self:calculateBackPropagateBias(
		bias, learningRate, layer, neuronIndex, targetOutput
	)

	self.biases[layer][neuronIndex] = newBias
end

function NeuralNetwork:calculateBackPropagateWeight(weight, learningRate, layer, neuronIndex, targetOutput)
	return weight - learningRate * self:calculateBackPropagateWeightRatio(layer, neuronIndex, targetOutput)
end

function NeuralNetwork:calculateBackPropagateBias(bias, learningRate, layer, neuronIndex, targetOutput)
	return bias - learningRate * self:calculateBackPropagateBiasRatio(bias, layer, neuronIndex, targetOutput)
end

function NeuralNetwork:calculateBackPropagateWeightRatio(layer, neuronIndex, targetOutput)
	return (
		self:calculateBackPropagateChainA(layer, neuronIndex, targetOutput) *
		self:calculateBackPropagateChainB(layer, neuronIndex) *
		self:calculateBackPropagateChainCWeight(layer, neuronIndex)
	)
end

function NeuralNetwork:calculateBackPropagateBiasRatio(bias, layer, neuronIndex, targetOutput)
	return (
		self:calculateBackPropagateChainA(layer, neuronIndex, targetOutput) *
		self:calculateBackPropagateChainB(layer, neuronIndex) *
		self:calculateBackPropagateChainCBias(bias)
	)
end

function NeuralNetwork:calculateBackPropagateChainA(layer, neuronIndex, targetOutput)
	return 2 * (self.neurons[layer][neuronIndex] - targetOutput)
end

function NeuralNetwork:calculateBackPropagateChainB(layer, neuronIndex)
	return self:activateDerivative(self.neuronsWithoutActivation[layer][neuronIndex])
end

function NeuralNetwork:calculateBackPropagateChainCWeight(layer, neuronIndex)
	return self.neurons[layer - 1][neuronIndex]
end

function NeuralNetwork:calculateBackPropagateChainCBias(bias)
	return 1
end

function NeuralNetwork:mutate(chance, value)
	for i = 1, #(self.neurons) do
		for j = 1, #(self.neurons[i]) do
			self.neurons[i][j] = 0
		end
	end

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			if math.random(1, 100) <= chance then
				self.biases[i][j] = self.biases[i][j] + math.random(-value, value) / 100
				self.biases[i][j] = clamp(self.biases[i][j], -1, 1)
			end
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				if math.random(1, 100) <= chance then
					self.weights[i][j][k] = self.weights[i][j][k] + math.random(-value, value) / 100
					self.weights[i][j][k] = clamp(self.weights[i][j][k], -1, 1)
				end
			end
		end
	end
end

function NeuralNetwork:copy(neuralNetwork)
	for i = 1, #(self.neurons) do
		for j = 1, #(self.neurons[i]) do
			neuralNetwork.neurons[i][j] = 0
		end
	end

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			neuralNetwork.biases[i][j] = self.biases[i][j]
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				neuralNetwork.weights[i][j][k] = self.weights[i][j][k]
			end
		end
	end

	return neuralNetwork
end

function NeuralNetwork:copyAverage(neuralNetwork)
	for i = 1, #(self.neurons) do
		for j = 1, #(self.neurons[i]) do
			neuralNetwork.neurons[i][j] = 0
		end
	end

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			neuralNetwork.biases[i][j] = (self.biases[i][j] + neuralNetwork.biases[i][j]) / 2
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				neuralNetwork.weights[i][j][k] = (self.weights[i][j][k] + neuralNetwork.weights[i][j][k]) / 2
			end
		end
	end

	return neuralNetwork
end

function NeuralNetwork:copyPercentage(neuralNetwork, percentage)
	for i = 1, #(self.neurons) do
		for j = 1, #(self.neurons[i]) do
			neuralNetwork.neurons[i][j] = 0
		end
	end

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			neuralNetwork.biases[i][j] = (self.biases[i][j] + neuralNetwork.biases[i][j]) / 100 * percentage
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				neuralNetwork.weights[i][j][k] = (self.weights[i][j][k] + neuralNetwork.weights[i][j][k]) / 100 * percentage
			end
		end
	end

	return neuralNetwork
end

function NeuralNetwork:save(fileName)
	local saveFile = io.open(fileName, "w")

	saveFile:write(bestFitness, "\n")

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			saveFile:write(self.biases[i][j], "\n")
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				saveFile:write(self.weights[i][j][k], "\n")
			end
		end
	end

	io.close(saveFile)
end

function NeuralNetwork:load(fileName)
	local lines = {}
	local index = 1

	for line in io.lines(fileName) do 
		lines[#lines + 1] = line
	end

	bestFitness = tonumber(lines[index])
	index = index + 1

	self:initNeurons()

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			self.biases[i][j] = tonumber(lines[index])
			index = index + 1
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				self.weights[i][j][k] = tonumber(lines[index])
				index = index + 1
			end
		end
	end
end

function NeuralNetwork:isEqual(neuralNetwork)
	local equal = true

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			if self.biases[i][j] ~= neuralNetwork.biases[i][j] then
				equal = false
			end
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				if self.weights[i][j][k] ~= neuralNetwork.weights[i][j][k] then
					equal = false
				end
			end
		end
	end

	return equal
end

function NeuralNetwork:initNeurons()
	for i = 1, #(self.layers) do
		self.neurons[i] = {}
		self.neuronsWithoutActivation[i] = {}

		for j = 1, self.layers[i] do
			self.neurons[i][j] = 0
			self.neuronsWithoutActivation[i][j] = 0
		end
	end
end

function NeuralNetwork:initBiases()
	for i = 1, #(self.layers) do
		self.biases[i] = {}

		for j = 1, self.layers[i] do
			self.biases[i][j] = 0
		end
	end
end

function NeuralNetwork:initWeights()
	for i = 2, #(self.layers) do
		self.weights[i - 1] = {}
		local neuronsInPreviousLayer = self.layers[i - 1]

		for j = 1, #(self.neurons[i]) do
			self.weights[i - 1][j] = {}

			for k = 1, neuronsInPreviousLayer do
				self.weights[i - 1][j][k] = 0
			end
		end
	end
end

function NeuralNetwork:printStats()
	for i = 1, #(self.neurons) do
		for j = 1, #(self.neurons[i]) do
			print("[neuron]" .. "[" .. i .. "][" .. j .. "] "  .. self.neurons[i][j])
		end
	end

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			print("[bias]" .. "[" .. i .. "][" .. j .. "] "  .. self.biases[i][j])
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				print("[weight]" .. "[" .. i .. "][" .. j .. "][" .. k .. "] "  .. self.weights[i][j][k])
			end
		end
	end
end

function NeuralNetwork:printInputs()
	for i = 1, #(self.neurons[1]) do
		print("[input neuron]" .. "[" .. i .. "] "  .. self.neurons[1][i])
	end
end

function NeuralNetwork:printNeurons()
	for i = 1, #(self.neurons) do
		for j = 1, #(self.neurons[i]) do
			print("[neuron]" .. "[" .. i .. "][" .. j .. "] "  .. self.neurons[i][j])
		end
	end
end

function NeuralNetwork:printBiases()
	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			print("[bias]" .. "[" .. i .. "][" .. j .. "] "  .. self.biases[i][j])
		end
	end
end

function NeuralNetwork:printWeights()
	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				print("[weight]" .. "[" .. i .. "][" .. j .. "][" .. k .. "] "  .. self.weights[i][j][k])
			end
		end
	end
end

function ReplayMemory:new(maxSize)
	local this = {}
	setmetatable(this, self)
	self.__index = self

	this.maxSize = maxSize
	this.size = 0
	this.replays = {}

	return this
end

function ReplayMemory:addReplay(state, actions, reward, nextState)
	if self.size >= self.maxSize then
		return
	end

	self.size = self.size + 1

	self.replays[self.size] = {}

	self.replays[self.size]["State"] = state
	self.replays[self.size]["Actions"] = actions
	self.replays[self.size]["Reward"] = reward
	self.replays[self.size]["Next State"] = nextState
end

function ReplayMemory:getBatch(size)
	size = math.max(self.size)
	
	local replays = {}

	for i = 1, size do
		replays[i] = self.replays[math.random(1, self.size)]
	end

	return replays
end

-- START PROGRAM
--runTraining()

--runQLearningTraining()

runBackPropagationTest()

--increaseNeuralNetwork(saveFileName, {inputScannerWidth * inputScannerHeight, 100, 100, 5})

--runWorldGridCreator()