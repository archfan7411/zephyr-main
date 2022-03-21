extends Node


var pos_update_interval = 0.1
var protocol_version = 2

var player = null
var main = null
var input = null
var history = null
var respawn_point = null

var base_health = 100
var healthbar = null

var raycast = null

var target_address = "archvps.us"
var target_port = 7411
