#Requires AutoHotkey v2.0
#include Jsons.ahk
#include MergeObjects.ahk

ReadJson(path, fileReadOptions := "UTF-8", debug := false) {
	if !FileExist(path) {
		if (debug)
			MsgBox('json file not found: ' path)
		return {}
	}

	text := FileRead(path, fileReadOptions)
	obj := Jsons.Load(&text)
	return MergeObjects({}, obj)
}
