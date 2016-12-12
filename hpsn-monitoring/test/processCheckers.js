"use strict";
//http://chaijs.com/
var chai = require('chai')
  , SSH = require('simple-ssh') // https://www.npmjs.com/package/simple-ssh
  , expect = chai.expect
  , should = chai.should()
  , assert = chai.assert
  , config = require('../config.js')
  , procChecker = require('./lib/processCheckerHelper.js')
  , timeoutForSSHCommands = config.timeoutInMillisForSSHCommands || 15000
  , ipsToSkip = config.ipsToSkip || []
  , testHelper = require('./lib/testHelper');

if (!testHelper.verifyEnvironmentIsSpecified(config)) {
  return;
}

config.environmentsToTest.forEach(function (env) {
  var configEnv = config[env];

  function getSSHClient(host) {
    if (ipsToSkip.indexOf(host) >= 0) {
      return {skipTest: true, host: host};
    }
    return new SSH({
      host: host,
      user: configEnv.sshUser,
      key: configEnv.sshKey
    });
  }

// ====================================================================================================================
// ==================================================== THE TESTS =====================================================
// ====================================================================================================================

  describe('Environment: ' + env + ' -- ssh process checks', function () {
    if (config.disableProcessChecks) {
      it('should skip all ssh process checks because HPSN_DISABLE_PROCESS_CHECKS=1 was specified', function () {})
      return;
    }

    this.timeout(timeoutForSSHCommands);  // increase the default timeout since SSH can take a while.

    describe('jetty servers', function () {
      configEnv.hosts.jettyServers.forEach(function (jettyServer) {
        it('should have jetty running on ' + jettyServer, function (done) {
          //ubuntu@hpe-stg-jetty1:~$ ps -ef | grep [j]etty | grep "/usr/bin/java"
          //jetty     9145     1  0 Oct02 ?        00:29:10 /usr/bin/java -Djetty.state=/opt/jetty/jetty.state -Djetty.home=/opt/jetty -Djava.io.tmpdir=/mnt/jetty_java_io_tmp -jar /opt/jetty/start.jar jetty.port=8080 etc/jetty-logging.xml etc/jetty-started.xml etc/jetty-rewrite.xml etc/jetty-requestlog.xml --daemon
          var ssh = getSSHClient(jettyServer)
            , cmd = "ps -ef | grep [j]etty | grep '/usr/bin/java'";
          procChecker.checkProcess(ssh, cmd, done);
        });
      });
    });

    describe('portal socket servers', function () {
      configEnv.hosts.portalSocketServers.forEach(function (pss) {
        it('should have the node.js process running portal-socket-server.js on ' + pss, function (done) {
          //ubuntu@staging-portal-socket-server:~$ ps -ef | grep -e '[n]ode.*/portal-socket-server.js'
          //ubuntu   11368 12131  0 Jul14 ?        00:00:23 /usr/bin/nodejs /home/ubuntu/portal_socket_server_archives/1167/portal-socket-server.js
          var ssh = getSSHClient(pss)
            , cmd = "ps -ef | grep -e '[n]ode.*/portal-socket-server.js'";
          procChecker.checkProcess(ssh, cmd, done);
        });

        it('should be running with forever and have a minimum uptime value on ' + pss, function (done) {
          var ssh = getSSHClient(pss)
            , minNumberOfSecondsUptime = 20;
          procChecker.checkForeverScript(ssh, 'portal-socket-server.js', done, minNumberOfSecondsUptime);
        });
      });
    });

    describe('screen socket node.js servers', function () {
      configEnv.hosts.screenSocketServers.forEach(function (sss) {
        it('should have the node.js process running server.js on ' + sss, function (done) {
          var ssh = getSSHClient(sss)
            , cmdPS = "ps -ef | grep -e '[n]ode.*/server.js'";
          procChecker.checkProcess(ssh, cmdPS, done);
        });

        it('should be running with forever and have a minimum uptime value on ' + sss, function (done) {
          var ssh = getSSHClient(sss)
            , minNumberOfSecondsUptime = 20;
          procChecker.checkForeverScript(ssh, 'server.js', done, minNumberOfSecondsUptime);
        });

      });
    });

    describe('mongo database servers / replica sets', function () {
      var minimumUptimeInSeconds = 15 * 60;
      it('should have a primary running', function (done) {
        var ssh = getSSHClient(configEnv.hosts.mongoPrimary);
        procChecker.checkMongo(ssh, minimumUptimeInSeconds, done, true, false, false);
      });
      it('should have a secondary running', function (done) {
        var ssh = getSSHClient(configEnv.hosts.mongoSecondary);
        procChecker.checkMongo(ssh, minimumUptimeInSeconds, done, false, true, false);
      });
      it('should have an arbiter running', function (done) {
        var ssh = getSSHClient(configEnv.hosts.mongoArbiter);
        procChecker.checkMongo(ssh, minimumUptimeInSeconds, done, false, false, true);
      });
    });

    describe('redis servers and sentinels', function () {
      var cmdPing = "redis-cli PING";

      it('should have master running', function (done) {
        var ssh = getSSHClient(configEnv.hosts.redisMaster);
        procChecker.checkProcess(ssh, cmdPing, done);
      });

      describe('all slaves', function () {
        configEnv.hosts.redisSlaves.forEach(function (host, index) {
          it('should have slave ' + index + ' running (host: ' + host + ')', function (done) {
            var ssh = getSSHClient(host);
            procChecker.checkProcess(ssh, cmdPing, done);
          });
        });
      });

      describe('sentinels', function () {
        var cmd = 'ps -ef | grep [r]edis-sentinel';
        it('should have a sentinel running on master', function (done) {
          var ssh = getSSHClient(configEnv.hosts.redisMaster);
          procChecker.checkProcess(ssh, cmd, done);
        });
        configEnv.hosts.redisSlaves.forEach(function (host, index) {
          it('should have a sentinel running on slave ' + index + ' (host: ' + host + ')', function (done) {
            var ssh = getSSHClient(host);
            procChecker.checkProcess(ssh, cmd, done);
          });
        });
      });

    });

    describe('analytics - kinesis client', function () {
      it('should be running the kinesis-redshift connector java process', function (done) {
        var ssh = getSSHClient(configEnv.hosts.kinesisClient)
          , cmd = "jps | grep RedshiftBasicExecutor";
        procChecker.checkProcess(ssh, cmd, done);
      });
    });

    describe('nginx: load balancers', function () {
      var cmd = "service nginx status";
      describe('jetty load balancer', function () {
        it('should be running the nginx service for jetty servers', function (done) {
          var ssh = getSSHClient(configEnv.hosts.loadBalancerJava);
          procChecker.checkProcess(ssh, cmd, done);
        });
      });
      describe('screen socket server - node.js load balancer', function () {
        it('should be running the nginx service for node.js servers', function (done) {
          var ssh = getSSHClient(configEnv.hosts.loadBalancerNodeJS);
          procChecker.checkProcess(ssh, cmd, done);
        });
      });
      describe('portal socket server - node.js load balancer', function () {
        if (configEnv.hosts.loadBalancerPortalSocket) {
          it('should be running the nginx service for portal socket node.js servers', function (done) {
            var ssh = getSSHClient(configEnv.hosts.loadBalancerNodeJS);
            procChecker.checkProcess(ssh, cmd, done);
          });
        }
      });
    });

    describe('job runner', function () {
      it('should be running the rails server', function (done) {
        var ssh = getSSHClient(configEnv.hosts.jobRunner)
          , cmd = "ps -ef | grep '[r]uby.*rails server'";
        procChecker.checkProcess(ssh, cmd, done);
      });
      it('should be running a queue listener rake task', function (done) {
        var ssh = getSSHClient(configEnv.hosts.jobRunner)
          , cmd = "ps -ef | grep '[r]uby.*/rake redis_command_queue:start'";
        procChecker.checkProcess(ssh, cmd, done);
      });
      it('should be running queue workers', function (done) {
        //ubuntu@staging-job-runner:~$ ps -ef | grep '[r]esque-[0-9]' | sed 's/.* Waiting for //' | sed 's/,/\n/' | sort | uniq | paste -s -d',' | sed 's/\s//g' | grep box,crocodoc,download,image_thumbnails,jaspersoft_accounts,thumbnails
        //box,crocodoc,download,image_thumbnails,jaspersoft_accounts,thumbnails
        var ssh = getSSHClient(configEnv.hosts.jobRunner)
          , cmd = "ps -ef | grep '[r]esque-[0-9]' | sed 's/.* Waiting for //' | sed 's/,/\\n/' | sort | uniq | paste -s -d',' | sed 's/\\s//g' | grep box,crocodoc,download,image_thumbnails,jaspersoft_accounts,thumbnails";
        procChecker.checkProcess(ssh, cmd, done);
      });
      it('should be running the stale worker monitoring script', function (done) {
        var ssh = getSSHClient(configEnv.hosts.jobRunner)
          , cmd = "ps -ef | grep '[m]onitor_stale_workers.rb'";
        procChecker.checkProcess(ssh, cmd, done);
      });
    });

  });
});



