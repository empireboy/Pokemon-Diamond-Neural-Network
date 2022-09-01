NeuralNetwork = {}

neuralNetworks = {}
neuralNetworkIndex = 1
neuralNetworkCount = 20
goodNeuralNetworkCount = 5
averageNeuralNetworkCount = 5

bestRun = -1
totalRuns = 0
runTime = 1000
runTimer = 0
evolution = 0

mutationChance = 1
mutationStrength = 10

joypadTable = {}
isWalkingRight = true

playerPositionX = 0
playerPositionY = 0
previousPlayerPositionX = 0
previousPlayerPositionY = 0
playerRotation = 0
playerWalkingTowardsTileType = 0
playerTileType = 0
playerMoveGrid = {}
playerStuckPositionX = 0
playerStuckPositionY = 0
playerStuckDistance = 3
playerStuckCurrentCount = 0
playerStuckMaxCount = 10

stuckTime = 40
stuckTimer = 0

bestFitness = 0
fitnessPlayerMoving = 0
fitnessPlayerExploration = 0
fitnessMoveInput = 0

saveState = 5

saveFileName = "Best Neural Network.txt"

input = {}
inputScannerString = ""
inputScannerBorderString = "---------------------"
inputScannerIndex = 1

programLoop = false

replayAfterEvolution = false

--print(joypad.getimmediate())

function drawInputScanner(input)
	inputScannerString = ""
	inputScannerIndex = 1

	for i = 1, 10 do
		for j = 1, 10 do
			inputScannerString = inputScannerString .. tostring(input[inputScannerIndex])

			inputScannerIndex = inputScannerIndex + 1
		end

		print(inputScannerString)
		inputScannerString = ""
	end

	print(inputScannerBorderString)
end

function drawCurrentNeuralNetwork()
	for i = 1, #(neuralNetworks[neuralNetworkIndex].neurons) do
		for j = 1, #(neuralNetworks[neuralNetworkIndex].neurons[i]) do
			color = "Red"
			positionX = 5
			positionY = 125
			offsetX = client.borderwidth() / 4
			offsetY = (client.screenheight() - 150) / #(neuralNetworks[neuralNetworkIndex].neurons[i])

			if
				(neuralNetworks[neuralNetworkIndex].neurons[i][j] == 1 and i == 1) or
				(neuralNetworks[neuralNetworkIndex].neurons[i][j] > 0 and i ~= 1)
			then
				color = "Green"		-- Active color
			elseif neuralNetworks[neuralNetworkIndex].neurons[i][j] == 2 and i == 1 then
				color = "White"		-- Wall color
			end

			gui.drawRectangle(positionX + offsetX * (i - 1), positionY + offsetY * (j - 1), 10, 1, color, color)
		end
	end
end

function ManhattanDistance(x1, y1, x2, y2)
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

function inGridRange(x, y, width, height)
	if 
		x >= 0 and
		x <= width and
		y >= 0 and
		y <= height
	then
		return true
	end

	return false
end

function inPlayerGridRange(x, y)
	return inGridRange(x, y, #(playerMoveGrid), #(playerMoveGrid[1]))
end

function readFromMemory()
	playerPositionX = memory.read_s32_le(0x291D3C)
	playerPositionY = memory.read_s32_le(0x291D44)
	playerRotation = memory.read_s32_le(0x291D14)
	playerWalkingTowardsTileType = memory.read_s32_le(0x291D84)
	playerTileType = memory.read_s16_le(0x291D92)
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

function initPlayerMoveGrid()
	for i = 1, playerPositionX * 2 + 1 do
		playerMoveGrid[i] = {}

		for j = 1, playerPositionY * 2 + 1 do
			playerMoveGrid[i][j] = 0
		end
	end
end

function replay()
	replayAfterEvolution = true

	print("Replay will show after next evolution")
end

function getNeuralNetworkInputFromGrid(width, height)
	input = {}
	inputIndex = 1

	for i = 1, width do
		for j = 1, height do
			gridIndexX = playerPositionX - math.floor(width / 2) + i
			gridIndexY = playerPositionY - math.floor(height / 2) + j

			if 
				gridIndexX >= 0 and
				gridIndexX <= #(playerMoveGrid) and
				gridIndexY >= 0 and
				gridIndexY <= #(playerMoveGrid[1])
			then
				input[inputIndex] = playerMoveGrid[gridIndexX][gridIndexY]
			else
				input[inputIndex] = 1
			end

			inputIndex = inputIndex + 1
		end
	end

	return input
end

function increaseNeuralNetwork(fileName)
	neuralNetworkTempOld = NeuralNetwork:new({10*10, 60, 60, 5})
	neuralNetworkTempNew = NeuralNetwork:new({10*10, 60, 60, 60, 5})

	neuralNetworkTempOld:load(fileName)

	lines = {}
	linesNew = {}
	index = 1
	biasesToAdd = arrayLength2D(neuralNetworkTempNew.biases) - arrayLength2D(neuralNetworkTempOld.biases)
	weightsToAdd = arrayLength3D(neuralNetworkTempNew.weights) - arrayLength3D(neuralNetworkTempOld.weights)

	for line in io.lines(fileName) do
		lines[#lines + 1] = line
	end

	-- Set best fitness to 0 because the new Neural Network won't beat the old best fitness
	linesNew[index] = 0
	index = index + 1

	for i = 1, #(neuralNetworkTempOld.biases) do
		for j = 1, #(neuralNetworkTempOld.biases[i]) do
			linesNew[index] = neuralNetworkTempOld.biases[i][j]
			index = index + 1
		end
	end

	-- New biases
	for i = 1, biasesToAdd do
		linesNew[index] = 0
		index = index + 1
	end

	for i = 1, #(neuralNetworkTempOld.weights) do
		for j = 1, #(neuralNetworkTempOld.weights[i]) do
			for k = 1, #(neuralNetworkTempOld.weights[i][j]) do
				linesNew[index] = neuralNetworkTempOld.weights[i][j][k]
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
	
	playerStuckCurrentCount = 0

	neuralNetworkIndex = neuralNetworkIndex + 1
	stuckTimer = 0
	runTimer = 0
	input = {}
	
	initPlayerMoveGrid()

	-- Only remove places walked from grid, but keep walls etc
	--[[
	for i = 1, #(playerMoveGrid) do
		for j = 1, #(playerMoveGrid[i]) do
			if playerMoveGrid[i][j] == 1 then
				playerMoveGrid[i][j] = 0
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
	neuralNetwork.fitness = fitnessPlayerMoving + fitnessMoveInput + fitnessPlayerExploration
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

function initializeProgram()
	math.randomseed(os.time())

	console.clear()

	memory.usememorydomain("Main RAM")

	savestate.loadslot(saveState)

	gui.use_surface("client")
	gui.clearGraphics()

	readFromMemory()

	initPlayerMoveGrid()

	previousPlayerPositionX = playerPositionX
	previousPlayerPositionY = playerPositionY


	for i = 1, neuralNetworkCount do
		neuralNetworks[i] = NeuralNetwork:new({15*15, 15*15/3*2, 5})

		if fileExists(saveFileName) then
			neuralNetworks[i]:load(saveFileName)
		end
	end

	if fileExists(saveFileName) then
		mutate()
	else
		mutateAll()
	end

	programLoop = true
end

-- START PROGRAM
initializeProgram()

--increaseNeuralNetwork(saveFileName)

while programLoop do
	gui.clearGraphics()

	readFromMemory()

	-- Start of run initialization
	if runTimer == 0 then
		-- Reset previous player position if a new run started
		previousPlayerPositionX = playerPositionX
		previousPlayerPositionY = playerPositionY

		playerStuckPositionX = playerPositionX
		playerStuckPositionY = playerPositionY

		-- Start position is explored
		playerMoveGrid[playerPositionX][playerPositionY] = 1
	end

	-- Player moved one step
	if playerMovedOneStep() then
		-- If player stays within a small distance go next run
		if playerStuckCurrentCount >= playerStuckMaxCount then
			if ManhattanDistance(playerPositionX, playerPositionY, playerStuckPositionX, playerStuckPositionY) <= playerStuckDistance then
				nextRun()
			else
				playerStuckPositionX = playerPositionX
				playerStuckPositionY = playerPositionY
				playerStuckCurrentCount = 0
			end
		end

		playerStuckCurrentCount = playerStuckCurrentCount + 1

		fitnessSpeed = (stuckTime - stuckTimer) * 0.00001

		-- If player moved to a new grid tile, add fitness
		if inPlayerGridRange(playerPositionX, playerPositionY) then
			if playerMoveGrid[playerPositionX][playerPositionY] == 0 then
				playerMoveGrid[playerPositionX][playerPositionY] = 1
				fitnessPlayerMoving = fitnessPlayerMoving + 0.0001 + fitnessSpeed
			end
		end

		stuckTimer = 0
	end

	-- Remove wall from grid if player hits a wall
	if playerWalkingTowardsTileType == 2 then
		if playerRotation == 0 then
			if inPlayerGridRange(playerPositionX, playerPositionY - 1) then
				playerMoveGrid[playerPositionX][playerPositionY - 1] = 2
			end
		elseif playerRotation == 1 then
			if inPlayerGridRange(playerPositionX, playerPositionY + 1) then
				playerMoveGrid[playerPositionX][playerPositionY + 1] = 2
			end
		elseif playerRotation == 2 then
			if inPlayerGridRange(playerPositionX - 1, playerPositionY) then
				playerMoveGrid[playerPositionX - 1][playerPositionY] = 2
			end
		elseif playerRotation == 3 then
			if inPlayerGridRange(playerPositionX + 1, playerPositionY) then
				playerMoveGrid[playerPositionX + 1][playerPositionY] = 2
			end
		end
	end

	input = getNeuralNetworkInputFromGrid(15, 15)

	-- Input Scanner Visual
	--drawInputScanner(input)

	output = neuralNetworks[neuralNetworkIndex]:feedForward(input)

	joypadTable = {
		Right = output[1] > 0,
		Left = output[2] > 0,
		Up = output[3] > 0,
		Down = output[4] > 0,
		B = output[5] > 0
	}
	
	gui.text(5, 5 + 20 * 0, "Best Fitness: " .. bestFitness)
	gui.text(5, 5 + 20 * 1, "Best Run: " .. bestRun)
	gui.text(5, 5 + 20 * 3, "Current Run: " .. totalRuns + 1)
	gui.text(5, 5 + 20 * 4, "Current Evolution: " .. evolution)

	-- Draw replay text
	if neuralNetworkIndex <= goodNeuralNetworkCount and runTimer <= 150 then
		gui.drawText(client.screenwidth() / 2, client.screenheight() / 2, "Replay #" .. neuralNetworkIndex, nil, nil, 100, nil, "bold", "center", "center")
	end

	-- Player exploration fitness
	--[[
	if playerMovedOneStep() then
		for i = 1, #(input) do
			if input[i] > 0 then
				fitnessPlayerExploration = fitnessPlayerExploration + 0.0001
			end
		end
	end
	--]]

	--[[
	if output[1] > 0 then
		--fitnessMoveInput = fitnessMoveInput - 0.00001 * runTimer
	else
		fitnessMoveInput = fitnessMoveInput + math.min(0.000001 * runTimer, 0.0001)
	end

	if output[2] > 0 then
		--fitnessMoveInput = fitnessMoveInput - 0.00001 * runTimer
	else
		fitnessMoveInput = fitnessMoveInput + math.min(0.000001 * runTimer, 0.0001)
	end

	if output[3] > 0 then
		--fitnessMoveInput = fitnessMoveInput - 0.00001 * runTimer
	else
		fitnessMoveInput = fitnessMoveInput + math.min(0.000001 * runTimer, 0.0001)
	end

	if output[4] > 0 then
		--fitnessMoveInput = fitnessMoveInput - 0.00001 * runTimer
	else
		fitnessMoveInput = fitnessMoveInput + math.min(0.000001 * runTimer, 0.0001)
	end
	--]]

	joypad.set(joypadTable)

	-- Draw Neural Network
	--drawCurrentNeuralNetwork()

	runTimer = runTimer + 1

	if runTimer >= runTime then
		nextRun()
	end

	stuckTimer = stuckTimer + 1

	if stuckTimer >= stuckTime then
		nextRun()
	end

	emu.frameadvance()

	previousPlayerPositionX = playerPositionX
	previousPlayerPositionY = playerPositionY
end

-- Back propegation outputs berekenen door random outputs in te vullen en daarmee te kijken of de fitness score hoger wordt
-- Die outputs gebruiken voor back propegation
-- Misschien alle mogelijke outputs uitproberen en de beste te selecteren