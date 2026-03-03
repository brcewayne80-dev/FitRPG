rjudge@pi-console:~ $ which node
/home/rjudge/.config/nvm/versions/node/v20.20.0/bin/node
rjudge@pi-console:~ $ sudo ln -s $v20.19.0/bin/node
rjudge@pi-console:~ $ sudo systemctl restart fitrpg-dashboard
rjudge@pi-console:~ $ sudo systemctl status fitrpg-dashboard
● fitrpg-dashboard.service - FitRPG Next.js Dashboard
     Loaded: loaded (/etc/systemd/system/fitrpg-dashboard.service; enabled; preset: enabled)
     Active: activating (auto-restart) (Result: exit-code) since Tue 2026-03-03 23:34:54 GMT; 3s ago
    Process: 6900 ExecStart=/usr/bin/node .next/standalone/server.js (code=exited, status=203/EXEC)
   Main PID: 6900 (code=exited, status=203/EXEC)
        CPU: 903us
rjudge@pi-console:~ $ sudo ln -s $/home/rjudge/.nvm/versions/node/v20.19.0/bin/node
ln: failed to create symbolic link './node': File exists
