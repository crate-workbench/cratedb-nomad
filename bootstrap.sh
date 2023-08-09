#!/bin/bash
#
# Bootstrap Ansible environment for Crate.io
#
# - Create a Python virtualenv
# - Install all dependency packages and modules
# - Drop user into an activated virtualenv
#
# Synopsis::
#
#     source bootstrap.sh
#

function print_header() {
    printf '=%.0s' {1..42}; echo
    echo "$1"
    printf '=%.0s' {1..42}; echo
}

function ensure_virtualenv() {
    # Create a Python virtualenv with current version of Python 3.
    # TODO: Maybe take `pyenv` into account.
    if [[ ! -d .venv ]]; then
        python3 -m venv .venv
    fi
}

function activate_virtualenv() {
    # Activate Python virtualenv.
    source .venv/bin/activate
}

function before_setup() {

    # When `wheel` is installed, Python will build `wheel` packages from all
    # acquired `sdist` packages and will store them into `~/.cache/pip`, where
    # they will be picked up by the caching machinery and will be reused on
    # subsequent invocations when run on CI. This makes a *significant*
    # difference on total runtime on CI, it is about 2x faster.
    #
    # Otherwise, there will be admonitions like:
    #   Using legacy 'setup.py install' for ansible, since package 'wheel' is not installed.
    #
    pip install wheel
}

function setup_ansible() {

    # Install all requirements of the Ansible environment.

    print_header "Installing Python modules"
    pip install --requirement=playbooks/requirements.txt
    echo

    print_header "Installing Ansible modules"
    ansible-galaxy install -r playbooks/requirements.yaml
    echo

    print_header "Ansible environment is ready"
    ansible --version
    echo
}

function finalize() {

    # Some steps before dropping into the activated virtualenv.

    # Fix brokenness of Python on macOS 10.13 and beyond.
    # https://www.wefearchange.org/2018/11/forkmacos.rst.html
    export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

    export VAULT_ADDR='https://vault.vdc.cr8.net:8200'
}

function footer() {

    print_header "Viel Spaß am Gerät"
    cat <<ZUSE

    Es hat viele Erfinder außer mir gebraucht, um den Computer, so wie wir ihn heute kennen, zu entwickeln.
    Ich wünsche der nachfolgenden Generation Alles Gute im Umgang mit dem Computer. Möge dieses Instrument
    Ihnen helfen, die Probleme dieser Welt zu beseitigen, die wir Alten Euch hinterlassen haben.

    -- Konrad Zuse

ZUSE

}

function main() {
    ensure_virtualenv
    activate_virtualenv
    before_setup
    setup_ansible
    finalize
    footer
}

function lint() {
    ansible-lint playbooks
}

main
