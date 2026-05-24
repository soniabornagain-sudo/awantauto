module.exports = {
  apps: [
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
      out_file: "./logs/out.log",
      error_file: "./logs/error.log",
    },
  ],
};
