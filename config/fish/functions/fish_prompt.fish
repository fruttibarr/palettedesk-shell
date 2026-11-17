# Minimal two-tone prompt:   ~/dir ❯     (❯ turns red after a failed command)
function fish_prompt
    set -l last_status $status
    set_color $fish_color_cwd
    echo -n ' '(prompt_pwd)' '
    if test $last_status -ne 0
        set_color $fish_color_error
    else
        set_color $fish_color_operator
    end
    echo -n '❯ '
    set_color normal
end
