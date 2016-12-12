"use strict";
var chai = require('chai')
  , assert = chai.assert;

module.exports = {
  verifyEnvironmentIsSpecified: function (config) {
    if (!config) {
      throw new Exception("No config was specified");
    }
    if (config.environmentsToTest.length === 0) {
      describe('Ensure that environments were specified.', function () {
        it('should specify at least 1 test environment', function () {
          assert(config.environmentsToTest.length > 0, "Please set environment variables to enable staging and/or prod testing.");
        });
      });
      return false;
    }
    return true;
  }
};