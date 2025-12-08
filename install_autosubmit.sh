#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

MODEL_ROOT=${MODEL_ROOT:-$HOME/models/wrf}
AUTOSUBMIT_ROOT=${AUTOSUBMIT_ROOT:-$MODEL_ROOT/autosubmit}
EXPERIMENT_ROOT=${EXPERIMENT_ROOT:-$MODEL_ROOT/experiments}
AUTOSUBMIT_REPO=${AUTOSUBMIT_REPO:-https://github.com/hectornav/autosubmit}
AUTOSUBMIT_BRANCH=${AUTOSUBMIT_BRANCH:-master}
VENV_DIR=${VENV_DIR:-$AUTOSUBMIT_ROOT/venv}
MANAGE_SCRIPT=${MANAGE_SCRIPT:-$AUTOSUBMIT_ROOT/manage_experiments.sh}

command -v python3 >/dev/null 2>&1 || {
    error "python3 is required to install autosubmit."
    exit 1
}

info "Ensuring autosubmit directory exists at $AUTOSUBMIT_ROOT"
mkdir -p "$AUTOSUBMIT_ROOT"
CLONE_FAILED=false

if [ -d "$AUTOSUBMIT_ROOT/.git" ]; then
    info "Updating existing autosubmit checkout"
    git -C "$AUTOSUBMIT_ROOT" fetch --depth=1 origin "$AUTOSUBMIT_BRANCH" >/dev/null 2>&1 || true
    git -C "$AUTOSUBMIT_ROOT" checkout "$AUTOSUBMIT_BRANCH" >/dev/null 2>&1
    git -C "$AUTOSUBMIT_ROOT" reset --hard "origin/$AUTOSUBMIT_BRANCH" >/dev/null 2>&1 || true
else
    info "Cloning autosubmit repository"
    if ! git clone --depth=1 --branch "$AUTOSUBMIT_BRANCH" "$AUTOSUBMIT_REPO" "$AUTOSUBMIT_ROOT"; then
        error "Could not clone $AUTOSUBMIT_REPO. Continuing with autosubmit helper scripts only."
        CLONE_FAILED=true
    fi
fi

info "Creating Python virtual environment at $VENV_DIR"
python3 -m venv "$VENV_DIR"
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

python3 -m pip install --upgrade pip setuptools wheel >/dev/null
if [ "$CLONE_FAILED" = false ] && ( [ -f "$AUTOSUBMIT_ROOT/setup.py" ] || [ -f "$AUTOSUBMIT_ROOT/pyproject.toml" ] ); then
    python3 -m pip install --editable "$AUTOSUBMIT_ROOT" >/dev/null
    if [ -f "$AUTOSUBMIT_ROOT/requirements.txt" ]; then
        python3 -m pip install -r "$AUTOSUBMIT_ROOT/requirements.txt" >/dev/null
    fi
else
    info "autosubmit source not available; pip installation skipped."
fi

info "Preparing experiment directories under $EXPERIMENT_ROOT"
QUEUE_DIR="$EXPERIMENT_ROOT/queue"
LOG_DIR="$EXPERIMENT_ROOT/logs"
OUTPUT_DIR="$EXPERIMENT_ROOT/output"
mkdir -p "$QUEUE_DIR" "$LOG_DIR" "$OUTPUT_DIR"

if [ ! -f "$QUEUE_DIR/README.md" ]; then
    cat <<EOF > "$QUEUE_DIR/README.md"
Each script dropped in this folder defines one experiment.
Autosubmit helper scripts will execute these files in order of creation.
EOF
fi

cat <<'EOF' > "$MANAGE_SCRIPT"
#!/usr/bin/env bash
set -euo pipefail

MODEL_ROOT=${MODEL_ROOT:-$HOME/models/wrf}
AUTOSUBMIT_ROOT=${AUTOSUBMIT_ROOT:-$MODEL_ROOT/autosubmit}
EXPERIMENT_ROOT=${EXPERIMENT_ROOT:-$MODEL_ROOT/experiments}
VENV_DIR=${VENV_DIR:-$AUTOSUBMIT_ROOT/venv}
QUEUE_DIR="$EXPERIMENT_ROOT/queue"
LOG_DIR="$EXPERIMENT_ROOT/logs"
OUTPUT_DIR="$EXPERIMENT_ROOT/output"

command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required to run experiment helpers."
    exit 1
}

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "Autosubmit environment not found. Run install_autosubmit.sh first."
    exit 1
fi

source "$VENV_DIR/bin/activate"

list_jobs() {
    ls -1 "$QUEUE_DIR"/*.sh 2>/dev/null || true
}

submit_jobs() {
    local command=("autosubmit")
    local has_autosubmit
    if command -v autosubmit >/dev/null 2>&1; then
        has_autosubmit=true
    else
        has_autosubmit=false
    fi

    for job in "$QUEUE_DIR"/*.sh; do
        [ -f "$job" ] || continue
        echo "-> Running experiment: $job"
        if $has_autosubmit; then
            autosubmit run "$job" || bash "$job"
        else
            bash "$job"
        fi
        cp "$job" "$LOG_DIR/$(basename "$job").done"
    done
}

case "${1:-list}" in
    list)
        list_jobs
        ;;
    submit)
        submit_jobs
        ;;
    help|--help|-h)
        cat <<HELP
Usage: $(basename "$0") [list|submit]
- list   : show experiment scripts stored in $QUEUE_DIR
- submit : run each script (delegates to autosubmit if installed)
HELP
        ;;
    *)
        echo "Unknown command: $1"
        exit 1
        ;;
esac
EOF

chmod +x "$MANAGE_SCRIPT"

success "Autosubmit helper installed." \
        "Use '$MANAGE_SCRIPT list' and '$MANAGE_SCRIPT submit' to run experiments."