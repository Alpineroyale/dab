# vim: ts=4 sw=4 sts=4 noet
@smoke
Feature: Subcommand: dab version
	The version subcommand displays information
	on the current dab environment.

	Scenario: Can execute dab version and get environment info
		When I run `dab version`

		And it should pass matching:
		"""
		Dab Version: \b[0-9a-f]{5,40}\b
		Server Version:
		"""
