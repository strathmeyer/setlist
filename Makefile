server: dev

dev:
	 shotgun -sthin -p33202 >out.log >&out.log &

production:
	rackup -sthin -p33202 >out.log >&out.log &
