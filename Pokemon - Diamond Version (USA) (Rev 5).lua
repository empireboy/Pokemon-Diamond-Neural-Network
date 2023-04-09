debugMode = true

NeuralNetwork = {}
UIDrawer = {}
ReplayMemory = {}

combinedInput = {}
input = {}
combinedPreviousInput = {}
previousInput = {}
previousInputHistory = {}
previousInputHistory2 = {}
inputScannerBorderString = "---------------------"
inputScannerWidth = 5
inputScannerHeight = 5
debugStartInput = nil
output = {}
previousOutput = {}

--[[

	Neural Network Inputs:
	1. Input Scanner (width x height)
	2. Is Player in Battle (0 or 1)
	3. Player Pokemon Health (binary)
	4. Opponent Pokemon Health (binary)
	5. Battle Screen ID (binary)
	6. Battle Move ID (binary)
	7. 1..6 Again for Previous Inputs (history)

--]]

neuralNetworks = {}
neuralNetworkLayers = {(inputScannerWidth * inputScannerHeight + 1 + 10 + 10 + 10 + 9) * 2, 800, 6}
neuralNetworkLayersBackPropagationTest = {inputScannerWidth * inputScannerHeight, 1000, 8}
neuralNetworkLayersBackPropagationTestFromReplayMemory = {inputScannerWidth * inputScannerHeight, 20, 20, 4}
neuralNetworkIndex = 1
neuralNetworkCount = 20
goodNeuralNetworkCount = 5
averageNeuralNetworkCount = 5
neuralNetworkNegativeColorLow = "#300000"
neuralNetworkNegativeColor = "Red"
neuralNetworkNegativeColorHigh = "#FFCCCB"
neuralNetworkPositiveColorLow = "#003000"
neuralNetworkPositiveColor = "green"
neuralNetworkPositiveColorHigh = "#00FF00"
neuralNetworkType = "Q Learning"
neuralNetworkOutputType = "Random"
neuralNetworkDropoutPercentage = 30
isDropoutActive = true
neuralNetworkLearningRate = 0.01
neuralNetworkWeightDecay = 0.001

bestRun = -1
totalRuns = 0
runTime = 3000
runTimer = 0
evolution = 0
totalErrors = {}
totalErrorsIndex = 1
maxTotalErrors = 50
totalErrorsSaveFileName = "Total Errors.txt"
totalCorrectActions = {}
totalCorrectActionsIndex = 1
maxTotalCorrectActions = 200
totalCorrectSaveFileName = "Total Correct.txt"

mutationChance = 40
mutationStrength = 30

joypadTable = {}
joypadControl = true

playerPositionX = 0
playerPositionY = 0
playerPositionXAddress = 0x291D3C
playerPositionYAddress = 0x291D44
playerPositionXAddressForWrite = 0x291D48
playerPositionYAddressForWrite = 0x291D50
playerPositionXAddressForWriteVisual = 0x34FC1E
playerPositionYAddressForWriteVisual = 0x34FC26
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
playerRepetitiveStuckMaxCount = 30
isPlayerRepetitiveStuckActive = true
isPlayerInConversation = false
playerConversationAddress = 0x39E544
isPlayerInBattle = false
playerInBattleAddress = 0x1F6484
playerPokemonHealth = 0
playerPokemonHealthAddress = 0x2B587C
playerPokemonHealthMaxLength = 10
playerPokemonOpponentHealth = 0
previousPlayerPokemonOpponentHealth = 0
playerPokemonOpponentHealthAddress = 0x2B593C
playerBattleScreenID = 0
playerBattleScreenIDAddress = 0x26014E
playerBattleScreenIDMaxLength = 10
playerBattleMoveID = 0
playerBattleMoveIDAddress = 0x2B5BA4
playerBattleMoveIDMaxLength = 9

worldGrid = {}
worldGridWidth = 1000
worldGridHeight = 1000
worldGridCreatorTimer = 0
worldGridCreatorX = 100
worldGridCreatorY = 850
worldGridCreatorTillX = 115
worldGridCreatorTillY = 851
worldGridCreatorXStart = worldGridCreatorX
worldGridCreatorIndex = 0
worldGridSaveFileName = "World Grid.txt"
unExploredTileInput = 0
exploredTileInput = 0.25
wallInput = 0.5
wallColor = "White"
npcInput = 0.75
npcColor = "Yellow"
grassInput = 1
grassColor = "DarkGreen"

stuckTime = 3 -- 40
stuckTimer = 0
isStuckTimerActive = true
isRunTimerActive = true

bestFitness = 0
fitnessPlayerMoving = 0
fitnessPlayerSpeed = 0
fitnessPlayerBattle = 0

explorationExploitation = 0
explorationExploitationIncrease = 0.01

saveState = 9
minSaveState = 5
maxSaveState = 8
isRandomSaveStateActive = false

saveFileName = "Best Neural Network.txt"

replayAfterEvolution = false
replayTime = 150
replayFormat = "Replay #%s"

extraBorderWidth = 360

trainingTextPositionX = 5
trainingTextPositionY = 5
trainingTextOffsetY = 20

replayMemory = nil
replayMemorySize = 1000
replayMemorySaveFileName = "Replay Memory.txt"
batchLearnTime = 30
batchLearnTimer = 0
isBatchLearnTimerActive = true
batchSize = 20
debugReplay = nil
saveReplayTime = 10
saveReplayTimer = 0
isSaveReplayTimerActive = true

bellmanDiscountFactor = 0.8
bellmanLearningRate = 0.1

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

function uniform(low, high)
	return low + (high - low) * math.random()
end

function normal(mean, std)
	local u1 = math.random()
	local u2 = math.random()
	local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)

	return mean + z * std
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

function copyTable(fromTable, toTable)
	for i, value in pairs(fromTable) do
		toTable[i] = value
	end
end

function averageTables3D(table)
	local result = {}
	for i = 1, #table[1] do
		result[i] = {}
		for j = 1, #table[1][i] do
			result[i][j] = 0
			for k = 1, #table do
				result[i][j] = result[i][j] + table[k][i][j]
			end
			result[i][j] = result[i][j] / #table
		end
	end
	return result
end

function averageTables4D(table)
	local result = {}
	for i = 1, #table[1] do
		result[i] = {}
		for j = 1, #table[1][i] do
			result[i][j] = {}
			for l = 1, #table[1][i][j] do
				result[i][j][l] = 0
				for k = 1, #table do
					result[i][j][l] = result[i][j][l] + table[k][i][j][l]
				end
				result[i][j][l] = result[i][j][l] / #table
			end
		end
	end
	return result
end

function binary(value, length)
	local binaryString = ""

	while value > 0 do
		local remainder = value % 2

		binaryString = tostring(remainder) .. binaryString
		value = math.floor(value / 2)
	end

	if length then
		if binaryString ~= "" then
			binaryString = string.format("%0" .. tostring(length) .. "d", tonumber(binaryString))
		else
			binaryString = string.rep("0", length)
		end
	end

	return binaryString
end

function insertBinary(toTable, binaryString)
	for i = 1, #binaryString do
		local binaryValue = tonumber(string.sub(binaryString, i, i))

		table.insert(toTable, binaryValue)
	end
end

function getJoypadTableFromOutput(output)
	local joypadTable = {
		Left = false,
		Right = false,
		Up = false,
		Down = false,
		B = false
	}

	local maxAction = nil
	local maxValue = -math.huge

	for index, value in ipairs(output) do
		if value > maxValue then
			maxAction = index
			maxValue = value
		end
	end

	if (maxAction == 1) then joypadTable = { Left = true }
	elseif (maxAction == 2) then joypadTable = { Left = true , B = true }
	elseif (maxAction == 3) then joypadTable = { Right = true }
	elseif (maxAction == 4) then joypadTable = { Right = true, B = true }
	elseif (maxAction == 5) then joypadTable = { Up = true }
	elseif (maxAction == 6) then joypadTable = { Up = true, B = true }
	elseif (maxAction == 7) then joypadTable = { Down = true }
	elseif (maxAction == 8) then joypadTable = { Down = true, B = true  }
	end

	return joypadTable
end

function getJoypadTableFromOutputWithoutWalk(output)
	local joypadTable = {
		Left = false,
		Right = false,
		Up = false,
		Down = false,
		B = false,
		A = false
	}

	local maxAction = nil
	local maxValue = -math.huge

	for index, value in ipairs(output) do
		if value > maxValue then
			maxAction = index
			maxValue = value
		end
	end

	if (maxAction == 1) then joypadTable = { Left = true , B = true }
	elseif (maxAction == 2) then joypadTable = { Right = true, B = true }
	elseif (maxAction == 3) then joypadTable = { Up = true, B = true }
	elseif (maxAction == 4) then joypadTable = { Down = true, B = true  }
	elseif (maxAction == 5) then joypadTable = { B = true  }
	elseif (maxAction == 6) then joypadTable = { A = true  }
	end

	return joypadTable
end

function getSimpleJoypadTableFromOutput(output)
	local joypadTable = {
		Left = false,
		Right = false,
		Up = false,
		Down = false,
		B = false
	}

	local maxAction = nil
	local maxValue = -math.huge

	for index, value in ipairs(output) do
		if value > maxValue then
			maxAction = index
			maxValue = value
		end
	end

	if (maxAction == 1) then joypadTable = { Left = true , B = true }
	elseif (maxAction == 2) then joypadTable = { Right = true, B = true }
	elseif (maxAction == 3) then joypadTable = { Up = true, B = true }
	elseif (maxAction == 4) then joypadTable = { Down = true, B = true  }
	end

	return joypadTable
end

function getRandomOutput(buttonCount)
	local joypadTable = {}

	local randomIndex = math.random(1, buttonCount)

	for i = 1, buttonCount do
		if (i == randomIndex) then
			joypadTable[i] = 1
		else
			joypadTable[i] = -1
		end
	end

	return joypadTable
end

function getSimpleRandomOutput()
	local joypadTable = {}

	local buttonCount = 4
	local randomIndex = math.random(1, buttonCount)

	for i = 1, buttonCount do
		if (i == randomIndex) then
			joypadTable[i] = 1
		else
			joypadTable[i] = -1
		end
	end

	return joypadTable
end

function fileExists(fileName)
	local saveFile = io.open(fileName, "r")

	if saveFile then saveFile:close() end

	return saveFile ~= nil
end

function saveLine(fileName, value)
	local saveFile = io.open(fileName, "a")

	saveFile:write(value, "\n")

	io.close(saveFile)
end

function isInputEqual(input1, input2)
	local inputEqual = true

	for i = 1, #(input1) do
		if input1[i] ~= input2[i] then
			inputEqual = false
		end
	end

	return inputEqual
end

function isReplayEqual(replay1, replay2)
	for i = 1, #(replay1["State"]) do
		if replay1["State"][i] ~= replay2["State"][i] then
			return false, "Replay 1 is not supposed to have a different State at index " .. i .. " than when it was added"
		end
	end

	for i = 1, #(replay1["Actions"]) do
		if replay1["Actions"][i] ~= replay2["Actions"][i] then
			return false, "Replay 1 is not supposed to have different Actions at index " .. i .. " than when it was added"
		end
	end

	if replay1["Reward"] ~= replay2["Reward"] then
		return false, "Replay 1 is not supposed to have a different Reward" .. " than when it was added"
	end

	for i = 1, #(replay1["Next State"]) do
		if replay1["Next State"][i] ~= replay2["Next State"][i] then
			return false, "Replay 1 is not supposed to have a different Next State at index " .. i .. " than when it was added"
		end
	end

	return true, "Replays are equal"
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
	isPlayerInBattle = numberToBool(memory.read_s32_le(playerInBattleAddress))
	playerPokemonHealth = memory.read_s32_le(playerPokemonHealthAddress)
	playerPokemonOpponentHealth = memory.read_s32_le(playerPokemonOpponentHealthAddress)
	playerBattleScreenID = memory.read_s16_le(playerBattleScreenIDAddress)
	playerBattleMoveID = memory.read_s16_le(playerBattleMoveIDAddress)

	if not isPlayerInBattle then
		playerPokemonHealth = 0
		playerPokemonOpponentHealth = 0
		playerBattleScreenID = 0
		playerBattleMoveID = 0
	end
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
	local lines = {}
	-- Start index at 3 to skip width and height
	local index = 3
	local saveFileAlreadyExists = fileExists(worldGridSaveFileName)

	if saveFileAlreadyExists then
		for line in io.lines(fileName) do 
			lines[#lines + 1] = line
		end
	end

	local saveFile = io.open(fileName, "w")

	saveFile:write(worldGridWidth, "\n")
	saveFile:write(worldGridHeight, "\n")

	for i = 1, #worldGrid do
		for j = 1, #worldGrid[i] do
			-- Overwrite the tile from the save file, so new tiles will be added
			if saveFileAlreadyExists then
				local tileFromSave = tonumber(lines[index])

				if tileFromSave ~= 0 then
					worldGrid[i][j] = tileFromSave
				end

				index = index + 1
			end

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
	neuralNetworks[1]:mutate(100, mutationStrength)
end

function initNeuralNetworksForBackPropagationTestFromReplayMemory()
	neuralNetworks[1] = NeuralNetwork:new(neuralNetworkLayersBackPropagationTestFromReplayMemory)
	neuralNetworks[2] = NeuralNetwork:new(neuralNetworkLayersBackPropagationTestFromReplayMemory)

	neuralNetworks[1]:mutate(100, mutationStrength)

	neuralNetworks[1]:copy(neuralNetworks[2])
end

function initReplayMemory()
	replayMemory = ReplayMemory:new(replayMemorySize)

	if fileExists(replayMemorySaveFileName) then
		replayMemory:load(replayMemorySaveFileName)
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
		updatePlayerPreviousPosition()

		playerRepetitiveStuckPositionX = playerPositionX
		playerRepetitiveStuckPositionY = playerPositionY

		-- Start position is explored
		worldGrid[playerPositionX][playerPositionY] = exploredTileInput
	end
end

function trainingLoopPlayerMoved()
	-- Player moved one step
	if playerMovedOneStep() then
		if not updatePlayerRepetitiveStuck() then
			return false
		end

		updatePlayerMovementFitness()

		stuckTimer = 0
	end

	return true
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
			if debugMode then
				print("Next run due to being in the same area for too long")
			end

			if neuralNetworkType == "Default" then
				return false
			elseif neuralNetworkType == "Q Learning" then
				return false
			end
		else
			playerRepetitiveStuckPositionX = playerPositionX
			playerRepetitiveStuckPositionY = playerPositionY
			playerRepetitiveStuckCurrentCount = 0
		end
	end

	playerRepetitiveStuckCurrentCount = playerRepetitiveStuckCurrentCount + 1

	return true
end

function updatePlayerMovementFitness()
	fitnessPlayerSpeed = fitnessPlayerSpeed + (stuckTime - stuckTimer) * 0.01

	-- If player moved to a new grid tile, add fitness
	if isPlayerInGridRange() then
		if worldGrid[playerPositionX][playerPositionY] == unExploredTileInput then
			worldGrid[playerPositionX][playerPositionY] = exploredTileInput
			fitnessPlayerMoving = fitnessPlayerMoving + 1

			if debugMode and neuralNetworkOutputType == "Policy" then
				addCorrectAction(true)
			end
		elseif worldGrid[playerPositionX][playerPositionY] == exploredTileInput then
			fitnessPlayerMoving = fitnessPlayerMoving - 0.8

			if debugMode and neuralNetworkOutputType == "Policy" then
				addCorrectAction(false)
			end
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
				gridValue ~= npcInput
			then
				-- Wall
				if playerWalkingTowardsTileType == 2 then
					worldGrid[gridPositionX][gridPositionY] = wallInput

				-- Grass
				elseif playerTileType == 2 then
					worldGrid[playerPositionX][playerPositionY] = grassInput
				end

				-- NPCs
				if isPlayerInConversation then
					worldGrid[gridPositionX][gridPositionY] = npcInput
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
		if debugMode then
			print("Next run due to timer ending")
		end

		return false
	end

	return true
end

function updateStuckTimer()
	if not isStuckTimerActive then
		return true
	end

	stuckTimer = stuckTimer + 1

	if stuckTimer >= stuckTime then
		stuckTimer = 0

		if debugMode and not isPlayerInBattle then
			print("Next run due to being stuck")
		end

		return false
	end

	return true
end

function updateBatchLearnTimer()
	if not isBatchLearnTimerActive then
		return true
	end

	batchLearnTimer = batchLearnTimer + 1

	if batchLearnTimer >= batchLearnTime then
		batchLearnTimer = 0

		return false
	end

	return true
end

function updateSaveReplayTimer()
	if not isSaveReplayTimerActive then
		return true
	end

	saveReplayTimer = saveReplayTimer + 1

	if saveReplayTimer >= saveReplayTime then
		saveReplayTimer = 0

		return false
	end

	return true
end

function updateExplorationExploitation()
	if math.random(0, 100) >= explorationExploitation then
		output = getRandomOutput(6)

		copyTable(output, neuralNetworks[neuralNetworkIndex].neurons[#(neuralNetworks[neuralNetworkIndex].layers)])

		neuralNetworkOutputType = "Random"
	else
		copyTable(neuralNetworks[neuralNetworkIndex]:feedForward(combinedInput), output)

		neuralNetworkOutputType = "Policy"

		--print(output)
	end

	joypadTable = getJoypadTableFromOutputWithoutWalk(output)
end

function trainOnBatch(batchSize)
	if runTimer <= 0 then
		return
	end

	-- Save first replay for debugging
	if debugReplay == nil then
		debugReplay = replayMemory:cloneReplay(1)
	end

	local replays = replayMemory:getBatch(batchSize)

	local weightsDeltaGradients = {}
	local gammaGradients = {}

	local targetOutputs = {}
	local totalReplaysError = 0
					
	for i = 1, #(replays) do
		local outputPolicy = {}
		copyTable(neuralNetworks[neuralNetworkIndex]:feedForward(replays[i]["State"]), outputPolicy)

		local outputTarget = {}
		copyTable(neuralNetworks[neuralNetworkIndex + 1]:feedForward(replays[i]["Next State"]), outputTarget)

		local outputErrors = {}

		local maxTargetAction = maxValueInTable(outputTarget)

		local maxQValue = maxQValue(replays[i]["Reward"], bellmanDiscountFactor, maxTargetAction)

		local maxReplayAction, maxReplayIndex = maxValueInTable(replays[i]["Actions"])

		for errorIndex = 1, #(outputPolicy) do
			-- Update only the max Q value
			if errorIndex == maxReplayIndex then
				outputErrors[errorIndex] = bellmanEquation(bellmanLearningRate, outputPolicy[errorIndex], maxQValue)
				--outputErrors[errorIndex] = math.min(math.abs(outputErrors[errorIndex]), 1) * (outputErrors[errorIndex]/math.abs(outputErrors[errorIndex]))

				totalReplaysError = totalReplaysError + math.abs(maxQValue - outputErrors[errorIndex])

				targetOutputs[errorIndex] = outputErrors[errorIndex]
				--targetOutputs[errorIndex] = outputPolicy[errorIndex] + outputErrors[errorIndex]
			else
				targetOutputs[errorIndex] = outputPolicy[errorIndex]
			end
		end

		-- Compute the average absolute error
		local totalError = 0

		for i = 1, #targetOutputs do
			totalError = totalError + math.abs(targetOutputs[i])
		end

		local avgError = totalError / #targetOutputs

		-- Scale the output errors
		for i = 1, #targetOutputs do
			targetOutputs[i] = targetOutputs[i] / avgError
		end
						
		--[[
		if replays[i]["Reward"] < 0 then
			print("Reward: " .. replays[i]["Reward"])
			print("Max Q Value: " .. maxQValue)
			print("Current:")
			print(outputPolicy)
			print("Errors:")
			print(outputErrors)
			print("Target:")
			print(targetOutputs)
		end
		--]]

		replayMemory:updatePriority(replays[i]["Index"], math.abs(maxQValue - outputErrors[maxReplayIndex]))
						
		neuralNetworks[neuralNetworkIndex]:backPropagate(targetOutputs, neuralNetworkLearningRate)
	end

	-- Total errors calculation
	addError(totalReplaysError)
end

function saveReplay(policyNeuralNetwork, targetNeuralNetwork, input, previousInput, previousOutput, reward, discountFactor, learningRate)
	if runTimer <= 0 then
		return
	end

	if #input <= 0 then
		return "Cannot save replay since input is nil or empty"
	end

	if #previousInput <= 0 then
		return "Cannot save replay since previous input is nil or empty"
	end

	if #previousOutput <= 0 then
		return "Cannot save replay since previous output is nil or empty"
	end

	local outputPolicy = {}
	copyTable(policyNeuralNetwork:feedForward(previousInput), outputPolicy)

	local outputTarget = {}
	copyTable(targetNeuralNetwork:feedForward(input), outputTarget)

	local maxTargetAction = maxValueInTable(outputTarget)

	local maxQValue = maxQValue(reward, bellmanDiscountFactor, maxTargetAction)

	local maxAction, maxActionIndex = maxValueInTable(previousOutput)

	local priority = math.abs(bellmanEquation(learningRate, outputPolicy[maxActionIndex], maxQValue))

	replayMemory:addReplay(previousInput, previousOutput, reward, input, priority)
end

function addError(error)
	if totalErrorsIndex < maxTotalErrors then
		totalErrors[totalErrorsIndex] = error
		totalErrorsIndex = totalErrorsIndex + 1
	else
		totalErrorsIndex = 1						
	end
end

function printAverageError()
	if #(totalErrors) <= 0 then
		return nil
	end

	local totalError = 0
	local totalErrorAverage = 0
	local totalErrorSize = 0

	for i = 1, maxTotalErrors do
		if totalErrors[i] ~= nil then
			totalError = totalError + totalErrors[i]
			totalErrorSize = totalErrorSize + 1
		end
	end

	totalErrorAverage = totalError / totalErrorSize

	-- Only keep two decimal places
	totalErrorAverage = math.floor(totalErrorAverage * 100) / 100

	print("Total Error: " .. totalErrorAverage)

	return totalErrorAverage
end

function addCorrectAction(correctAction)
	if totalCorrectActionsIndex < maxTotalCorrectActions then
		totalCorrectActions[totalCorrectActionsIndex] = correctAction
		totalCorrectActionsIndex = totalCorrectActionsIndex + 1
	else
		totalCorrectActionsIndex = 1						
	end
end

function printCorrectActions()
	if #(totalCorrectActions) <= 0 then
		return nil
	end

	local totalCorrect = 0
	local totalCorrectPercentage = 0

	for i = 1, maxTotalCorrectActions do
		if totalCorrectActions[i] ~= nil then
			if totalCorrectActions[i] == true then
				totalCorrect = totalCorrect + 1
			end
		end
	end

	totalCorrectPercentage = (totalCorrect / #(totalCorrectActions)) * 100

	-- Only keep two decimal places
	totalCorrectPercentage = math.floor(totalCorrectPercentage * 100) / 100

	print("Total Correct: " .. totalCorrectPercentage .. "%")

	return totalCorrectPercentage
end

function maxQValue(reward, discountFactor, maxAction)
	return reward + discountFactor * maxAction
end

function maxValueInTable(table)
	local maxValueIndex = nil
	local maxValue = -math.huge

	for index, value in ipairs(table) do
		if value > maxValue then
			maxValueIndex = index
			maxValue = value
		end
	end

	return maxValue, maxValueIndex
end

function bellmanEquation(learningRate, policyQValue, maxQValue)
	return policyQValue + learningRate * (maxQValue - policyQValue)
	--return (1 - learningRate) * policyQValue + learningRate * maxQValue
end

function getNeuralNetworkColorFromValue(value)
	local color

	if value <= -0.66 then
		color = neuralNetworkNegativeColorHigh
	elseif value <= -0.33 and value > -0.66 then
		color = neuralNetworkNegativeColor
	elseif value <= 0 and value > -0.33 then
		color = neuralNetworkNegativeColorLow
	elseif value >= 0.66 then
		color = neuralNetworkPositiveColorHigh
	elseif value >= 0.33 and value < 0.66 then
		color = neuralNetworkPositiveColor
	elseif value > 0 and value < 0.33 then
		color = neuralNetworkPositiveColorLow
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
				input[inputIndex] = wallInput
			end

			input[inputIndex] = input[inputIndex]

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

function nextRunByType()
	if neuralNetworkType == "Default" then
		nextRun()
	elseif neuralNetworkType == "Q Learning" then
		nextRunQLearning()
	end
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

	-- Save after every run so you don't lose progress
	neuralNetworks[neuralNetworkIndex]:save(saveFileName)

	replayMemory:save(replayMemorySaveFileName)

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

			print("New Best Fitness: " .. bestFitness)
		end
	end

	fitnessPlayerMoving = 0
	fitnessPlayerSpeed = 0
	
	playerRepetitiveStuckCurrentCount = 0

	stuckTimer = 0
	runTimer = 0
	input = {}

	for i = 1, #(neuralNetworks) do
		neuralNetworks[i].fitness = 0
	end

	if debugMode then
		-- Debugging total error
		local averageError = printAverageError()

		-- Save average error if it's added
		if averageError ~= nil then
			saveLine(totalErrorsSaveFileName, averageError)
		end

		-- Debugging correct percentage
		local correctPercentage = printCorrectActions()

		-- Save correct percentage if it's added
		if correctPercentage ~= nil then
			saveLine(totalCorrectSaveFileName, correctPercentage)
		end

		-- Debugging replays
		if 
			debugReplay ~= nil and
			replayMemory.size < replayMemory.maxSize 
		then
			local replayEqual, errorMessage = isReplayEqual(debugReplay, replayMemory.replays[1])

			if not replayEqual then
				print(errorMessage)
			end

			if not debugReplay["Index"] == 1 then
				print("Replay 1 has an index of " .. debugReplay["Index"] .. " which is supposed to be 1")
			end
		end
	end
	
	initWorldGrid()
	loadWorldGrid(worldGridSaveFileName)

	-- Load between a random save state so that it learns multiple inputs at the same time
	if isRandomSaveStateActive then
		saveState = math.random(minSaveState, maxSaveState)
	end

	savestate.loadslot(saveState)

	trainingLoopQLearning()
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
	return fitnessPlayerMoving + fitnessPlayerSpeed + fitnessPlayerBattle
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
	math.randomseed(os.clock()*1000000)

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
	math.randomseed(os.clock()*1000000)

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
	math.randomseed(os.clock()*1000000)

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
	math.randomseed(os.clock()*1000000)

	event.onexit(onExit)

	console.clear()

	client.SetClientExtraPadding(extraBorderWidth, 0, 0, 0)

	gui.use_surface("client")
	gui.clearGraphics()

	initNeuralNetworksForBackPropagationTest()

	trainingLoopBackPropagationTest()
end

function runBackPropagationTestFromReplayMemory()
	math.randomseed(os.clock()*1000000)

	event.onexit(onExit)

	console.clear()

	client.SetClientExtraPadding(extraBorderWidth, 0, 0, 0)

	gui.use_surface("client")
	gui.clearGraphics()

	initReplayMemory();

	initNeuralNetworksForBackPropagationTestFromReplayMemory()

	trainingLoopBackPropagationTestFromReplayMemory()
end

function runBackPropagationTestFromReplayMemoryOutputsOnly()
	math.randomseed(os.clock()*1000000)

	event.onexit(onExit)

	console.clear()

	client.SetClientExtraPadding(extraBorderWidth, 0, 0, 0)

	gui.use_surface("client")
	gui.clearGraphics()

	initReplayMemory();

	initNeuralNetworksForBackPropagationTestFromReplayMemory()

	trainingLoopBackPropagationTestFromReplayMemoryOutputsOnly()
end

function runInputScannerOnly()
	event.onexit(onExit)

	console.clear()

	client.SetClientExtraPadding(extraBorderWidth, 0, 0, 0)

	memory.usememorydomain("Main RAM")

	gui.use_surface("client")
	gui.clearGraphics()

	readFromMemory()

	initWorldGrid()
	loadWorldGrid(worldGridSaveFileName)

	trainingLoopInputScannerOnly()
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
			memory.write_s16_le(playerPositionXAddressForWriteVisual, worldGridCreatorX)
			memory.write_s16_le(playerPositionYAddressForWriteVisual, worldGridCreatorY)
		elseif worldGridCreatorIndex == 10 * 1 then
			savestate.loadslot(saveState)

			memory.write_s32_le(playerPositionXAddressForWrite, worldGridCreatorX)
			memory.write_s32_le(playerPositionYAddressForWrite, worldGridCreatorY)
			memory.write_s16_le(playerPositionXAddressForWriteVisual, worldGridCreatorX)
			memory.write_s16_le(playerPositionYAddressForWriteVisual, worldGridCreatorY)
		elseif worldGridCreatorIndex == 10 * 2 then
			savestate.loadslot(saveState)

			memory.write_s32_le(playerPositionXAddressForWrite, worldGridCreatorX)
			memory.write_s32_le(playerPositionYAddressForWrite, worldGridCreatorY)
			memory.write_s16_le(playerPositionXAddressForWriteVisual, worldGridCreatorX)
			memory.write_s16_le(playerPositionYAddressForWriteVisual, worldGridCreatorY)
		elseif worldGridCreatorIndex == 10 * 3 then
			savestate.loadslot(saveState)

			memory.write_s32_le(playerPositionXAddressForWrite, worldGridCreatorX)
			memory.write_s32_le(playerPositionYAddressForWrite, worldGridCreatorY)
			memory.write_s16_le(playerPositionXAddressForWriteVisual, worldGridCreatorX)
			memory.write_s16_le(playerPositionYAddressForWriteVisual, worldGridCreatorY)
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

			if worldGridCreatorX >= worldGridCreatorTillX then
				if worldGridCreatorY < worldGridCreatorTillY then
					worldGridCreatorY = worldGridCreatorY + 1
					worldGridCreatorX = worldGridCreatorXStart
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
	while true do
		initTrainingLoop()

		if not trainingLoopPlayerMoved() then
			nextRunByType()

			break
		end

		local playerPokemonOpponentHealthDiff = playerPokemonOpponentHealth - previousPlayerPokemonOpponentHealth

		previousPlayerPokemonOpponentHealth = playerPokemonOpponentHealth

		if playerPokemonOpponentHealthDiff < 0 then
			fitnessPlayerBattle = fitnessPlayerBattle + math.abs(playerPokemonOpponentHealthDiff) * 0.01

			if debugMode and neuralNetworkOutputType == "Policy" then
				addCorrectAction(true)
			end
		else
			fitnessPlayerBattle = fitnessPlayerBattle - math.abs(playerPokemonOpponentHealthDiff) * 0.01
		end

		--updateWorldGrid()

		local reward = getCurrentReward()

		copyTable(input, previousInput)

		if not isInputEqual(input, previousInputHistory) then
			copyTable(previousInputHistory, previousInputHistory2)
			copyTable(input, previousInputHistory)
		end

		previousOutput = {}
		copyTable(output, previousOutput)

		addFitness(neuralNetworks[neuralNetworkIndex])

		fitnessPlayerMoving = 0
		fitnessPlayerSpeed = 0
		fitnessPlayerBattle = 0

		input = getNeuralNetworkInputFromGrid(inputScannerWidth, inputScannerHeight)

		-- Insert all different inputs
		table.insert(input, boolToNumber(isPlayerInBattle))

		local binaryString = binary(playerPokemonHealth, playerPokemonHealthMaxLength)
		insertBinary(input, binaryString)

		binaryString = binary(playerPokemonOpponentHealth, playerPokemonHealthMaxLength)
		insertBinary(input, binaryString)

		binaryString = binary(playerBattleScreenID, playerBattleScreenIDMaxLength)
		insertBinary(input, binaryString)

		binaryString = binary(playerBattleMoveID, playerBattleMoveIDMaxLength)
		insertBinary(input, binaryString)

		-- Make sure previous inputs are initialized to zero
		if runTimer <= 0 then
			previousInputHistory = {}
			previousInputHistory2 = {}

			for i = 1, #input do
				table.insert(previousInputHistory, 0)
				table.insert(previousInputHistory2, 0)
			end
		end

		-- Combine inputs with history of previous inputs
		combinedInput = {}
		combinedPreviousInput = {}

		copyTable(input, combinedInput)
		copyTable(previousInputHistory, combinedPreviousInput)

		for i = 1, #previousInputHistory do
			table.insert(combinedInput, previousInputHistory[i])
		end

		for i = 1, #previousInputHistory2 do
			table.insert(combinedPreviousInput, previousInputHistory2[i])
		end

		UIDrawer.drawInputScanner(previousInputHistory, 32, 200, inputScannerHeight)
		UIDrawer.drawInputScanner(previousInputHistory2, 160, 200, inputScannerHeight)
		UIDrawer.drawInputScanner(combinedInput, 32, 260, inputScannerHeight)
		UIDrawer.drawInputScanner(combinedPreviousInput, 32, 320, inputScannerHeight)

		-- Setting the start input value for debugging
		if debugMode then
			if debugStartInput == nil then
				debugStartInput = {}

				copyTable(combinedInput, debugStartInput)
			end
		end

		if not updateSaveReplayTimer() then
			local errorMessage = saveReplay(
				neuralNetworks[neuralNetworkIndex],
				neuralNetworks[neuralNetworkIndex + 1],
				combinedInput,
				combinedPreviousInput,
				previousOutput,
				reward,
				bellmanDiscountFactor,
				bellmanLearningRate
			)

			if errorMessage then
				print(errorMessage)
			end
		end

		if not updateBatchLearnTimer() then
			trainOnBatch(batchSize)
		end

		if not isInputEqual(input, previousInput) then
			updateExplorationExploitation()
		end

		explorationExploitation = explorationExploitation + explorationExploitationIncrease

		if explorationExploitation >= 100 then
			print("Updating target network")

			evolution = evolution + 1

			neuralNetworks[neuralNetworkIndex]:copy(neuralNetworks[neuralNetworkIndex + 1])

			explorationExploitation = 0
		end

		setJoypadInput(joypadTable)

		if not updateRunTimer() then
			nextRunByType()

			break
		end

		if not updateStuckTimer() then
			--if neuralNetworkOutputType == "Random" then
			if not isPlayerInBattle then
				-- Add a decreased reward when stuck in a wall
				fitnessPlayerMoving = fitnessPlayerMoving - 1

				reward = getCurrentReward()

				if isSaveReplayTimerActive then
					local errorMessage = saveReplay(
						neuralNetworks[neuralNetworkIndex],
						neuralNetworks[neuralNetworkIndex + 1],
						combinedInput,
						combinedPreviousInput,
						previousOutput,
						reward,
						bellmanDiscountFactor,
						bellmanLearningRate
					)

					if errorMessage then
						print(saveReplay)
					end
				end

				if debugMode and neuralNetworkOutputType == "Policy" then
					addCorrectAction(false)
				end

				nextRunByType()

				break
			else
				-- Make sure that the neural network continues during a battle
				updateExplorationExploitation()
			end
			--end
		end

		UIDrawer.drawTrainingUI()

		emu.frameadvance()

		updatePlayerPreviousPosition()
	end
end

function trainingLoopBackPropagationTest()
	while true do
		gui.clearGraphics()

		local learningRate = 0.005
		local totalError = 0

		-- Output 1

		for i = 1, inputScannerWidth * inputScannerHeight do
			input[i] = 0
		end

		local outputTargets = {-0.5, -0.5, -0.5, -1, -1, 0, -1, -0.5}

		local errors = {}

		output = neuralNetworks[neuralNetworkIndex]:feedForward(input)

		--print(output)
		
		
		--[[
		print(
			"Current output: [" ..
			tonumber(string.format("%.3f", output[1])) ..
			"] [" ..
			tonumber(string.format("%.3f", output[2])) ..
			"] [" ..
			tonumber(string.format("%.3f", output[3])) ..
			"] [" ..
			tonumber(string.format("%.3f", output[4])) ..
			"] [" ..
			tonumber(string.format("%.3f", output[5])) ..
			"]"
		)
		--]]

		for i = 1, #(outputTargets) do
			errors[i] = (output[i] - outputTargets[i])^2
			totalError = totalError + errors[i]
		end

		neuralNetworks[neuralNetworkIndex]:backPropagate(outputTargets, learningRate)

		-- Output 2

		for i = 1, inputScannerWidth * inputScannerHeight do
			input[i] = 0.2
		end

		outputTargets = {0.7, 0.1, 0.2, 0.5, 0.9, 1, 0.5, 0.9}

		errors = {}

		output = neuralNetworks[neuralNetworkIndex]:feedForward(input)
		
		--[[
		print(
			"Current output: [" ..
			tonumber(string.format("%.3f", output[1])) ..
			"] [" ..
			tonumber(string.format("%.3f", output[2])) ..
			"] [" ..
			tonumber(string.format("%.3f", output[3])) ..
			"] [" ..
			tonumber(string.format("%.3f", output[4])) ..
			"] [" ..
			tonumber(string.format("%.3f", output[5])) ..
			"]"
		)
		--]]

		for i = 1, #(outputTargets) do
			errors[i] = (output[i] - outputTargets[i])^2
			totalError = totalError + errors[i]
		end

		neuralNetworks[neuralNetworkIndex]:backPropagate(outputTargets, learningRate)

		-- Output 3

		for i = 1, inputScannerWidth * inputScannerHeight do
			input[i] = 1
		end

		outputTargets = {-0.2, -1, -0.2, -0.8, -0.4, -0.2, -0.5, -0.9}

		errors = {}

		output = neuralNetworks[neuralNetworkIndex]:feedForward(input)

		for i = 1, #(outputTargets) do
			errors[i] = (output[i] - outputTargets[i])^2
			totalError = totalError + errors[i]
		end

		neuralNetworks[neuralNetworkIndex]:backPropagate(outputTargets, learningRate)

		-- Output 4

		for i = 1, inputScannerWidth * inputScannerHeight do
			input[i] = 0.7
		end

		outputTargets = {0.1, 1, 1, 1, 0.3, 1, 1, 1}

		errors = {}

		output = neuralNetworks[neuralNetworkIndex]:feedForward(input)

		for i = 1, #(outputTargets) do
			errors[i] = (output[i] - outputTargets[i])^2
			totalError = totalError + errors[i]
		end

		neuralNetworks[neuralNetworkIndex]:backPropagate(outputTargets, learningRate)

		print("Total error: " .. string.format("%.10f", totalError))

		UIDrawer.drawCurrentNeuralNetwork()

		emu.frameadvance()
	end
end

function trainingLoopBackPropagationTestFromReplayMemory()
	while true do
		gui.clearGraphics()

		local replays = replayMemory:getBatch(20)

		local targetOutputs = {}
		local totalReplaysError = 0
					
		for i = 1, #(replays) do
			local outputPolicy = {}
			copyTable(neuralNetworks[neuralNetworkIndex]:feedForward(replays[i]["State"]), outputPolicy)

			local outputTarget = {}
			copyTable(neuralNetworks[neuralNetworkIndex + 1]:feedForward(replays[i]["Next State"]), outputTarget)

			local outputErrors = {}

			local maxTargetAction = maxValueInTable(outputTarget)

			local maxQValue = maxQValue(replays[i]["Reward"], bellmanDiscountFactor, maxTargetAction)

			local maxReplayAction, maxReplayIndex = maxValueInTable(replays[i]["Actions"])

			for errorIndex = 1, #(outputPolicy) do
				-- Update only the max Q value
				if errorIndex == maxReplayIndex then
					outputErrors[errorIndex] = bellmanEquation(bellmanLearningRate, outputPolicy[errorIndex], maxQValue)
					outputErrors[errorIndex] = math.min(math.abs(outputErrors[errorIndex]), 1) * (outputErrors[errorIndex]/math.abs(outputErrors[errorIndex]))

					totalReplaysError = totalReplaysError + math.abs(maxQValue - outputErrors[errorIndex])

					targetOutputs[errorIndex] = outputErrors[errorIndex]
				else
					targetOutputs[errorIndex] = outputPolicy[errorIndex]
				end
			end

			replayMemory:updatePriority(replays[i]["Index"], math.abs(maxQValue - outputErrors[maxReplayIndex]))

			neuralNetworks[neuralNetworkIndex]:backPropagate(targetOutputs, 0.005)
		end

		-- Total errors calculation
		local totalError = 0
		local totalErrorAverage = 0
		local totalErrorSize = 0

		if totalErrorsIndex <= maxTotalErrors then
			totalErrors[totalErrorsIndex] = totalReplaysError
			totalErrorsIndex = totalErrorsIndex + 1
		else
			totalErrorsIndex = 1						
		end

		for i = 1, maxTotalErrors do
			if totalErrors[i] ~= nil then
				totalError = totalError + totalErrors[i]
				totalErrorSize = totalErrorSize + 1
			end
		end

		totalErrorAverage = totalError / totalErrorSize

		if (debugMode) then
			print("Total Error: " .. string.format("%.2f", totalErrorAverage))
		end

		--UIDrawer.drawCurrentNeuralNetwork()

		emu.frameadvance()
	end
end

function trainingLoopBackPropagationTestFromReplayMemoryOutputsOnly()
	while true do
		gui.clearGraphics()

		local replays = replayMemory:getBatch(20)

		local targetOutputs = {}
		local totalReplaysError = 0

		local totalError = 0
		local errors = {}
					
		for i = 1, #(replays) do
			output = neuralNetworks[neuralNetworkIndex]:feedForward(replays[i]["State"])

			neuralNetworks[neuralNetworkIndex]:backPropagate(replays[i]["Actions"], 0.01)

			for i = 1, #(replays[i]["Actions"]) do
				errors[i] = (output[i] - replays[i]["Actions"][i])^2
				totalReplaysError = totalReplaysError + errors[i]
			end
		end

		--print("Total error: " .. string.format("%.10f", totalReplaysError))

		-- Total errors calculation
		local totalError = 0
		local totalErrorAverage = 0
		local totalErrorSize = 0

		if totalErrorsIndex <= maxTotalErrors then
			totalErrors[totalErrorsIndex] = totalReplaysError
			totalErrorsIndex = totalErrorsIndex + 1
		else
			totalErrorsIndex = 1						
		end

		for i = 1, maxTotalErrors do
			if totalErrors[i] ~= nil then
				totalError = totalError + totalErrors[i]
				totalErrorSize = totalErrorSize + 1
			end
		end

		totalErrorAverage = totalError / totalErrorSize

		if (debugMode) then
			print("Total Error: " .. string.format("%.2f", totalErrorAverage))
		end

		--UIDrawer.drawCurrentNeuralNetwork()

		emu.frameadvance()
	end
end

function trainingLoopInputScannerOnly()
	while true do
		gui.clearGraphics()

		readFromMemory()

		input = getNeuralNetworkInputFromGrid(inputScannerWidth * 5, inputScannerHeight * 5)

		UIDrawer.drawInputScanner(input, 16, 16)

		emu.frameadvance()
	end
end

function UIDrawer.drawTrainingUI()
	UIDrawer.drawTrainingText(trainingTextPositionX, trainingTextPositionY, trainingTextOffsetY)

	--UIDrawer.drawReplayText(neuralNetworkIndex)

	--UIDrawer.drawCurrentNeuralNetwork()

	UIDrawer.drawInputScanner(input, 240, 5, inputScannerHeight)

	
	gui.text(600, 200, neuralNetworkOutputType)
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

function UIDrawer.drawInputScanner(input, positionX, positionY, height, tileWidth, tileHeight, outlineColor)
	positionX = positionX or 240
	positionY = positionY or 5
	height = height or math.sqrt(#input)
	tileWidth = tileWidth or 9
	tileHeight = tileHeight or 9

	local inputScannerIndex = 1
	local color

	local width = math.ceil(#input / height)

	for i = 1, width do
		for j = 1, height do
			if not input[inputScannerIndex] then
				break
			end

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

	this.layers = {}
	copyTable(layers, this.layers)
	this.neurons = {}
	this.neuronsWithoutActivation = {}
	this.neuronsTarget = {}
	this.testBias = {}
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

			if layerIndex ~= #(self.neurons) then
				-- Dropout
				if isDropoutActive then
					if math.random() < (neuralNetworkDropoutPercentage / 100) then
						value = 0
					else
						value = value / (1 - (neuralNetworkDropoutPercentage / 100))
					end
				end

				self.neurons[layerIndex][neuronIndex] = self:activate(
					value + self.biases[layerIndex][neuronIndex]
				)
			else
				self.neurons[layerIndex][neuronIndex] = value + self.biases[layerIndex][neuronIndex]
			end
			

			self.neuronsWithoutActivation[layerIndex][neuronIndex] = value + self.biases[layerIndex][neuronIndex]
		end
	end

	return self.neurons[#(self.neurons)]
end

function NeuralNetwork:backPropagate(targetOutputs, learningRate)
	self:updateBackPropagateWeightsAndBiases2(targetOutputs, learningRate)
	--self:updateBackPropagateWeightsAndBiases(targetOutputs, learningRate)	
end

function NeuralNetwork:updateBackPropagateWeightsAndBiases2(targetOutputs, learningRate)
	local layer = #(self.layers)
	local targetOutput = 0

	local totalError = 0

	local gamma = {}
	local weightsDelta = {}

	local layerCount = #(self.layers)
	local layerCountWithoutOutput = #(self.layers) - 1

	for i = 1, layerCount do
		local neuronCount = self.layers[i]
		gamma[i] = {}

		for j = 1, neuronCount do
			gamma[i][j] = 0
		end
	end

	for i = 2, layerCount do
		local neuronsInPreviousLayer = self.layers[i - 1]
		local neuronsInCurrentLayer = #(self.neurons[i])

		weightsDelta[i - 1] = {}

		for j = 1, neuronsInCurrentLayer do
			weightsDelta[i - 1][j] = {}

			for k = 1, neuronsInPreviousLayer do
				weightsDelta[i - 1][j][k] = 0
			end
		end
	end

	for layerIndex = 1, layerCountWithoutOutput do
		local neuronsInLayer = #(self.neurons[layer])

		for neuronIndex = 1, neuronsInLayer do
			local weightCountInLayer = #(self.weights[layer - 1][neuronIndex])

			-- Calculate output layer
			if layer == #(self.layers) then
				targetOutput = targetOutputs[neuronIndex]

				local error = self.neurons[layer][neuronIndex] - targetOutput
				--local error = (targetOutput - self.neurons[layer][neuronIndex])^2
				--local error = (self.neurons[layer][neuronIndex] - targetOutput)^2
				totalError = totalError + math.abs(error)
				gamma[layer][neuronIndex] = error * self:activateDerivative(self.neuronsWithoutActivation[layer][neuronIndex])
				
				for weightIndex = 1, weightCountInLayer do
					weightsDelta[layer - 1][neuronIndex][weightIndex] = gamma[layer][neuronIndex] * self.neurons[layer - 1][weightIndex]
				end
			-- Calculate hidden layers
			else
				gamma[layer][neuronIndex] = 0

				local gammaCountInNextLayer = #(gamma[layer + 1])

				for gammaIndex = 1, gammaCountInNextLayer do
					gamma[layer][neuronIndex] = gamma[layer + 1][gammaIndex] * self.weights[layer][gammaIndex][neuronIndex] -- gammaIndex and neuronIndex backwards?
				end

				gamma[layer][neuronIndex] = gamma[layer][neuronIndex] * self:activateDerivative(self.neuronsWithoutActivation[layer][neuronIndex])

				for weightIndex = 1, weightCountInLayer do
					weightsDelta[layer - 1][neuronIndex][weightIndex] = gamma[layer][neuronIndex] * self.neurons[layer - 1][weightIndex]
				end
			end

			for weightIndex = 1, weightCountInLayer do
				--self.weights[layer - 1][neuronIndex][weightIndex] = self.weights[layer - 1][neuronIndex][weightIndex] - weightsDelta[layer - 1][neuronIndex][weightIndex] * learningRate
				--self.weights[layer - 1][neuronIndex][weightIndex] = self.weights[layer - 1][neuronIndex][weightIndex] - (weightsDelta[layer - 1][neuronIndex][weightIndex] + learningRate * self.weights[layer - 1][neuronIndex][weightIndex]) * learningRate
				
				-- Weight Decay
				local weightDecayValue = neuralNetworkWeightDecay * self.weights[layer - 1][neuronIndex][weightIndex]
				self.weights[layer - 1][neuronIndex][weightIndex] = self.weights[layer - 1][neuronIndex][weightIndex] - (weightsDelta[layer - 1][neuronIndex][weightIndex] + weightDecayValue) * learningRate
			end

			self.biases[layer][neuronIndex] = self.biases[layer][neuronIndex] - (gamma[layer][neuronIndex] * self.neurons[layer][neuronIndex]) * learningRate
		end

		layer = layer - 1
	end

	-- Debugging to see if the error gets lower
	--[[
	if debugMode then
		local currentTotalError = 0
		local errors = {}

		self:feedForward(self.neurons[1])

		for i = 1, #(targetOutputs) do
			errors[i] = (self.neurons[#(self.layers)][i] - targetOutputs[i])^2
			currentTotalError = currentTotalError + errors[i]
		end

		--print(currentTotalError - totalError)
		--print("Current: " .. currentTotalError)
		--print("Previous: " .. totalError)
	end
	--]]
end

--[[
function NeuralNetwork:backPropagate(targetOutputs, learningRate)
	local weightsDelta, gamma = self:calculateGradients(targetOutputs)

	self:updateBackPropagateWeightsAndBiases2(learningRate, weightsDelta, gamma)
end

function NeuralNetwork:backPropagateFromGradients(learningRate, weightsDelta, gamma)
	self:updateBackPropagateWeightsAndBiases2(learningRate, weightsDelta, gamma)
end

function NeuralNetwork:updateBackPropagateWeightsAndBiases2(learningRate, weightsDelta, gamma)
	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
                self.weights[i][j][k] = self.weights[i][j][k] - (weightsDelta[i][j][k] + learningRate * self.weights[i][j][k]) * learningRate
            end

            self.biases[i + 1][j] = self.biases[i + 1][j] - (gamma[i + 1][j] * self.neurons[i + 1][j]) * learningRate
        end
    end
end

function NeuralNetwork:calculateGradients(targetOutputs)
	local layer = #(self.layers)
	local targetOutput = 0

	local totalError = 0

	local gamma = {}
	local weightsDelta = {}

	for i = 1, #(self.layers) do
		gamma[i] = {}

		for j = 1, self.layers[i] do
			gamma[i][j] = 0
		end
	end

	for i = 2, #(self.layers) do
		weightsDelta[i - 1] = {}
		local neuronsInPreviousLayer = self.layers[i - 1]

		for j = 1, #(self.neurons[i]) do
			weightsDelta[i - 1][j] = {}

			for k = 1, neuronsInPreviousLayer do
				weightsDelta[i - 1][j][k] = 0
			end
		end
	end

	for layerIndex = 1, #(self.layers) - 1 do
		for neuronIndex = 1, #(self.neurons[layer]) do
			-- Calculate output layer
			if layer == #(self.layers) then
				targetOutput = targetOutputs[neuronIndex]

				local error = self.neurons[layer][neuronIndex] - targetOutput
				--local error = (targetOutput - self.neurons[layer][neuronIndex])^2
				--local error = (self.neurons[layer][neuronIndex] - targetOutput)^2
				totalError = totalError + math.abs(error)
				gamma[layer][neuronIndex] = error * self:activateDerivative(self.neuronsWithoutActivation[layer][neuronIndex])
			
				for weightIndex = 1, #(self.weights[layer - 1][neuronIndex]) do
					weightsDelta[layer - 1][neuronIndex][weightIndex] = gamma[layer][neuronIndex] * self.neurons[layer - 1][weightIndex]
				end
			-- Calculate hidden layers
			else
				gamma[layer][neuronIndex] = 0

				for gammaIndex = 1, #(gamma[layer + 1]) do
					gamma[layer][neuronIndex] = gamma[layer + 1][gammaIndex] * self.weights[layer][gammaIndex][neuronIndex] -- gammaIndex and neuronIndex backwards?
				end

				gamma[layer][neuronIndex] = gamma[layer][neuronIndex] * self:activateDerivative(self.neuronsWithoutActivation[layer][neuronIndex])

				for weightIndex = 1, #(self.weights[layer - 1][neuronIndex]) do
					weightsDelta[layer - 1][neuronIndex][weightIndex] = gamma[layer][neuronIndex] * self.neurons[layer - 1][weightIndex]
				end
			end
		end

		layer = layer - 1
	end

	return weightsDelta, gamma
end
--]]

function NeuralNetwork:updateBackPropagateWeightsAndBiases(targetOutputs, learningRate)
	local layer = #(self.layers)
	local targetOutput = 0

	for layerIndex = 1, #(self.layers) - 1 do
		for neuronIndex = 1, #(self.neurons[layer]) do
			if (layer == #(self.layers)) then
				targetOutput = targetOutputs[neuronIndex]
			end

			for weightIndex = 1, #(self.weights[layer - 1][neuronIndex]) do
				self:updateBackPropagateWeight(learningRate, layer, neuronIndex, weightIndex, targetOutput)
			end

			self:updateBackPropagateBias(learningRate, layer, neuronIndex, targetOutput)
		end

		layer = layer - 1
	end
end

function NeuralNetwork:updateBackPropagateWeight(learningRate, layer, neuronIndex, weightIndex, targetOutput)
	local weight = self.weights[layer - 1][neuronIndex][weightIndex]

	local newWeight = self:calculateBackPropagateWeight(
		weight, learningRate, layer, neuronIndex, weightIndex, targetOutput
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

function NeuralNetwork:calculateBackPropagateWeight(weight, learningRate, layer, neuronIndex, weightIndex, targetOutput)
	local ratio = self:calculateBackPropagateWeightRatio(layer, neuronIndex, weightIndex, targetOutput)

	self.neuronsTarget[layer - 1][weightIndex] = self.neuronsTarget[layer - 1][weightIndex] + ratio

	return weight - learningRate * ratio
end

function NeuralNetwork:calculateBackPropagateBias(bias, learningRate, layer, neuronIndex, targetOutput)
	return bias - learningRate * self:calculateBackPropagateBiasRatio(bias, layer, neuronIndex, targetOutput)
end

function NeuralNetwork:calculateBackPropagateWeightRatio(layer, neuronIndex, weightIndex, targetOutput)
	return (
		self:calculateBackPropagateChainAWeight(layer, neuronIndex, weightIndex, targetOutput) *
		self:calculateBackPropagateChainB(layer, neuronIndex) *
		self:calculateBackPropagateChainCWeight(layer, neuronIndex, weightIndex)
	)
end

function NeuralNetwork:calculateBackPropagateBiasRatio(bias, layer, neuronIndex, targetOutput)
	return (
		self:calculateBackPropagateChainABias(layer, neuronIndex, targetOutput) *
		self:calculateBackPropagateChainB(layer, neuronIndex) *
		self:calculateBackPropagateChainCBias(bias)
	)
end

function NeuralNetwork:calculateBackPropagateChainAWeight(layer, neuronIndex, weightIndex, targetOutput)
	local result = 0

	--[[
	if (layer == #(self.layers)) then
		result = 2 * (self.neurons[layer][neuronIndex] - targetOutput)
	else
		result = 2 * (self.neurons[layer][neuronIndex] - self.neuronsTarget[layer][neuronIndex])
	end

	--self.neuronsTarget[layer - 1][weightIndex] = self.neuronsTarget[layer - 1][weightIndex] + result
	--]]

	if (layer == #(self.layers)) then
		result = self.neurons[layer][neuronIndex] - targetOutput
	else
		--result = 2 * (self.neurons[layer][neuronIndex] - self.neuronsTarget[layer][neuronIndex])
	end

	return result
end

function NeuralNetwork:calculateBackPropagateChainABias(layer, neuronIndex, targetOutput)
	local result = 0

	if (layer == #(self.layers)) then
		result = 2 * (self.neurons[layer][neuronIndex] - targetOutput)
	else
		result = self.neuronsTarget[layer][neuronIndex]
	end

	return result
end

function NeuralNetwork:calculateBackPropagateChainB(layer, neuronIndex)
	return self:activateDerivative(self.neuronsWithoutActivation[layer][neuronIndex])
end

function NeuralNetwork:calculateBackPropagateChainCWeight(layer, neuronIndex, weightIndex)
	return self.neurons[layer - 1][weightIndex]
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

function NeuralNetwork:xavierInitialization(scale)
	for i = 1, #(self.neurons) do
		for j = 1, #(self.neurons[i]) do
			self.neurons[i][j] = 0
		end
	end

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			self.biases[i][j] = uniform(-scale, scale)
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				self.weights[i][j][k] = uniform(-scale, scale)
			end
		end
	end
end

function NeuralNetwork:heInitialization(scale)
	for i = 1, #(self.neurons) do
		for j = 1, #(self.neurons[i]) do
			self.neurons[i][j] = 0
		end
	end

	for i = 1, #(self.biases) do
		for j = 1, #(self.biases[i]) do
			self.biases[i][j] = normal(0, scale)
		end
	end

	for i = 1, #(self.weights) do
		for j = 1, #(self.weights[i]) do
			for k = 1, #(self.weights[i][j]) do
				self.weights[i][j][k] = normal(0, scale)
			end
		end
	end
end

function NeuralNetwork:initNeurons()
	for i = 1, #(self.layers) do
		self.neurons[i] = {}
		self.neuronsWithoutActivation[i] = {}
		self.neuronsTarget[i] = {}

		for j = 1, self.layers[i] do
			self.neurons[i][j] = 0
			self.neuronsWithoutActivation[i][j] = 0
			self.neuronsTarget[i][j] = 0
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

function ReplayMemory:addReplay(state, actions, reward, nextState, priority)
	-- Traverse backwards if replay memory is full
	if self.size >= self.maxSize then
		for i = 2, #(self.replays) do
			self.replays[i - 1] = self:cloneReplay(i)
			self.replays[i - 1]["Index"] = i - 1
		end
	end

	self.size = math.min(self.size + 1, self.maxSize)

	self.replays[self.size] = {}

	self.replays[self.size]["State"] = {}
	self.replays[self.size]["Actions"] = {}
	self.replays[self.size]["Next State"] = {}

	self.replays[self.size]["Index"] = self.size

	self.replays[self.size]["Priority"] = priority

	copyTable(state, self.replays[self.size]["State"])

	copyTable(actions, self.replays[self.size]["Actions"])

	self.replays[self.size]["Reward"] = reward

	copyTable(nextState, self.replays[self.size]["Next State"])
end

function ReplayMemory:getBatch(size)
	size = math.min(self.size, size)

	local sortedReplays = self:cloneAllReplays()

	table.sort(sortedReplays, function(a, b) return a["Priority"] > b["Priority"] end)
	
	local replays = {}

	for i = 1, size do
		replays[i] = sortedReplays[math.random(1, math.min(size * 2, self.size))]
	end

	return replays
end

function ReplayMemory:updatePriority(index, priority)
	self.replays[index]["Priority"] = priority
end

function ReplayMemory:cloneReplay(index)
	local replay = {}

	replay["State"] = {}
	replay["Actions"] = {}
	replay["Next State"] = {}

	replay["Index"] = self.replays[index]["Index"]

	replay["Priority"] = self.replays[index]["Priority"]

	copyTable(self.replays[index]["State"], replay["State"])

	copyTable(self.replays[index]["Actions"], replay["Actions"])

	replay["Reward"] = self.replays[index]["Reward"]

	copyTable(self.replays[index]["Next State"], replay["Next State"])

	return replay
end

function ReplayMemory:cloneAllReplays()
	local replays = {}

	for i = 1, #(self.replays) do
		replays[i] = {}

		replays[i]["State"] = {}
		replays[i]["Actions"] = {}
		replays[i]["Next State"] = {}

		replays[i]["Index"] = self.replays[i]["Index"]

		replays[i]["Priority"] = self.replays[i]["Priority"]

		copyTable(self.replays[i]["State"], replays[i]["State"])

		copyTable(self.replays[i]["Actions"], replays[i]["Actions"])

		replays[i]["Reward"] = self.replays[i]["Reward"]

		copyTable(self.replays[i]["Next State"], replays[i]["Next State"])
	end

	return replays
end

function ReplayMemory:save(fileName)
	local saveFile = io.open(fileName, "w")

	saveFile:write(self.size, "\n")

	for replayIndex = 1, #(self.replays) do
		saveFile:write(self.replays[replayIndex]["Index"], "\n")

		saveFile:write(self.replays[replayIndex]["Priority"], "\n")

		for stateIndex = 1, #(self.replays[replayIndex]["State"]) do
			saveFile:write(self.replays[replayIndex]["State"][stateIndex], "\n")
		end

		for actionIndex = 1, #(self.replays[replayIndex]["Actions"]) do
			saveFile:write(self.replays[replayIndex]["Actions"][actionIndex], "\n")
		end

		saveFile:write(self.replays[replayIndex]["Reward"], "\n")

		for nextStateIndex = 1, #(self.replays[replayIndex]["Next State"]) do
			saveFile:write(self.replays[replayIndex]["Next State"][nextStateIndex], "\n")
		end
	end

	io.close(saveFile)
end

function ReplayMemory:load(fileName)
	local lines = {}
	local index = 1

	for line in io.lines(fileName) do 
		lines[#lines + 1] = line
	end

	self.size = tonumber(lines[index])
	index = index + 1

	for replayIndex = 1, self.size do
		self.replays[replayIndex] = {}

		self.replays[replayIndex]["State"] = {}
		self.replays[replayIndex]["Actions"] = {}
		self.replays[replayIndex]["Next State"] = {}

		self.replays[replayIndex]["Index"] = tonumber(lines[index])
		index = index + 1

		self.replays[replayIndex]["Priority"] = tonumber(lines[index])
		index = index + 1

		for stateIndex = 1, neuralNetworkLayers[1] do
			self.replays[replayIndex]["State"][stateIndex] = tonumber(lines[index])
			index = index + 1
		end

		for actionIndex = 1, neuralNetworkLayers[#(neuralNetworkLayers)] do
			self.replays[replayIndex]["Actions"][actionIndex] = tonumber(lines[index])
			index = index + 1
		end

		self.replays[replayIndex]["Reward"] = tonumber(lines[index])
		index = index + 1

		for nextStateIndex = 1, neuralNetworkLayers[1] do
			self.replays[replayIndex]["Next State"][nextStateIndex] = tonumber(lines[index])
			index = index + 1
		end
	end
end

-- START PROGRAM
--runTraining()

runQLearningTraining()

--runBackPropagationTest()

--runBackPropagationTestFromReplayMemory()

--runBackPropagationTestFromReplayMemoryOutputsOnly()

--increaseNeuralNetwork(saveFileName, {inputScannerWidth * inputScannerHeight, 100, 100, 5})

--runWorldGridCreator()

--runInputScannerOnly()