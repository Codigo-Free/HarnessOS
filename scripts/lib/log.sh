#!/usr/bin/env bash
# HarnessOS — Logging functions

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

log_step()  { echo -e "${CYAN}${BOLD}==> ${RESET}${BOLD}${1}${RESET}"; }
log_info()  { echo -e "${BLUE}    -> ${RESET}${1}"; }
log_ok()    { echo -e "${GREEN}    ✓  ${RESET}${1}"; }
log_warn()  { echo -e "${YELLOW}    ⚠  ${RESET}${1}" >&2; }
log_error() { echo -e "${RED}    ✗  ${RESET}${1}" >&2; }

die() {
    log_error "${1}"
    exit "${2:-1}"
}
