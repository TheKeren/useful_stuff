REGION ?= eu-central-1

doc:
	cat docs/readme_header.md > README.md
	terraform-docs md . >> README.md
	cat docs/readme_footer.md >> README.md

test: test-debug test-clean

test-debug: test-create test-verify

test-create:
	kitchen create beamly-elasticache
	kitchen converge beamly-elasticache
	(cd spec/fixtures; terraform output) | \
        awk '{$$1= "$$"$$1; $$3= "\""$$3"\""; print}' > spec/constants.rb

test-verify:
	AWS_REGION=$(REGION) kitchen verify beamly-elasticache

test-clean:
	kitchen destroy keren-elasticache
