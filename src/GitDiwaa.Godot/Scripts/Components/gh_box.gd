class_name GhBox
extends RefCounted
## กล่องรายการที่ GitHubUi.box สร้างให้: panel คือกรอบนอก body คือที่ใส่แถว

var panel: PanelContainer
var body: VBoxContainer


func _init(p_panel: PanelContainer = null, p_body: VBoxContainer = null) -> void:
	panel = p_panel
	body = p_body
