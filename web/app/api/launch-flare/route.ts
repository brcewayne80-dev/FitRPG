import { NextRequest, NextResponse } from 'next/server';
import { spawn, type ChildProcess } from 'child_process';

// Module-level — persists for the lifetime of the Next.js server process
let flareProcess: ChildProcess | null = null;

export async function POST(req: NextRequest) {
  if (flareProcess) {
    return NextResponse.json({ error: 'Already running' }, { status: 409 });
  }

  const scriptPath = process.env.FLARE_LAUNCHER_PATH ?? '';
  if (!scriptPath) {
    // Dev on Windows — Flare not available, silently no-op
    return NextResponse.json({ status: 'launched' });
  }

  const token = req.headers.get('authorization')?.replace('Bearer ', '') ?? '';

  try {
    flareProcess = spawn('node', [scriptPath, `--token=${token}`], {
      detached: false,
      stdio: 'inherit',
    });

    flareProcess.on('exit', () => {
      flareProcess = null;
    });

    flareProcess.on('error', () => {
      flareProcess = null;
    });
  } catch {
    // flare-launcher.js or node not available (e.g. Windows dev) — silently no-op
    flareProcess = null;
  }

  return NextResponse.json({ status: 'launched' });
}

export async function GET() {
  return NextResponse.json({ running: flareProcess !== null });
}
