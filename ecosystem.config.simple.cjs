// No dependencies, just plain config
module.exports = {
  apps : [{
    name   : "ptchampion-api",
    script : "./dist/index.js",
    cwd    : "/home/ec2-user/ptchampion",
    env_production: {
       NODE_ENV: "production",
       DATABASE_URL: "postgres://postgres:Dunlainge1!@ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com:5432/postgres",
       PORT: 3000,
       NODE_TLS_REJECT_UNAUTHORIZED: 0
    }
  }]
}
