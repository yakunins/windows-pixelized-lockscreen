#Requires AutoHotkey v2.0

#include Log.ahk
#include MergeObjects.ahk
#include ReadJson.ahk

MergeFileConfig(config, debug := false) {
	if config.HasOwnProp("fileConfig") {
		secondaryPath := A_ScriptDir '\' config.fileConfig

		if FileExist(config.fileConfig) {
			filePath := config.fileConfig
		} else if FileExist(secondaryPath) {
			filePath := secondaryPath
		}
		fileConfig := ReadJson(filePath, , debug)
		return MergeObjects(config, fileConfig)
	}
	if (debug)
		MsgBox "Prop is not exist: config.fileConfig"
	return config
}