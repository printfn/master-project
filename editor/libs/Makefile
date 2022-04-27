default: all

ace.js:
	curl -vLO https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.14/ace.js

jszip.min.js:
	curl -vLO https://cdnjs.cloudflare.com/ajax/libs/jszip/3.9.1/jszip.min.js

mode-l42.js:
	curl -vLO https://l42.is/js/mode-l42.js

theme-l42_eclipse.js:
	curl -vLO https://l42.is/js/theme-l42_eclipse.js

all: ace.js jszip.min.js mode-l42.js theme-l42_eclipse.js

clean:
	rm -f ace.js jszip.min.js mode-l42.js theme-l42_eclipse.js

.PHONY: all default
