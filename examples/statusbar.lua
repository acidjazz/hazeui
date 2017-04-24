require "hazeUI" 
_G.gui = clone(hazeUI) 
_G.gui.gpu = require("component").gpu 

_G.statusbar(10, 10, 100, 2, 10, 20, "what")
