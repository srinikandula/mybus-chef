/**
 * Environment variables required in order to run tests are:
 *   PROD_CHECK_ENABLED=1        # for production
 *   STAG_CHECK_ENABLED=1        # for staging
 *
 * Environment variables that can be used to override default settings:
 *   HPSN_STAGING_PEM_FILE
 *   HPSN_PROD_PEM_FILE
 *
 *   HPSN_TIMEOUT_HTTP_REQUEST     (value in milliseconds)
 *   HPSN_TIMEOUT_SSH_COMMANDS     (value in milliseconds)
 *
 *   HPSN_DISABLE_PROCESS_CHECKS=1      will disable the ssh process checkers,
 *                                      which are slow, and only runs the URL checks
 *   HPSN_DISABLE_URL_CHECKS=1          will disable the the URL checks
 *
 * Environment variables that can be used to ignore process checker tests by specifying IP address(es):
 * HPSN_SKIP_IPS   (a comma-separated string of IP addresses)
 *
 */

var fs = require('fs')
  , config;


// --------------- BEGIN helper functions -------------------
function getUserHome() {
  return process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'];
}

function getStagingPemFile() {
  return process.env.HPSN_STAGING_PEM_FILE || getUserHome() + '/.ssh/hpsn-staging-us-east.pem'
}

function getProdPemFile() {
  return process.env.HPSN_PROD_PEM_FILE || getUserHome() + '/.ssh/hpsalesnow-prod.pem'
}

function fileContentsOf(filename) {
  return fs.readFileSync(filename, {encoding: 'utf8'});
}
// --------------- END helper functions -------------------


config = {
  timeoutInMillisForHTTPRequests: parseInt(process.env.HPSN_TIMEOUT_HTTP_REQUEST) || 10000,
  timeoutInMillisForSSHCommands: parseInt(process.env.HPSN_TIMEOUT_SSH_COMMANDS) || 20000,
  environmentsToTest: [],  // can contain 'prod' and/or 'staging'
  prod: {
    recScreenUrl: "https://sales.now.hpe.com/recscreen",
    healthCheckDetailsUrl: "https://sales.now.hpe.com/healthcheck/details",
    webAppContent: "https://sales.now.hpe.com/uisupport/",
    portalHome: "https://sales.now.hpe.com/portalnosaml",
    sshUser: "ubuntu",
    sshKey: fileContentsOf(getProdPemFile()),
    hosts: {
      jettyServers: ["15.125.83.178"/*, "15.125.73.49"*/],
      portalSocketServers: ["15.125.98.157", "15.125.73.26"],
      screenSocketServers: ["15.125.68.45"],
      mongoPrimary: "15.125.64.54",
      mongoSecondary: "15.125.95.159",
      mongoArbiter: "15.125.95.13",
      redisMaster: "15.125.79.50",
      redisSlaves: ["15.125.91.211", "15.125.91.237"],
      kinesisClient: "15.125.77.131",
      jobRunner: "15.125.81.206",
      loadBalancerJava: "15.125.77.128",
      loadBalancerNodeJS: "15.125.98.120",
      loadBalancerPortalSocket: "15.125.73.26"
    }
  },
  staging: {
    recScreenUrl: "https://stage.sales.now.hpe.com/recscreen",
    healthCheckDetailsUrl: "https://stage.sales.now.hpe.com/healthcheck/details",
    webAppContent: "https://stage.sales.now.hpe.com/uisupport/",
    portalHome: "https://stage.sales.now.hpe.com/portalnosaml",
    sshUser: "ubuntu",
    sshKey: fileContentsOf(getStagingPemFile()),
    hosts: {
      jettyServers: ["15.126.229.15"],
      portalSocketServers: ["15.126.192.200"],
      screenSocketServers: ["15.126.246.139"],
      mongoPrimary: "15.126.195.217",
      mongoSecondary: "15.126.130.221",
      mongoArbiter: "15.126.212.98",
      redisMaster: "15.126.240.121",
      redisSlaves: ["15.126.244.102", "15.126.204.143"],
      kinesisClient: "15.126.193.181",
      jobRunner: "15.126.195.222",
      loadBalancerJava: "15.126.210.249",
      loadBalancerNodeJS: "15.126.210.249",
      loadBalancerPortalSocket: null
    }
  }
};

if (process.env.PROD_CHECK_ENABLED === '1') {
  config.environmentsToTest.push('prod');
}
config.disableProcessChecks = process.env.HPSN_DISABLE_PROCESS_CHECKS === '1';
config.disableURLChecks = process.env.HPSN_DISABLE_URL_CHECKS === '1';
if (process.env.STAG_CHECK_ENABLED === '1') {
  config.environmentsToTest.push('staging');
}
config.ipsToSkip = [];
if (process.env.HPSN_SKIP_IPS) {
  config.ipsToSkip = process.env.HPSN_SKIP_IPS.split(',') || [];
  console.log("process checks will be skipped for the following IPs: " + config.ipsToSkip);
}
module.exports = config;
