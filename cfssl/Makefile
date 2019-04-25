prepare:
	@bash ./release.sh prepare

build:
	@bash ./release.sh release

run:
	@docker run --rm -v $(PWD)/ssl:/ssl -w /ssl rainbond/cfssl:dev
