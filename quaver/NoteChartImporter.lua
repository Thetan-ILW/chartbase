local tinyyaml = require("tinyyaml")
local NoteChart = require("ncdk.NoteChart")
local MetaData = require("notechart.MetaData")
local osuNoteChartImporter = require("osu.NoteChartImporter")

local ncdk = require("ncdk")
local NoteDataImporter = require("quaver.NoteDataImporter")
local TimingDataImporter = require("quaver.TimingDataImporter")

local NoteChartImporter = {}

local NoteChartImporter_metatable = {}
NoteChartImporter_metatable.__index = NoteChartImporter

NoteChartImporter.new = function(self)
	local noteChartImporter = {}

	noteChartImporter.metaData = {}

	setmetatable(noteChartImporter, NoteChartImporter_metatable)

	return noteChartImporter
end

NoteChartImporter.import = function(self)
	self.noteChart = NoteChart:new()
	local noteChart = self.noteChart

	if not self.qua then
		self.qua = tinyyaml.parse(self.content:gsub("\r\n", "\n"))
	end

	self.foregroundLayerData = noteChart:getLayerData(1)
	self.foregroundLayerData:setTimeMode("absolute")

	self:process()

	noteChart.inputMode.key = tonumber(self.qua.Mode:sub(-1, -1))
	noteChart.type = "quaver"

	noteChart:compute()
	noteChart.index = 1
	noteChart.metaData = MetaData(noteChart, self)

	self.noteCharts = {noteChart}
end

NoteChartImporter.process = function(self)
	self.metaData = {}
	self.eventParsers = {}
	self.tempTimingDataImporters = {}
	self.timingDataImporters = {}
	self.noteDataImporters = {}

	self.noteCount = 0

	local TimingPoints = self.qua.TimingPoints
	for i = 1, #TimingPoints do
		self:addTimingPointParser(TimingPoints[i])
	end

	local SliderVelocities = self.qua.SliderVelocities
	for i = 1, #SliderVelocities do
		self:addTimingPointParser(SliderVelocities[i])
	end

	local HitObjects = self.qua.HitObjects
	for i = 1, #HitObjects do
		self:addNoteParser(HitObjects[i])
	end

	self:updateLength()
	self.noteCount = #HitObjects

	self:processTimingDataImporters()
	table.sort(self.noteDataImporters, function(a, b) return a.startTime < b.startTime end)

	self:updatePrimaryBPM()

	self:processMeasureLines()

	self.audioFileName = self.qua.AudioFile
	self:processAudio()

	self:processTimingPoints()

	for _, noteParser in ipairs(self.noteDataImporters) do
		self.foregroundLayerData:addNoteData(noteParser:getNoteData())
	end
end

NoteChartImporter.updateLength = osuNoteChartImporter.updateLength
NoteChartImporter.processTimingDataImporters = osuNoteChartImporter.processTimingDataImporters
NoteChartImporter.updatePrimaryBPM = osuNoteChartImporter.updatePrimaryBPM
NoteChartImporter.processAudio = osuNoteChartImporter.processAudio
NoteChartImporter.processTimingPoints = osuNoteChartImporter.processTimingPoints
NoteChartImporter.processMeasureLines = osuNoteChartImporter.processMeasureLines

NoteChartImporter.addTimingPointParser = function(self, timingPoint)
	local timingDataImporter = TimingDataImporter:new()
	timingDataImporter.timingPoint = timingPoint
	timingDataImporter.noteChartImporter = self
	timingDataImporter:init()

	table.insert(self.tempTimingDataImporters, timingDataImporter)
end

NoteChartImporter.addNoteParser = function(self, hitObject)
	local noteDataImporter = NoteDataImporter:new()
	noteDataImporter.hitObject = hitObject
	noteDataImporter.noteChartImporter = self
	noteDataImporter.noteChart = self.noteChart
	noteDataImporter:init()

	table.insert(self.noteDataImporters, noteDataImporter)
end

return NoteChartImporter
