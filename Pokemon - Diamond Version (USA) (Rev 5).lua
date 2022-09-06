NeuralNetwork = {}

input = {}
inputScannerBorderString = "---------------------"
inputScannerWidth = 11
inputScannerHeight = 11

neuralNetworks = {}
neuralNetworkLayers = {inputScannerWidth * inputScannerHeight, 60, 60, 5}
neuralNetworkIndex = 1
neuralNetworkCount = 20
goodNeuralNetworkCount = 5
averageNeuralNetworkCount = 5
neuralNetworkNegativeColor = "Red"
neuralNetworkPositiveColor = "Green"

bestRun = -1
totalRuns = 0
runTime = 1000
runTimer = 0
evolution = 0

mutationChance = 30
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

worldGrid = {}
worldGridCreatorTimer = 0
worldGridCreatorX = 640
worldGridCreatorY = 340
worldGridCreatorIndex = 0
wallColor = "White"
unExploredTileInput = 0
exploredTileInput = 1
wallInput = 2

stuckTime = 80
isRunTimerActive = true
stuckTimer = 0
isStuckTimerActive = true

bestFitness = 0
fitnessPlayerMoving = 0
fitnessMoveInput = 0

saveState = 5

saveFileName = "Best Neural Network.txt"

trainingLoop = false

replayAfterEvolution = false
replayTime = 150
replayFormat = "Replay #%s"

extraBorderWidth = 360

trainingTextPositionX = 5
trainingTextPositionY = 5
trainingTextOffsetY = 20

--print(joypad.getimmediate())

function drawTrainingUI()
	drawTrainingText(trainingTextPositionX, trainingTextPositionY, trainingTextOffsetY)

	drawReplayText(neuralNetworkIndex)

	drawCurrentNeuralNetwork()

	drawInputScanner(input)
end

function drawTrainingText(positionX, positionY, offsetY)
	gui.text(positionX, positionY + offsetY * 0, "Best Fitness: " .. bestFitness)
	gui.text(positionX, positionY + offsetY * 1, "Best Run: " .. bestRun)
	gui.text(positionX, positionY + offsetY * 3, "Current Run: " .. totalRuns + 1)
	gui.text(positionX, positionY + offsetY * 4, "Current Evolution: " .. evolution)
end

function drawReplayText(neuralNetworkIndex)
	local replayText = string.format(replayFormat, neuralNetworkIndex)

	if neuralNetworkIndex <= goodNeuralNetworkCount and runTimer <= replayTime then
		gui.drawText(gameCenterX(), gameCenterY(), replayText, nil, nil, (client.screenwidth() + 250 - client.borderwidth() * 2) / 8, nil, "bold", "center", "center")
	end
end

function drawNeuralNetwork(neuralNetwork, positionX, positionY)
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

function drawCurrentNeuralNetwork()
	drawNeuralNetwork(neuralNetworks[neuralNetworkIndex])
end

function drawInputScanner(input, positionX, positionY, tileWidth, tileHeight, outlineColor)
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
	length = 0

	for i = 1, #(array) do
		length = length + #array[i]
	end
	
	return length
end

function arrayLength3D(array)
	length = 0

	for i = 1, #(array) do
		for j = 1, #(array[i]) do
			length = length + #array[i][j]
		end
	end
	
	return length
end

function fileExists(fileName)
	saveFile = io.open(fileName, "r")

	if saveFile then saveFile:close() end

	return saveFile ~= nil
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
end

function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function boolToNumber(value)
	return value and 1 or 0
end

function numberToBool(value)
	return value and true or false
end

function playerMovedOneStep()
	return playerPositionX ~= previousPlayerPositionX or playerPositionY ~= previousPlayerPositionY
end

function initworldGrid()
	for i = 1, playerPositionX * 5 + 1 do
		worldGrid[i] = {}

		for j = 1, playerPositionY * 5 + 1 do
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
		previousPlayerPositionX = playerPositionX
		previousPlayerPositionY = playerPositionY

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

function updatePlayerRepetitiveStuck()
	if not isPlayerRepetitiveStuckActive then
		return
	end

	-- If player stays within a small distance go next run
	if playerRepetitiveStuckCurrentCount >= playerRepetitiveStuckMaxCount then
		if manhattanDistance(playerPositionX, playerPositionY, playerRepetitiveStuckPositionX, playerRepetitiveStuckPositionY) <= playerRepetitiveStuckDistance then
			nextRun()
		else
			playerRepetitiveStuckPositionX = playerPositionX
			playerRepetitiveStuckPositionY = playerPositionY
			playerRepetitiveStuckCurrentCount = 0
		end
	end

	playerRepetitiveStuckCurrentCount = playerRepetitiveStuckCurrentCount + 1
end

function updatePlayerMovementFitness()
	fitnessSpeed = (stuckTime - stuckTimer) * 0.00001

	-- If player moved to a new grid tile, add fitness
	if isPlayerInGridRange() then
		if worldGrid[playerPositionX][playerPositionY] == 0 then
			worldGrid[playerPositionX][playerPositionY] = 1
			fitnessPlayerMoving = fitnessPlayerMoving + 0.0001 + fitnessSpeed
		end
	end
end

function updateWorldGrid()
	-- Remove wall from grid if player hits a wall
	if playerWalkingTowardsTileType == 2 then
		if playerRotation == 0 then
			if isInWorldGridRange(playerPositionX, playerPositionY - 1) then
				worldGrid[playerPositionX][playerPositionY - 1] = 2
			end
		elseif playerRotation == 1 then
			if isInWorldGridRange(playerPositionX, playerPositionY + 1) then
				worldGrid[playerPositionX][playerPositionY + 1] = 2
			end
		elseif playerRotation == 2 then
			if isInWorldGridRange(playerPositionX - 1, playerPositionY) then
				worldGrid[playerPositionX - 1][playerPositionY] = 2
			end
		elseif playerRotation == 3 then
			if isInWorldGridRange(playerPositionX + 1, playerPositionY) then
				worldGrid[playerPositionX + 1][playerPositionY] = 2
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
		nextRun()
	end
end

function updateStuckTimer()
	if not isStuckTimerActive then
		return
	end

	stuckTimer = stuckTimer + 1

	if stuckTimer >= stuckTime then
		nextRun()
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
	else
		color = neuralNetworkPositiveColor
	end

	return color
end

function getNeuralNetworkInputFromGrid(width, height)
	input = {}
	inputIndex = 1

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
	neuralNetworkOld = NeuralNetwork:new(neuralNetworkLayers)
	neuralNetworkNew = NeuralNetwork:new(newNeuralNetworkLayers)

	neuralNetworkOld:load(fileName)

	lines = {}
	linesNew = {}
	index = 1
	biasesToAdd = arrayLength2D(neuralNetworkNew.biases) - arrayLength2D(neuralNetworkOld.biases)
	weightsToAdd = arrayLength3D(neuralNetworkNew.weights) - arrayLength3D(neuralNetworkOld.weights)

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
	saveFile = io.open(fileName, "w")

	-- Save best Fitness
	saveFile:write(linesNew[1], "\n")

	for i = 2, #(linesNew) do
		saveFile:write(linesNew[i], "\n")
	end

	io.close(saveFile)

	print("Increased Neural Network size from " .. #(lines) .. " to " .. #(linesNew))
end

function sortNeuralNetworks(neuralNetworks)
	highestFitness = -1
	bestNeuralNetworkIndex = -1
	neuralNetworksSorted = {}
	neuralNetworksUsed = {}

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
		savedFitness = 0

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
	fitnessPlayerExploration = 0
	fitnessMoveInput = 0
	
	playerRepetitiveStuckCurrentCount = 0

	neuralNetworkIndex = neuralNetworkIndex + 1
	stuckTimer = 0
	runTimer = 0
	input = {}
	
	initworldGrid()

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

function nextEvolution()
	evolution = evolution + 1

	neuralNetworks = sortNeuralNetworks(neuralNetworks)

	print("Evolutions: " .. evolution)
	print("Best Fitness: " .. neuralNetworks[1].fitness)

	neuralNetworks[1]:load(saveFileName)

	bestFitness = neuralNetworks[1].fitness

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
	neuralNetwork.fitness = fitnessPlayerMoving + fitnessMoveInput
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

	initworldGrid()

	disableRunTimers()

	joypadControl = false

	previousPlayerPositionX = playerPositionX
	previousPlayerPositionY = playerPositionY

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

	initworldGrid()

	enableRunTimers()

	previousPlayerPositionX = playerPositionX
	previousPlayerPositionY = playerPositionY

	initNeuralNetworks()

	trainingLoop()
end

function worldGridCreatorLoop()
	while true do
		gui.clearGraphics()

		joypadTable = {}

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

		readFromMemory()

		updateWorldGrid()

		input = getNeuralNetworkInputFromGrid(inputScannerWidth, inputScannerHeight)

		if not joypadControl then
			joypad.set(joypadTable)
		end

		drawInputScanner(input)

		worldGridCreatorTimer = worldGridCreatorTimer + 1

		if worldGridCreatorIndex >= 10 * 3 + 7 then
			worldGridCreatorIndex = 0

			print("[" .. worldGridCreatorX .. "][" .. worldGridCreatorY .. "]")

			if worldGridCreatorX >= 660 then
				worldGridCreatorY = worldGridCreatorY + 1
				worldGridCreatorX = 640
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

		updateWorldGrid()

		input = getNeuralNetworkInputFromGrid(inputScannerWidth, inputScannerHeight)

		output = neuralNetworks[neuralNetworkIndex]:feedForward(input)

		joypadTable = {
			Right = output[1] > 0,
			Left = output[2] > 0,
			Up = output[3] > 0,
			Down = output[4] > 0,
			B = output[5] > 0
		}

		if not joypadControl then
			joypad.set(joypadTable)
		end

		updateRunTimer()

		updateStuckTimer()

		drawTrainingUI()

		emu.frameadvance()

		previousPlayerPositionX = playerPositionX
		previousPlayerPositionY = playerPositionY
	end
end

function NeuralNetwork:new(layers)
	this = {}
	setmetatable(this, self)
	self.__index = self

	this.layers = layers
	this.neurons = {}
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

function NeuralNetwork:activateRelu(value)
	return math.max(value, 0)
end

function NeuralNetwork:feedForward(inputs)
	for i = 1, #(inputs) do
		self.neurons[1][i] = inputs[i]
	end

	for i = 2, #(self.layers) do
		for j = 1, #(self.neurons[i]) do
			value = 0

			for k = 1, #(self.neurons[i - 1]) do
				value = value + self.weights[i - 1][j][k] * self.neurons[i - 1][k]
			end

			self.neurons[i][j] = this:activate(value + self.biases[i][j])

			--[[
			if j >= #(self.neurons[i]) then
				self.neurons[i][j] = this:activate(value)
			else
				self.neurons[i][j] = value + self.biases[i][j]
			end
			]]--
		end
	end

	return self.neurons[#(self.neurons)]
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
	saveFile = io.open(fileName, "w")

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
	lines = {}
	index = 1

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
	equal = true

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

		for j = 1, self.layers[i] do
			self.neurons[i][j] = 0
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
		neuronsInPreviousLayer = self.layers[i - 1]

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

-- START PROGRAM
--runTraining()

--increaseNeuralNetwork(saveFileName)

runWorldGridCreator()