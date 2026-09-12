"""
K8s Self-Healing Demo — Python (Flask)

Endpoints:
  GET /healthz  -> liveness probe  (always 200 once process is up)
  GET /ready    -> readiness probe (503 during simulated startup)
  GET /burn     -> CPU burner      (used by stress generator)
  GET /         -> returns hostname so you can see which pod served you
"""

import os
import time
import math
import random
import socket
import threading
from flask import Flask, Response

app = Flask(__name__)

# ------------------------------------------------------------------
# Simulated slow startup
# ------------------------------------------------------------------
# Real apps need time to connect to DBs, warm caches, load ML models, etc.
# We simulate 8 seconds of initialization so the readiness probe can
# demonstrate withholding traffic until the app is actually ready.
STARTUP_DELAY_SECONDS = int(os.getenv("STARTUP_DELAY_SECONDS", "8"))
_start_time = time.time()
_ready = False


def _finish_startup():
    """Background thread that flips readiness after the simulated startup."""
    global _ready
    time.sleep(STARTUP_DELAY_SECONDS)
    _ready = True
    app.logger.info(
        "Startup complete after %.1fs — readiness probe will now pass",
        STARTUP_DELAY_SECONDS,
    )


threading.Thread(target=_finish_startup, daemon=True).start()


# ------------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------------
@app.route("/healthz")
def healthz():
    """Liveness probe.

    As long as the Python process is alive enough to answer HTTP,
    we return 200. If the process hangs, this will time out and
    kubelet will restart the container.
    """
    return "OK", 200


@app.route("/ready")
def ready():
    """Readiness probe.

    Returns 503 until the app has fully initialized, then 200.
    Kubernetes will keep this pod out of the Service endpoints
    until it returns 200.
    """
    if _ready:
        return "Ready", 200
    return "Not Ready", 503


@app.route("/burn")
def burn():
    """CPU burner used to trigger HPA scale-up.

    Burns CPU for up to 30 seconds (or a shorter duration if the
    query string specifies one) doing pointless math.
    """
    duration = float(os.getenv("BURN_SECONDS", "30"))
    end = time.time() + duration
    iterations = 0
    while time.time() < end:
        # Busy loop — keeps one core hot
        math.sqrt(random.random())
        iterations += 1
    return f"Burned CPU for {duration}s ({iterations:,} iterations)\n", 200


@app.route("/")
def index():
    """Return pod hostname so clients can see which replica responded."""
    return f"Hello from {socket.gethostname()}\n", 200


@app.route("/crash")
def crash():
    """Optional: force-kill the process to demonstrate liveness recovery.

    Calling this endpoint makes the container exit, which the kubelet
    detects via the failing liveness probe and restarts the container.
    """
    app.logger.warning("Crash endpoint called — terminating process")
    os._exit(1)


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    # Use threaded=True so /burn doesn't block /healthz or /ready
    app.run(host="0.0.0.0", port=port, threaded=True)
