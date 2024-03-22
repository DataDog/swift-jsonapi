test:
	swift test \
		--parallel

format:
	swift format --in-place --recursive .

.PHONY: format test
