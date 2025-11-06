#!/usr/bin/bash

# Usage: test/setup.sh FLUENTD_VERSION
#
#  source test/setup.sh v1.16
#
#

function check_ruby_version() {
    version=$(ruby -v | cut -d' ' -f2)
    base_version=$(echo $version | sed 's/p[0-9]\+$//')
    FLUENT_AUDITIFY_RUBYVER=ruby-${base_version}
}

function setup_rvm_gemset() {
    FLUENT_AUDITIFY_GEMSET=$1
    if [ -n "$FLUENT_AUDITIFY_RUBYVER" ]; then
        rvm use $FLUENT_AUDITIFY_RUBYVER
        rvm gemset use $FLUENT_AUDITIFY_GEMSET --create
    fi
}

function setup_gems() {
    FLUENTD_VERSION=$1
    version=$(ruby -v | cut -d' ' -f2)
    rm -f Gemfile.local Gemfile.lock
    echo '' > Gemfile.local
    case $version in
        2.7*)
            echo "gem 'fiber-storage', '= 1.0.0'" >> Gemfile.local
            echo "gem 'fiber-local', '= 1.0.0'" >> Gemfile.local
            echo "gem 'console', '= 1.19.0'" >> Gemfile.local
            ;;
        *)
            echo "gem 'webrick'" >> Gemfile.local
            ;;
    esac
    case $FLUENTD_VERSION in
        1.19*)
            echo "gem 'fluentd', '= 1.19.1'" >> Gemfile.local
            ;;
        1.18*)
            echo "gem 'fluentd', '= 1.18.0'" >> Gemfile.local
            ;;
        1.17*)
            echo "gem 'fluentd', '= 1.17.1'" >> Gemfile.local
            ;;
        1.16*)
            echo "gem 'fluentd', '= 1.16.10'" >> Gemfile.local
            ;;
        1.15*)
            echo "gem 'fluentd', '= 1.15.3'" >> Gemfile.local
            ;;
        1.14*)
            echo "gem 'fluentd', '= 1.14.6'" >> Gemfile.local
            ;;
        1.13*)
            echo "gem 'fluentd', '= 1.13.3'" >> Gemfile.local
            ;;
        1.12*)
            echo "gem 'fluentd', '= 1.12.4'" >> Gemfile.local
            ;;
        1.11*)
            echo "gem 'fluentd', '= 1.11.5'" >> Gemfile.local
            ;;
        1.10*)
            echo "gem 'fluentd', '= 1.10.4'" >> Gemfile.local
            ;;
        1.9*)
            echo "gem 'fluentd', '= 1.9.3'" >> Gemfile.local
            ;;
        1.8*)
            echo "gem 'fluentd', '= 1.8.1'" >> Gemfile.local
            ;;
        1.7*)
            echo "gem 'fluentd', '= 1.7.4'" >> Gemfile.local
            ;;
        1.6*)
            echo "gem 'fluentd', '= 1.6.3'" >> Gemfile.local
            ;;
        1.5*)
            echo "gem 'fluentd', '= 1.5.2'" >> Gemfile.local
            ;;
        1.4*)
            echo "gem 'fluentd', '= 1.4.2'" >> Gemfile.local
            ;;
        1.3*)
            echo "gem 'fluentd', '= 1.3.3'" >> Gemfile.local
            ;;
        1.2*)
            echo "gem 'fluentd', '= 1.2.6'" >> Gemfile.local
            ;;
        1.1*)
            echo "gem 'fluentd', '= 1.1.3'" >> Gemfile.local
            ;;
        1.0*)
            echo "gem 'fluentd', '= 1.0.2'" >> Gemfile.local
            ;;
        0.14*)
            echo "gem 'fluentd', '= 0.14.25'" >> Gemfile.local
            ;;
        0.12*)
            echo "gem 'fluentd', '= 0.12.43'" >> Gemfile.local
            ;;
    esac
    cat Gemfile.local
    bundle install
    if [ $? -ne 0 ]; then
        echo -e "\e[37;41m[FAIL]\e[0m Install dependency gems with bundler."
    else
        echo -e "\e[37;42m[PASS]\e[0m Install dependency gems with bundler."
    fi
}

check_ruby_version

case $1 in
    *[0-9.]*)
        short_version=$(echo "$1" | sed 's/[.]//g')
        if [ -n "$CI" ]; then
            # use setup-ruby
            echo -e "\e[37;42m[PASS]\e[0m Use setup-ruby."
        else
            gemset=$(rvm gemset list | grep "fluentd${short_version}-auditify")
            if [ -n "${gemset}" ]; then
                rvm use $RUBYVER@fluentd${short_version}-auditify
            else
                setup_rvm_gemset fluentd${short_version}-auditify
            fi
        fi
        setup_gems $1
        ;;
    *)
        echo "Usage: source test/setup.sh v1.19"
        ;;
esac
