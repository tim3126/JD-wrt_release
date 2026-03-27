#!/usr/bin/env bash

maintim_wrap_function() {
    local original_name="$1"
    local wrapped_name="$2"
    local definition

    definition=$(declare -f "$original_name") || return 1
    eval "${definition/$original_name/$wrapped_name}"
}
