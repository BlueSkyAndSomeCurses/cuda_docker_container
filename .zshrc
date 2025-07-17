PROMPT='%n@%m %1~ %# '

# >>> conda initialize >>>
__conda_setup="$('/root/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
    conda activate ADHD
else
    if [ -f "/root/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/root/miniconda3/etc/profile.d/conda.sh"
        conda activate ADHD
    fi
fi
# <<< conda initialize <<<
