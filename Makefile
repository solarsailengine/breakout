default: run

run:
	../engine/install/player/bin/player --premount ../engine/install/player/share/assets00.zip --premount ./assets01

trace:
	SOLARSAIL_LOG_LEVEL=TRACE ../engine/install/player/bin/player --premount ../engine/install/player/share/assets00.zip --premount ./assets01

debug:
	SOLARSAIL_LOG_LEVEL=DEBUG ../engine/install/player/bin/player --premount ../engine/install/player/share/assets00.zip --premount ./assets01

warn:
	SOLARSAIL_LOG_LEVEL=WARN ../engine/install/player/bin/player --premount ../engine/install/player/share/assets00.zip --premount ./assets01

error:
	SOLARSAIL_LOG_LEVEL=ERROR ../engine/install/player/bin/player --premount ../engine/install/player/share/assets00.zip --premount ./assets01