//http://chaijs.com/
var chai = require('chai')
  , expect = chai.expect
  , should = chai.should()
  , assert = chai.assert
  , request = require('request')
  , config = require('../config.js')
  , timeoutForRequests = config.timeoutInMillisForHTTPRequests || 5000
  , testHelper = require('./lib/testHelper');

if (!testHelper.verifyEnvironmentIsSpecified(config)) {
  return;
}

chai.config.includeStack = true; // turn on stack trace

if (config.environmentsToTest.length === 0) {
  describe('Ensure that environments were specified.', function () {
    it('should specify at least 1 test environment', function () {
      assert(config.environmentsToTest.length > 0, "Please set environment variables to enable staging and/or prod testing.");
    });
  });
  return;
}

config.environmentsToTest.forEach(function (env) {
  var configEnv = config[env];

  describe('Environment: ' + env + ' -- Basic HTTP requests', function () {
    if (config.disableURLChecks) {
      it('should skip all url checks because HPSN_DISABLE_URL_CHECKS=1 was specified', function () {})
      return;
    }

    this.timeout(timeoutForRequests + 1000);

    describe('health check (detailed) ', function () {
      it('should receive a successful response', function (done) {
        expect(configEnv.healthCheckDetailsUrl).to.be.ok;
        request(configEnv.healthCheckDetailsUrl, {timeout: timeoutForRequests}, function (error, response, body) {
          assert.isNull(error, "healthCheckDetails request failed with error: " + error);
          should.not.exist(error, "healthCheckDetails request failed with error: " + error);
          should.exist(body);
          response.statusCode.should.equal(200);
          done();
        });
      });
    });


    describe('rec screen with sync code', function () {
      it('should receive a successful response', function (done) {
        expect(configEnv.recScreenUrl).to.be.ok;
        request(configEnv.recScreenUrl, {timeout: timeoutForRequests}, function (error, response, body) {
          response.statusCode.should.equal(200);
          done();
        });
      });
    });

    describe('base hpsn web app', function () {
      it('should receive a successful response', function (done) {
        expect(configEnv.webAppContent).to.be.ok;
        request(configEnv.webAppContent, {timeout: timeoutForRequests}, function (error, response, body) {
          expect(response.statusCode).to.equal(200);
          done();
        });
      });
    });


    describe('portal home screen', function () {
      it('should receive a successful response', function (done) {
        expect(configEnv.portalHome).to.be.ok;
        request(configEnv.portalHome, {timeout: timeoutForRequests}, function (error, response, body) {
          expect(response.statusCode).to.equal(200);
          done();
        });
      });
    });

  });
});
