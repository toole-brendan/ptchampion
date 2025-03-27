// Load .env.production variables explicitly
require('dotenv').config({ path: '/home/ec2-user/ptchampion/.env.production' });

module.exports = {
  apps : [{
    name   : "ptchampion-api",
    script : "./dist/index.js",
    cwd    : "/home/ec2-user/ptchampion",
    env_production: {
       NODE_ENV: "production"
       // Variables from .env.production should now be loaded by the require('dotenv') call above
       // We can still define or override variables here if needed
    },
  }]
}
