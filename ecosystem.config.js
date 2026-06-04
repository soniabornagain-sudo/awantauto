module.exports = {
  apps: [
    {
      name: "parallels-starter",
      script: "check_parallels.sh",
      interpreter: "bash",
      cwd: __dirname,
      // PM2 cron: 평일(1-5) 오후 2시 5분
      cron_restart: "5 14 * * 1-5",
      autorestart: false,
      watch: false,
      env: {
        PYTHONUNBUFFERED: "1",
      },
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      out_file: "./logs/out.log",
      error_file: "./logs/error.log",
    },
    {
      name: "onewms-checker",
      script: "onewms_checker.py",
      interpreter: "python3",
      cwd: __dirname,
      // PM2 cron: 평일(1-5) 오후 2시 20분
      cron_restart: "20 14 * * 1-5",
      autorestart: false,
      watch: false,
      env: {
        PYTHONUNBUFFERED: "1",
      },
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      out_file: "./logs/onewms_out.log",
      error_file: "./logs/onewms_error.log",
    },
    {
      name: "parallels-stopper",
      script: "stop_parallels.sh",
      interpreter: "bash",
      cwd: __dirname,
      // PM2 cron: 평일(1-5) 오후 3시
      cron_restart: "0 15 * * 1-5",
      autorestart: false,
      watch: false,
      env: {
        PYTHONUNBUFFERED: "1",
      },
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      out_file: "./logs/out.log",
      error_file: "./logs/error.log",
    },
  ],
};
