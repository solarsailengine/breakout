function engine.on_started()
	engine.createdefaultwindow()
end

function engine.on_keyboard(buffer)
	if buffer == 'q' then
		engine.requestshutdown()
	end
end