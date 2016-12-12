"use strict";
var chai = require('chai')
  , SSH = require('simple-ssh') // https://www.npmjs.com/package/simple-ssh
  , expect = chai.expect
  , should = chai.should()
  , assert = chai.assert;

/**
 * helper function that executes the specified command and asserts that the result code is 0
 * @param sshClient - if this is an object with a property "skipTest" with a truthy value,
 * then the test is skipped
 * @param cmd
 * @param done
 * @param callback
 */
function performProcessCheck(sshClient, cmd, done, callback) {
  if (sshClient.skipTest) {
    console.log("skipping test for host: " + sshClient.host);
    done && done();
  } else {
    sshClient.exec(cmd, {
        exit: function (code, stdout, stderr) {
          assert.equal(code, 0, "STDOUT:\n" + stdout + "\n\nSTDERR:\n" + stderr);
          done && done();
          callback && callback(null, stdout, stderr);
        }
      }
    ).start({
        fail: function (err) {
          err.should.equal(null);
          done && done();
          callback && callback(err);
        }
      }
    );
  }
}

/**
 * Uses the db.serverStatus() command to verify that a mongo server is up and running
 * @param sshClient
 * @param minimumUptimeInSeconds
 * @param done
 * @param isPrimary
 * @param isSecondary
 * @param isArbiter
 */
function checkMongo(sshClient, minimumUptimeInSeconds, done, isPrimary, isSecondary, isArbiter) {
  var cmd = "mongo --eval 'print(JSON.stringify(db.serverStatus()))' --quiet";
  performProcessCheck(sshClient, cmd, null, function (err, stdout, stderr) {
    console.log("checkMongo: stdout: " + stdout);
    console.log("checkMongo: stderr: " + stderr);
    assert.isNull(err);
    var jsonOutput = JSON.parse(stdout);
    expect(jsonOutput.pid.floatApprox).to.be.above(0);
    expect(jsonOutput.uptime).to.be.above(minimumUptimeInSeconds);
    expect(jsonOutput.ok).to.equal(1);
    if (isPrimary || isSecondary || isArbiter) {
      expect(jsonOutput.repl).not.to.be.null;
      expect(jsonOutput.repl.ismaster).to.equal(isPrimary || false);
      expect(jsonOutput.repl.secondary).to.equal(isSecondary || false);
      isArbiter && expect(jsonOutput.repl.arbiterOnly).to.be.true;
    }
    done && done();
  });
}

/**
 * Checks that a process that is running via 'forever' is alive and that it meets the minimum uptime requirements
 *
 * @param sshClient
 * @param scriptName: string, e.g. 'server.js'
 * @param done
 * @param minUptimeInSeconds
 */
function performCheckOnForeverScriptWithMinimumUptime(sshClient, scriptName, done, minUptimeInSeconds) {
  var minNumberOfSecondsUptime = minUptimeInSeconds || 20
    // forever list --no-colors | grep portal-socket-server.js | sed 's/\s\+/ /g' | cut -d' ' -f9 | sed 's/\.[0-9]*//' | awk -F":" '{if ($1*86400 + $2*3600 + $3*60 + $4 < 15) {exit 5}}'
    , cmdForever = "/usr/local/bin/forever list --no-colors | /bin/grep " + scriptName + " | /bin/sed 's/\\s\\+/ /g' | /usr/bin/cut -d' ' -f9 | /bin/sed 's/\\.[0-9]*//' | /usr/bin/awk 'BEGIN {FS=\":\";} {if ($1*86400 + $2*3600 + $3*60 + $4 < " + minNumberOfSecondsUptime + ") {exit 5} }'";

  // note: the above command will cause an exit code value of 5 if the failure was due to not meeting the minimum
  // uptime in seconds.  We should use that later in order to specify if we want to allow the test to pass
  // in those circumstances.
  performProcessCheck(sshClient, cmdForever, done);
}


module.exports = {
  checkProcess: performProcessCheck,
  checkForeverScript: performCheckOnForeverScriptWithMinimumUptime,
  checkMongo: checkMongo
};
