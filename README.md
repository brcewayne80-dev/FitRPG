rjudge@pi-console:~/FitRPG/web $ npm run build

> fitrpg-web@0.1.0 build
> next build

Attention: Next.js now collects completely anonymous telemetry regarding usage.
This information is used to shape Next.js' roadmap and prioritize features.
You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
https://nextjs.org/telemetry

▲ Next.js 16.1.6 (Turbopack)

  Creating an optimized production build ...
Turbopack build encountered 1 warnings:
./app/api/launch-flare/route.ts:21:20
Module not found: Can't resolve (<dynamic> | '')
  19 |
  20 |   try {
> 21 |     flareProcess = spawn('node', [scriptPath, `--token=${token}`], {
     |                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
> 22 |       detached: false,
     | ^^^^^^^^^^^^^^^^^^^^^^
> 23 |       stdio: 'inherit',
     | ^^^^^^^^^^^^^^^^^^^^^^
> 24 |     });
     | ^^^^^^^
  25 |
  26 |     flareProcess.on('exit', () => {
  27 |       flareProcess = null;



https://nextjs.org/docs/messages/module-not-found


✓ Compiled successfully in 10.1s
✓ Finished TypeScript in 4.3s    
✓ Collecting page data using 3 workers in 568.2ms    
✓ Generating static pages using 3 workers (5/5) in 253.1ms
✓ Finalizing page optimization in 3.6s    

Route (app)
┌ ○ /
├ ○ /_not-found
├ ƒ /api/launch-flare
└ ○ /login


ƒ Proxy (Middleware)

○  (Static)   prerendered as static content
ƒ  (Dynamic)  server-rendered on demand

rjudge@pi-console:~/FitRPG/web $ sudo systemctl start fitrpg-dashboard
Failed to start fitrpg-dashboard.service: Unit fitrpg-dashboard.service not found.
rjudge@pi-console:~/FitRPG/web $ cd ..
rjudge@pi-console:~/FitRPG $ cd ..
rjudge@pi-console:~ $ sudo systemctl start fitrpg-dashboard
Failed to start fitrpg-dashboard.service: Unit fitrpg-dashboard.service not found.
