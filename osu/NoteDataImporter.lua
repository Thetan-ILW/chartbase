local class = require("class")
local ncdk = require("ncdk")

local NoteDataImporter = class()

NoteDataImporter.inputType = "key"

function NoteDataImporter:init()
	for i, soundData in ipairs(self.sounds) do
		soundData[2] = soundData[2] / 100
		self.noteChart:addResource("sound", soundData[1], {soundData[1], self.fallbackSounds[i][1]})
	end

	self.inputIndex = self.key

	local firstTime = math.min(self.endTime or self.startTime, self.startTime)
	if firstTime == firstTime then
		if not self.noteChartImporter.minTime or firstTime < self.noteChartImporter.minTime then
			self.noteChartImporter.minTime = firstTime
		end
	end

	local lastTime = math.max(self.endTime or self.startTime, self.startTime)
	if lastTime == lastTime then
		if not self.noteChartImporter.maxTime or lastTime > self.noteChartImporter.maxTime then
			self.noteChartImporter.maxTime = math.min(lastTime, 3600 * 2 * 1000)
		end
	end
end

function NoteDataImporter:initEvent()
	self.sounds = {}
	if self.sound and self.sound ~= "" then
		self.sounds[1] = {self.sound, self.volume / 100}
		self.noteChart:addResource("sound", self.sound, {self.sound})
	end
	self.keysound = true

	self.inputType = "auto"
	self.inputIndex = 0
end

function NoteDataImporter:getNoteData()
	local startNoteData, endNoteData

	local startTimePoint = self.noteChartImporter.foregroundLayerData:getTimePoint(self.startTime / 1000, 1)

	startNoteData = ncdk.NoteData(startTimePoint)
	startNoteData.inputType = self.inputType
	startNoteData.inputIndex = self.inputIndex
	startNoteData.sounds = self.sounds
	startNoteData.keysound = self.keysound

	if self.inputType == "auto" then
		startNoteData.noteType ="SoundNote"
	elseif not self.endTime then
		startNoteData.noteType = "ShortNote"
	else
		startNoteData.noteType = "LongNoteStart"

		local endTimePoint = self.noteChartImporter.foregroundLayerData:getTimePoint(self.endTime / 1000, 1)

		endNoteData = ncdk.NoteData(endTimePoint)
		endNoteData.inputType = self.inputType
		endNoteData.inputIndex = self.inputIndex
		endNoteData.keysound = self.keysound

		endNoteData.noteType = "LongNoteEnd"

		endNoteData.startNoteData = startNoteData
		startNoteData.endNoteData = endNoteData

		local startTime, endTime = self.startTime, self.endTime
		if startTime ~= startTime and endTime ~= endTime then
			startNoteData.noteType = "Ignore"
			endNoteData.noteType = "Ignore"
		elseif startTime ~= startTime and endTime == endTime then
			startNoteData.noteType = "Ignore"
			endNoteData.noteType = "SoundNote"
		elseif startTime == startTime and endTime ~= endTime then
			startNoteData.noteType = "SoundNote"
			endNoteData.noteType = "Ignore"
		elseif endTime < startTime then
			startNoteData.noteType = "ShortNote"
			endNoteData.noteType = "SoundNote"
		end
	end

	return startNoteData, endNoteData
end

return NoteDataImporter
